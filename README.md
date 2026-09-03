# 🚀 ShiftOps — Enterprise Handover & Task Management Platform

A production-ready enterprise web application that combines:
1. **Automated Shift Handover Note Generator**: Pulls shift activity from ticketing (Jira), incident logs (PagerDuty), and chat channels (Slack); filters strictly to the shift window; normalizes to UTC; collapses duplicates; assigns to 4 standard sections; and exports a single-file, professional PDF.
2. **User Management & Role-Based Access Control (RBAC)**:
   - **Admin (Ops Lead)**: Manages users, creates and assigns tasks to employees, reviews submitted work (GitHub repo, Drive link, or uploaded zip), and marks tasks complete.
   - **Employee (Shift Engineer)**: Views their assigned tasks, submits work artifacts (link or zip file), and tracks review status.
3. **Global Real-Time Search**: Instant search by Name or Employee ID across team members and assigned tasks.
4. **Dual Frontend**:
   - **Web Single-Page App (`frontend/index.html`)**: Responsive glassmorphism UI with Light & Dark theme support.
   - **Cross-Platform Mobile/Desktop App (`frontend_flutter/`)**: Complete Flutter codebase with Provider state management.

---

## 🏗️ Architecture Overview

```
                          ┌────────────────────────┐
                          │     Web SPA / Flutter  │
                          │  (Admin / Employee UI) │
                          └───────────┬────────────┘
                                      │ REST + Session Auth
                                      ▼
                          ┌────────────────────────┐
                          │   Flask API (:5050)    │
                          ├────────────────────────┤
                          │ • Auth & Sessions      │
                          │ • User & Task CRUD     │
                          │ • Submission & Review  │
                          │ • Global Search        │
                          │ • 3-Stage Handover Gen │
                          └─────┬────────────┬─────┘
                                │            │
                ┌───────────────▼┐          ┌▼─────────────────────────┐
                │ SQLite (app.db)│          │ Telemetry Mock Sources   │
                │ • users        │          │ • tickets.json           │
                │ • tasks        │          │ • incidents.json         │
                │ • submissions  │          │ • chat.json              │
                └────────────────┘          └──────────────────────────┘
```

---

## ⚡ Quick Start

### 1. Backend Setup & Run
```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start the backend server
python -m backend.app
```
Access the web portal at **[http://localhost:5050](http://localhost:5050)**.

---

## 🔑 Pre-Seeded Demo Accounts

| Role | Email | Password | Employee ID | Name | Capabilities |
|---|---|---|---|---|---|
| **Admin** | `admin@example.com` | `admin123` | `ADM-001` | Ops Lead / Admin | Manage users, assign tasks, review submissions, generate handovers |
| **Employee** | `john@example.com` | `employee123` | `EMP-101` | John Doe | View assigned tasks, submit work (link/zip), generate handovers |
| **Employee** | `sarah@example.com` | `employee123` | `EMP-102` | Sarah Connor | View assigned tasks, submit work, generate handovers |
| **Employee** | `alex@example.com` | `employee123` | `EMP-103` | Alex Mercer | View assigned tasks, submit work, generate handovers |

*(Quick 1-click login buttons are available directly on the login screen).*

---

## 📱 Flutter Frontend Setup (`frontend_flutter/`)

```bash
cd frontend_flutter
flutter pub get
flutter run -d chrome  # or -d macos / -d android / -d ios
```

---

## 📋 Complete REST API Endpoints

### 1. Authentication
- `POST /api/login`: Logs in with `{ "email", "password" }`.
- `POST /api/logout`: Destroys session.
- `GET /api/me`: Returns current authenticated user and role.

### 2. User Management (Admin Only)
- `GET /api/users?q=...`: Lists all users (supports name/ID search).
- `POST /api/users`: Creates a new user `{ name, email, password, role, employee_id }`.
- `PUT /api/users/<id>`: Updates user info.
- `DELETE /api/users/<id>`: Deletes a user.

### 3. Task Management
- `GET /api/tasks`: Returns all tasks for Admin; returns only assigned tasks for Employee.
- `POST /api/tasks`: Admin assigns task `{ title, description, assigned_to }`.
- `PUT /api/tasks/<id>`: Updates task status or details.
- `DELETE /api/tasks/<id>`: Admin deletes task.
- `GET /api/tasks/<id>/submission`: Retrieves submission for task.

### 4. Submissions & Reviews
- `POST /api/tasks/<id>/submit`: Employee submits GitHub/Drive link or uploads `.zip` file.
- `PUT /api/submissions/<id>`: Admin reviews submission, adds notes, and marks task complete.
- `GET /api/submissions/<id>/download`: Downloads uploaded `.zip` artifact.

### 5. Global Search
- `GET /api/search?q=...`: Real-time search across team members and tasks.

### 6. Shift Handover Generator
- `POST /api/generate`: Generates shift note and PDF from `{ shift_start, shift_end, timezone }`.
- `GET /api/download/<id>`: Downloads single-file ReportLab PDF.
- `GET /api/sources`: Returns health and record counts of telemetry files.

---

## 🧪 Automated Testing

Run the full pytest suite (11 test suites covering Auth, Tasks, Submissions, Search, Handover deduplication, and PDF export):

```bash
PYTHONPATH=. pytest -v
```
*(All 11 tests passing in < 1.0s).*
