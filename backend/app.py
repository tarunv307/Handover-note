import os
import logging
from pathlib import Path
from functools import wraps
from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS
from flask_login import (
    LoginManager,
    login_user,
    logout_user,
    login_required,
    current_user,
)
from werkzeug.utils import secure_filename

from backend.config import (
    BASE_DIR,
    OUTPUT_DIR,
    DATA_DIR,
    UPLOAD_FOLDER,
    PORT,
    HOST,
    DEBUG,
    SECRET_KEY,
    SQLALCHEMY_DATABASE_URI,
    SQLALCHEMY_TRACK_MODIFICATIONS,
)
from backend.models import db, User, Task, Submission
from backend.db_seed import seed_database
from backend.fetch_activity import fetch_shift_activity, fetch_tickets, fetch_incidents, fetch_chat
from backend.generator import generate_handover_note
from backend.publisher import publish_pdf

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("api")

app = Flask(__name__, static_folder=str(BASE_DIR / "frontend"))
app.config["SECRET_KEY"] = SECRET_KEY
app.config["SQLALCHEMY_DATABASE_URI"] = SQLALCHEMY_DATABASE_URI
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = SQLALCHEMY_TRACK_MODIFICATIONS
app.config["UPLOAD_FOLDER"] = str(UPLOAD_FOLDER)
app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024  # 50 MB max upload

# Allow credentials for CORS session cookies
CORS(app, supports_credentials=True)

# Test database connectivity before initializing SQLAlchemy
def get_effective_db_uri():
    db_url = SQLALCHEMY_DATABASE_URI
    if db_url.startswith("postgresql://") or db_url.startswith("postgres://"):
        try:
            import psycopg2
            conn = psycopg2.connect(db_url, connect_timeout=4)
            conn.close()
            logger.info("Connected to remote PostgreSQL / Supabase database successfully.")
            return db_url
        except Exception as e:
            logger.warning(
                f"Could not connect to remote PostgreSQL / Supabase ({e}). Falling back to local SQLite database."
            )
            return f"sqlite:///{BASE_DIR / 'backend' / 'app.db'}"
    return db_url

effective_db_uri = get_effective_db_uri()
app.config["SQLALCHEMY_DATABASE_URI"] = effective_db_uri

# Initialize Database & Login Manager
db.init_app(app)
login_manager = LoginManager()
login_manager.init_app(app)


@login_manager.user_loader
def load_user(user_id):
    return db.session.get(User, int(user_id))


@login_manager.unauthorized_handler
def unauthorized():
    return jsonify({"error": "Authentication required. Please log in."}), 401


def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify({"error": "Authentication required."}), 401
        if current_user.role != "admin":
            return jsonify({"error": "Forbidden: Admin privileges required."}), 403
        return f(*args, **kwargs)
    return decorated_function


# Initialize DB tables on startup
with app.app_context():
    seed_database()
    logger.info("Database initialized and ready.")


# -----------------------------------------------------------------------------
# System & Telemetry Endpoints
# -----------------------------------------------------------------------------
@app.route("/health", methods=["GET"])
@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "enterprise-shift-handover-and-task-manager",
        "version": "2.0.0"
    }), 200


@app.route("/api/sources", methods=["GET"])
def list_sources():
    """Returns overview of configured telemetry sources and total records."""
    try:
        tickets = fetch_tickets(DATA_DIR)
        incidents = fetch_incidents(DATA_DIR)
        chat = fetch_chat(DATA_DIR)
        return jsonify({
            "status": "online",
            "sources": {
                "tickets": {"count": len(tickets), "source_type": "file/jira_mock"},
                "incidents": {"count": len(incidents), "source_type": "file/pagerduty_mock"},
                "chat": {"count": len(chat), "source_type": "file/slack_mock"}
            },
            "total_records": len(tickets) + len(incidents) + len(chat)
        }), 200
    except Exception as e:
        logger.error(f"Error fetching sources status: {e}")
        return jsonify({"status": "degraded", "error": str(e)}), 500


# -----------------------------------------------------------------------------
# Authentication Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(force=True, silent=True) or {}
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "Email and password are required."}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "Invalid email or password."}), 401

    login_user(user, remember=True)
    logger.info(f"User logged in: {user.email} (Role: {user.role})")
    return jsonify({
        "message": "Login successful",
        "user": user.to_dict()
    }), 200


@app.route("/api/logout", methods=["POST"])
@login_required
def logout():
    logout_user()
    return jsonify({"message": "Logout successful"}), 200


