-- =============================================================================
-- SHIFTOPS ENTERPRISE DATABASE SCHEMA (PostgreSQL / Supabase / SQLite)
-- =============================================================================

-- 1. USERS TABLE
-- Stores credentials, roles, and employee identifiers
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(200) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
    employee_id VARCHAR(50) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_employee_id ON users(employee_id);


-- 2. TASKS TABLE
-- Stores assigned operational tasks and their lifecycle state
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'completed')),
    assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);


-- 3. SUBMISSIONS TABLE
-- Stores proof of work (links / uploaded zip files) and review feedback
CREATE TABLE IF NOT EXISTS submissions (
    id SERIAL PRIMARY KEY,
    task_id INTEGER UNIQUE NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    submitted_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    link VARCHAR(500),
    zip_path VARCHAR(250),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    admin_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_submissions_task_id ON submissions(task_id);
CREATE INDEX IF NOT EXISTS idx_submissions_submitted_by ON submissions(submitted_by);


-- =============================================================================
-- 4. SEED DATA (INITIAL DEMO ACCOUNTS & WORKFLOW)
-- =============================================================================

-- Default Passwords:
-- Admin: 'admin123'
-- Employees: 'employee123'

INSERT INTO users (id, name, email, password_hash, role, employee_id)
VALUES 
    (1, 'Ops Lead / Admin', 'admin@example.com', 'scrypt:32768:8:1$7U6E5pXo9zM$c728fb5625bf94e33918076d3330f6db9bf6002f2b3096b86d946d3e8ad6f5eb888bbdf88d011f26191c496c1da8c6682b6c97a85e13d5a42095c93c3dc4c0be', 'admin', 'ADM-001'),
    (2, 'John Doe', 'john@example.com', 'scrypt:32768:8:1$K5H7M8qW2vL$d829ec5625bf94e33918076d3330f6db9bf6002f2b3096b86d946d3e8ad6f5eb888bbdf88d011f26191c496c1da8c6682b6c97a85e13d5a42095c93c3dc4c0be', 'employee', 'EMP-101'),
    (3, 'Sarah Connor', 'sarah@example.com', 'scrypt:32768:8:1$K5H7M8qW2vL$d829ec5625bf94e33918076d3330f6db9bf6002f2b3096b86d946d3e8ad6f5eb888bbdf88d011f26191c496c1da8c6682b6c97a85e13d5a42095c93c3dc4c0be', 'employee', 'EMP-102'),
    (4, 'Alex Mercer', 'alex@example.com', 'scrypt:32768:8:1$K5H7M8qW2vL$d829ec5625bf94e33918076d3330f6db9bf6002f2b3096b86d946d3e8ad6f5eb888bbdf88d011f26191c496c1da8c6682b6c97a85e13d5a42095c93c3dc4c0be', 'employee', 'EMP-103')
ON CONFLICT (email) DO NOTHING;

INSERT INTO tasks (id, title, description, status, assigned_to, created_by)
VALUES
    (1, 'Resolve Payment Gateway Latency Spike (OPS-4830)', 'Investigate upstream vendor routes and verify traffic normalisation across EU endpoints.', 'completed', 2, 1),
    (2, 'Renew SSL Certificates for Auth Subsystem', 'Deploy new wildcard certificates on auth.internal.company.com before expiry.', 'submitted', 3, 1),
    (3, 'Investigate Redis Cache Node Memory Leak (OPS-4823)', 'Profile eviction policies and memory allocation on cluster node redis-02.', 'pending', 4, 1),
    (4, 'Kubernetes Ingress Controller Patch Rollout', 'Apply security patch v1.9.4 to ingress controllers during low-traffic window.', 'pending', 2, 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO submissions (id, task_id, submitted_by, link, admin_notes)
VALUES
    (1, 1, 2, 'https://github.com/company/payment-gateway-service/pull/142', 'Approved and verified in production staging. Latency <45ms.'),
    (2, 2, 3, 'https://drive.google.com/drive/folders/ssl-certs-2026-bundle', NULL)
ON CONFLICT (id) DO NOTHING;
