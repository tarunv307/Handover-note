from datetime import datetime
import pytz
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()


def utc_now():
    return datetime.now(pytz.UTC)


class User(UserMixin, db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="employee")  # 'admin' or 'employee'
    employee_id = db.Column(db.String(50), unique=True, nullable=True, index=True)
    created_at = db.Column(db.DateTime, default=utc_now)

    # Relationships
    tasks_assigned = db.relationship(
        "Task", foreign_keys="Task.assigned_to", backref="assigned_employee", lazy="dynamic"
    )
    tasks_created = db.relationship(
        "Task", foreign_keys="Task.created_by", backref="creator", lazy="dynamic"
    )
    submissions = db.relationship("Submission", backref="submitter", lazy="dynamic")

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "role": self.role,
            "employee_id": self.employee_id,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
        }


class Task(db.Model):
    __tablename__ = "tasks"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), default="pending", nullable=False)  # 'pending', 'submitted', 'completed'
    assigned_to = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, default=utc_now)

    # One-to-one relationship with submission
    submission = db.relationship("Submission", backref="task", uselist=False, cascade="all, delete-orphan")

    def to_dict(self):
        assigned_user = db.session.get(User, self.assigned_to) if self.assigned_to else None
        created_user = db.session.get(User, self.created_by) if self.created_by else None

        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "status": self.status,
            "assigned_to": self.assigned_to,
            "assigned_employee_name": assigned_user.name if assigned_user else "Unassigned",
            "assigned_employee_id": assigned_user.employee_id if assigned_user else None,
            "created_by": self.created_by,
            "creator_name": created_user.name if created_user else "System",
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
            "submission": self.submission.to_dict() if self.submission else None,
        }


class Submission(db.Model):
    __tablename__ = "submissions"

    id = db.Column(db.Integer, primary_key=True)
    task_id = db.Column(db.Integer, db.ForeignKey("tasks.id"), nullable=False, unique=True)
    submitted_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    link = db.Column(db.String(500), nullable=True)  # GitHub repo, Google Drive link, etc.
    zip_path = db.Column(db.String(250), nullable=True)  # Relative path in uploads
    submitted_at = db.Column(db.DateTime, default=utc_now)
    admin_notes = db.Column(db.Text, nullable=True)

    def to_dict(self):
        submitter_user = db.session.get(User, self.submitted_by) if self.submitted_by else None
        return {
            "id": self.id,
            "task_id": self.task_id,
            "submitted_by": self.submitted_by,
            "submitter_name": submitter_user.name if submitter_user else "Unknown",
            "submitter_employee_id": submitter_user.employee_id if submitter_user else None,
            "link": self.link,
            "zip_path": self.zip_path,
            "has_file": bool(self.zip_path),
            "submitted_at": self.submitted_at.strftime("%Y-%m-%d %H:%M:%S") if self.submitted_at else None,
            "admin_notes": self.admin_notes,
        }