@app.route("/api/me", methods=["GET"])
def get_current_user_info():
    if not current_user.is_authenticated:
        return jsonify({"authenticated": False, "user": None}), 200
    return jsonify({
        "authenticated": True,
        "user": current_user.to_dict()
    }), 200


# -----------------------------------------------------------------------------
# User Management Endpoints (Admin & Search)
# -----------------------------------------------------------------------------
@app.route("/api/users", methods=["GET"])
@login_required
def get_users():
    query_str = request.args.get("q", "").strip().lower()
    users_query = User.query
    if query_str:
        users_query = users_query.filter(
            (User.name.ilike(f"%{query_str}%")) | 
            (User.employee_id.ilike(f"%{query_str}%")) |
            (User.email.ilike(f"%{query_str}%"))
        )
    users = users_query.order_by(User.name.asc()).all()
    return jsonify([u.to_dict() for u in users]), 200


@app.route("/api/users", methods=["POST"])
@admin_required
def create_user():
    data = request.get_json(force=True, silent=True) or {}
    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "").strip()
    role = data.get("role", "employee").strip().lower()
    employee_id = data.get("employee_id", "").strip() or None

    if not name or not email or not password:
        return jsonify({"error": "Name, email, and password are required."}), 400

    if role not in ("admin", "employee"):
        return jsonify({"error": "Role must be either 'admin' or 'employee'."}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "A user with this email already exists."}), 409

    if employee_id and User.query.filter_by(employee_id=employee_id).first():
        return jsonify({"error": "A user with this employee ID already exists."}), 409

    user = User(name=name, email=email, role=role, employee_id=employee_id)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    logger.info(f"Admin created user: {user.email} (ID: {user.id})")
    return jsonify(user.to_dict()), 201


@app.route("/api/users/<int:user_id>", methods=["PUT"])
@admin_required
def update_user(user_id):
    user = User.query.get_or_404(user_id)
    data = request.get_json(force=True, silent=True) or {}

    name = data.get("name")
    role = data.get("role")
    employee_id = data.get("employee_id")
    password = data.get("password")

    if name:
        user.name = name.strip()
    if role and role in ("admin", "employee"):
        user.role = role
    if employee_id is not None:
        user.employee_id = employee_id.strip() or None
    if password:
        user.set_password(password)

    db.session.commit()
    return jsonify(user.to_dict()), 200


@app.route("/api/users/<int:user_id>", methods=["DELETE"])
@admin_required
def delete_user(user_id):
    user = User.query.get_or_404(user_id)
    if user.id == current_user.id:
        return jsonify({"error": "Cannot delete your own active admin account."}), 400

    db.session.delete(user)
    db.session.commit()
    return jsonify({"message": f"User {user.email} deleted successfully."}), 200


# -----------------------------------------------------------------------------
# Global Search Endpoint
# -----------------------------------------------------------------------------
@app.route("/api/search", methods=["GET"])
@login_required
def global_search():
    q = request.args.get("q", "").strip().lower()
    if not q:
        return jsonify({"users": [], "tasks": []}), 200

    users = User.query.filter(
        (User.name.ilike(f"%{q}%")) | (User.employee_id.ilike(f"%{q}%"))
    ).limit(10).all()

    tasks_query = Task.query.filter(
        (Task.title.ilike(f"%{q}%")) | (Task.description.ilike(f"%{q}%"))
    )
    if current_user.role != "admin":
        tasks_query = tasks_query.filter_by(assigned_to=current_user.id)
    tasks = tasks_query.limit(10).all()

    return jsonify({
        "users": [u.to_dict() for u in users],
        "tasks": [t.to_dict() for t in tasks]
    }), 200


# -----------------------------------------------------------------------------
# Task Management Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/tasks", methods=["GET"])
@login_required
def get_tasks():
    status_filter = request.args.get("status")
    
    if current_user.role == "admin":
        tasks_query = Task.query
    else:
        # Employees only see tasks assigned to them
        tasks_query = Task.query.filter_by(assigned_to=current_user.id)

    if status_filter:
        tasks_query = tasks_query.filter_by(status=status_filter)

    tasks = tasks_query.order_by(Task.created_at.desc()).all()
    return jsonify([t.to_dict() for t in tasks]), 200


