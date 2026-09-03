import pytest
import io
from backend.app import app, db
from backend.models import User, Task, Submission


@pytest.fixture
def client():
    app.config["TESTING"] = True
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    app.config["WTF_CSRF_ENABLED"] = False

    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            # Seed admin and employee
            admin = User(name="Admin User", email="admin@test.com", role="admin", employee_id="ADM-01")
            admin.set_password("pass123")

            emp = User(name="John Employee", email="emp@test.com", role="employee", employee_id="EMP-99")
            emp.set_password("pass123")

            db.session.add_all([admin, emp])
            db.session.commit()
            yield client
            db.session.remove()
            db.drop_all()


def test_auth_workflow(client):
    # Failed login
    res = client.post("/api/login", json={"email": "admin@test.com", "password": "wrong"})
    assert res.status_code == 401

    # Successful Admin login
    res = client.post("/api/login", json={"email": "admin@test.com", "password": "pass123"})
    assert res.status_code == 200
    data = res.get_json()
    assert data["user"]["role"] == "admin"

    # Check /api/me
    res = client.get("/api/me")
    assert res.status_code == 200
    assert res.get_json()["authenticated"] is True

    # Logout
    res = client.post("/api/logout")
    assert res.status_code == 200

    # /api/me after logout
    res = client.get("/api/me")
    assert res.get_json()["authenticated"] is False


def test_task_assignment_and_submission(client):
    # 1. Login as Admin
    client.post("/api/login", json={"email": "admin@test.com", "password": "pass123"})

    # 2. Get Employee ID
    res = client.get("/api/users?q=John")
    users = res.get_json()
    emp_id = users[0]["id"]

    # 3. Create Task assigned to John
    res = client.post("/api/tasks", json={
        "title": "Fix Critical Outage",
        "description": "Investigate DB connection pool",
        "assigned_to": emp_id
    })
    assert res.status_code == 201
    task_id = res.get_json()["id"]

    # 4. Switch to Employee session
    client.post("/api/logout")
    client.post("/api/login", json={"email": "emp@test.com", "password": "pass123"})

    # 5. Verify Employee sees only assigned task
    res = client.get("/api/tasks")
    tasks = res.get_json()
    assert len(tasks) == 1
    assert tasks[0]["id"] == task_id
    assert tasks[0]["status"] == "pending"

    # 6. Submit work with GitHub link
    res = client.post(f"/api/tasks/{task_id}/submit", json={
        "link": "https://github.com/org/repo/pull/42"
    })
    assert res.status_code == 200
    assert res.get_json()["task"]["status"] == "submitted"

    # 7. Switch back to Admin to review and complete
    client.post("/api/logout")
    client.post("/api/login", json={"email": "admin@test.com", "password": "pass123"})

    # Get submission details
    res = client.get(f"/api/tasks/{task_id}/submission")
    sub_data = res.get_json()["submission"]
    sub_id = sub_data["id"]

    # Admin marks complete
    res = client.put(f"/api/submissions/{sub_id}", json={
        "status": "completed",
        "admin_notes": "Great job, resolved quickly."
    })
    assert res.status_code == 200
    assert res.get_json()["task"]["status"] == "completed"


def test_global_search(client):
    client.post("/api/login", json={"email": "admin@test.com", "password": "pass123"})

    # Search by Employee ID
    res = client.get("/api/search?q=EMP-99")
    data = res.get_json()
    assert len(data["users"]) == 1
    assert data["users"][0]["name"] == "John Employee"

    # Search by Name
    res = client.get("/api/search?q=John")
    data = res.get_json()
    assert len(data["users"]) == 1
