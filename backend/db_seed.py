import logging
from backend.models import db, User, Task, Submission

logger = logging.getLogger("db_seed")


def seed_database():
    """Initializes tables and populates default demo data if empty."""
    db.create_all()

    # Check if admin already exists
    if User.query.filter_by(email="admin@example.com").first():
        return

    logger.info("Seeding initial database users and tasks...")

    # 1. Create Users
    admin = User(
        name="Ops Lead / Admin",
        email="admin@example.com",
        role="admin",
        employee_id="ADM-001",
    )
    admin.set_password("admin123")

    john = User(
        name="John Doe",
        email="john@example.com",
        role="employee",
        employee_id="EMP-101",
    )
    john.set_password("employee123")

    sarah = User(
        name="Sarah Connor",
        email="sarah@example.com",
        role="employee",
        employee_id="EMP-102",
    )
    sarah.set_password("employee123")

    alex = User(
        name="Alex Mercer",
        email="alex@example.com",
        role="employee",
        employee_id="EMP-103",
    )
    alex.set_password("employee123")

    db.session.add_all([admin, john, sarah, alex])
    db.session.commit()

    # 2. Create Sample Tasks
    task1 = Task(
        title="Resolve Payment Gateway Latency Spike (OPS-4830)",
        description="Investigate upstream vendor routes and verify traffic normalisation across EU endpoints.",
        status="completed",
        assigned_to=john.id,
        created_by=admin.id,
    )

    task2 = Task(
        title="Renew SSL Certificates for Auth Subsystem",
        description="Deploy new wildcard certificates on auth.internal.company.com before expiry.",
        status="submitted",
        assigned_to=sarah.id,
        created_by=admin.id,
    )

    task3 = Task(
        title="Investigate Redis Cache Node Memory Leak (OPS-4823)",
        description="Profile eviction policies and memory allocation on cluster node redis-02.",
        status="pending",
        assigned_to=alex.id,
        created_by=admin.id,
    )

    task4 = Task(
        title="Kubernetes Ingress Controller Patch Rollout",
        description="Apply security patch v1.9.4 to ingress controllers during low-traffic window.",
        status="pending",
        assigned_to=john.id,
        created_by=admin.id,
    )

    db.session.add_all([task1, task2, task3, task4])
    db.session.commit()

    # 3. Create Sample Submissions
    sub1 = Submission(
        task_id=task1.id,
        submitted_by=john.id,
        link="https://github.com/company/payment-gateway-service/pull/142",
        admin_notes="Approved and verified in production staging. Traffic latency returned to normal (<45ms).",
    )

    sub2 = Submission(
        task_id=task2.id,
        submitted_by=sarah.id,
        link="https://drive.google.com/drive/folders/ssl-certs-2026-bundle",
        admin_notes=None,
    )

    db.session.add_all([sub1, sub2])
    db.session.commit()

    logger.info("Database seeded successfully with default accounts and tasks.")