@app.route("/api/tasks", methods=["POST"])
@admin_required
def create_task():
    data = request.get_json(force=True, silent=True) or {}
    title = data.get("title", "").strip()
    description = data.get("description", "").strip()
    assigned_to = data.get("assigned_to")

    if not title:
        return jsonify({"error": "Task title is required."}), 400

    if assigned_to:
        assignee = db.session.get(User, assigned_to)
        if not assignee:
            return jsonify({"error": "Assigned employee not found."}), 404

    task = Task(
        title=title,
        description=description,
        status="pending",
        assigned_to=assigned_to,
        created_by=current_user.id,
    )
    db.session.add(task)
    db.session.commit()

    logger.info(f"Task created: '{task.title}' assigned to User ID {task.assigned_to}")
    return jsonify(task.to_dict()), 201


@app.route("/api/tasks/<int:task_id>", methods=["PUT"])
@admin_required
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json(force=True, silent=True) or {}

    if "title" in data:
        task.title = data["title"].strip()
    if "description" in data:
        task.description = data["description"].strip()
    if "status" in data and data["status"] in ("pending", "submitted", "completed"):
        task.status = data["status"]
    if "assigned_to" in data:
        task.assigned_to = data["assigned_to"]

    db.session.commit()
    return jsonify(task.to_dict()), 200


@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
@admin_required
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return jsonify({"message": f"Task #{task_id} deleted."}), 200


@app.route("/api/tasks/<int:task_id>/submission", methods=["GET"])
@login_required
def get_task_submission(task_id):
    task = db.session.get(Task, task_id)
    if not task:
        return jsonify({"error": "Task not found"}), 404
        
    if current_user.role != "admin" and task.assigned_to != current_user.id:
        return jsonify({"error": "Forbidden"}), 403

    if not task.submission:
        return jsonify({"submission": None}), 200
    return jsonify({"submission": task.submission.to_dict()}), 200


# -----------------------------------------------------------------------------
# Submission & Review Workflow Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/tasks/<int:task_id>/submit", methods=["POST"])
@login_required
def submit_task_work(task_id):
    task = Task.query.get_or_404(task_id)

    # Only assigned employee (or admin) can submit
    if current_user.role != "admin" and task.assigned_to != current_user.id:
        return jsonify({"error": "You can only submit work for tasks assigned to you."}), 403

    link = request.form.get("link")
    zip_path = None

    # Handle JSON payload if submitted as JSON
    if not link and request.is_json:
        json_data = request.get_json(silent=True) or {}
        link = json_data.get("link")

    # Handle file upload (zip file)
    if "file" in request.files:
        uploaded_file = request.files["file"]
        if uploaded_file and uploaded_file.filename:
            filename = secure_filename(uploaded_file.filename)
            if not filename.lower().endswith(".zip"):
                return jsonify({"error": "Only .zip files are permitted for upload."}), 400
            
            save_name = f"task_{task.id}_{current_user.id}_{filename}"
            full_save_path = UPLOAD_FOLDER / save_name
            uploaded_file.save(str(full_save_path))
            zip_path = save_name

    if not link and not zip_path:
        return jsonify({"error": "Please provide either a work link (GitHub/Drive) or a .zip file."}), 400

    # Create or update submission
    submission = Submission.query.filter_by(task_id=task.id).first()
    if not submission:
        submission = Submission(
            task_id=task.id,
            submitted_by=current_user.id,
            link=link,
            zip_path=zip_path
        )
        db.session.add(submission)
    else:
        submission.submitted_by = current_user.id
        if link:
            submission.link = link
        if zip_path:
            submission.zip_path = zip_path

    task.status = "submitted"
    db.session.commit()

    logger.info(f"Submission recorded for Task #{task.id} by User #{current_user.id}")
    return jsonify({
        "message": "Work submitted successfully",
        "task": task.to_dict(),
        "submission": submission.to_dict()
    }), 200


@app.route("/api/submissions/<int:sub_id>", methods=["PUT"])
@admin_required
def review_submission(sub_id):
    submission = Submission.query.get_or_404(sub_id)
    data = request.get_json(force=True, silent=True) or {}

    admin_notes = data.get("admin_notes")
    status = data.get("status", "completed")  # 'completed' or 'pending'

    if admin_notes is not None:
        submission.admin_notes = admin_notes.strip()

    if status in ("completed", "pending", "submitted"):
        submission.task.status = status

    db.session.commit()
    logger.info(f"Admin reviewed submission #{sub_id}, task marked '{status}'")
    return jsonify({
        "message": f"Task marked as '{status}'",
        "submission": submission.to_dict(),
        "task": submission.task.to_dict()
    }), 200


@app.route("/api/submissions/<int:sub_id>/download", methods=["GET"])
@login_required
def download_submission_file(sub_id):
    submission = Submission.query.get_or_404(sub_id)
    task = submission.task

    if current_user.role != "admin" and task.assigned_to != current_user.id:
        return jsonify({"error": "Forbidden"}), 403

    if not submission.zip_path:
        return jsonify({"error": "No file uploaded for this submission."}), 404

    file_path = UPLOAD_FOLDER / submission.zip_path
    if not file_path.exists():
        return jsonify({"error": "File not found on server."}), 404

    return send_file(
        str(file_path),
        as_attachment=True,
        download_name=submission.zip_path
    )


# -----------------------------------------------------------------------------
# Shift Handover Generation Endpoints (Grounded Pipeline)
# -----------------------------------------------------------------------------
@app.route("/api/generate", methods=["POST"])
def generate_note_endpoint():
    """
    Shift Handover Note Generation Endpoint (3-Stage Pipeline).
    Accessible to authenticated users (or demo callers).
    """
    try:
        payload = request.get_json(force=True, silent=False) or {}
    except Exception:
        return jsonify({"error": "Invalid JSON body payload."}), 400

    shift_start = payload.get("shift_start")
    shift_end = payload.get("shift_end")
    timezone_str = payload.get("timezone", "Asia/Kolkata")
    custom_sources = payload.get("custom_sources")

    if not shift_start or not shift_end:
        return jsonify({
            "error": "Missing required parameters: 'shift_start' and 'shift_end' must be provided."
        }), 400

    try:
        # Stage 1: Fetch and normalize
        events, meta = fetch_shift_activity(
            shift_start_str=str(shift_start),
            shift_end_str=str(shift_end),
            timezone_str=str(timezone_str),
            data_dir=DATA_DIR,
            custom_sources=custom_sources
        )

        # Stage 2: Generator (collapse, section, sort, format)
        note_data = generate_handover_note(events, meta)

        # Stage 3: Publisher (render PDF)
        pdf_filename = f"{note_data['id']}.pdf"
        pdf_path = OUTPUT_DIR / pdf_filename
        publish_pdf(note_data, pdf_path)

        download_url = f"/api/download/{note_data['id']}"

        return jsonify({
            "success": True,
            "id": note_data["id"],
            "download_url": download_url,
            "pdf_filename": pdf_filename,
            "note": note_data,
            "meta": meta
        }), 200

    except ValueError as ve:
        logger.warning(f"Validation error: {ve}")
        return jsonify({"error": str(ve)}), 400
    except RuntimeError as re:
        logger.error(f"Export or runtime error: {re}")
        return jsonify({"error": f"Failed to generate handover report: {re}"}), 500
    except Exception as e:
        logger.error(f"Unexpected server error: {e}", exc_info=True)
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route("/api/download/<report_id>", methods=["GET"])
def download_pdf_endpoint(report_id: str):
    safe_id = Path(report_id).name
    if not safe_id.endswith(".pdf"):
        safe_id = f"{safe_id}.pdf"
    
    file_path = OUTPUT_DIR / safe_id
    if not file_path.exists():
        return jsonify({"error": f"Report '{report_id}' not found or expired."}), 404

    as_attachment = request.args.get("inline", "false").lower() not in ("true", "1", "yes")

    return send_file(
        str(file_path),
        mimetype="application/pdf",
        as_attachment=as_attachment,
        download_name=safe_id
    )


@app.route("/api/download/apk", methods=["GET"])
def download_apk_endpoint():
    """Serves the compiled Android APK for mobile devices."""
    apk_paths = [
        BASE_DIR / "frontend_flutter" / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk",
        BASE_DIR / "frontend_flutter" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk",
    ]
    for apk_file in apk_paths:
        if apk_file.exists():
            return send_file(
                str(apk_file),
                mimetype="application/vnd.android.package-archive",
                as_attachment=True,
                download_name="ShiftOps-Mobile.apk"
            )
    return jsonify({"error": "APK is currently building or not found. Please try in a moment."}), 404


# -----------------------------------------------------------------------------
# Frontend Static Asset Serving
# -----------------------------------------------------------------------------
@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve_frontend(path):
    frontend_dir = BASE_DIR / "frontend"
    if path != "" and (frontend_dir / path).exists():
        return send_from_directory(str(frontend_dir), path)
    return send_from_directory(str(frontend_dir), "index.html")


if __name__ == "__main__":
    logger.info(f"Starting Enterprise Shift Handover & Task Manager on http://{HOST}:{PORT}")
    app.run(host=HOST, port=PORT, debug=DEBUG)
