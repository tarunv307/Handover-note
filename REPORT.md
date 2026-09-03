# 📑 ShiftOps Enterprise Platform — Final Report (RAALE #6 + Extensions)

---

## 1. What We Built

We built an enterprise-grade web application combining automated shift handover note generation with role-based user management, task assignments, and submission review workflows. The platform allows NOC/DevOps teams to seamlessly transition between shifts by automatically aggregating, deduplicating, and grounding shift telemetry into structured PDF documents. Simultaneously, Operations Leads (Admins) can manage team members, assign work items, and review employee submissions (GitHub PRs, Google Drive links, or uploaded zip packages). Shift Engineers (Employees) can view only their assigned tasks, submit completion artifacts, and generate shift handover reports on demand. The system includes both a responsive Light/Dark Web SPA and a complete cross-platform Flutter application backed by Flask, SQLAlchemy, SQLite, and ReportLab.

### System Architecture:
```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Interfaces                      │
│   Web SPA (index.html)     │      Flutter App (lib/)        │
│   - Light / Dark Mode      │      - Provider State Pattern  │
│   - Role-Based Views       │      - Cross-Platform          │
└─────────────────────────────┬───────────────────────────────┘
                              │ REST APIs (Session Auth)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Flask Backend (:5050)                     │
│  ┌─────────────────────────┐   ┌──────────────────────────┐ │
│  │   Auth & RBAC Layer     │   │   Task & Submission CRUD │ │
│  │   Flask-Login + Bcrypt  │   │   SQLAlchemy ORM         │ │
│  └─────────────────────────┘   └──────────────────────────┘ │
│  ┌─────────────────────────┐   ┌──────────────────────────┐ │
│  │   Global Real-time      │   │   3-Stage Shift Handover │ │
│  │   Search (Name & Emp ID)│   │   (Fetch, Gen, Publish)  │ │
│  └─────────────────────────┘   └──────────────────────────┘ │
└──────────────────────┬──────────────────────┬───────────────┘
                       │                      │
┌──────────────────────▼──────┐      ┌────────▼───────────────┐
│     SQLite Database (app.db)│      │ Telemetry Seed Sources │
│  • users (roles: admin/emp) │      │ • tickets.json (Jira)  │
│  • tasks (status workflow)  │      │ • incidents.json (PD)  │
│  • submissions (links/zips) │      │ • chat.json (Slack)    │
└─────────────────────────────┘      └────────────────────────┘
```

**Status**:
- **What works**: Complete user authentication, session security, password hashing, Admin User CRUD, Task assignment and filtering, employee work submissions (links and `.zip` uploads), Admin approval workflow, real-time global search, grounded shift handover note generation with deduplication collapse, ReportLab PDF export, and automated test suite.
- **What is out of scope**: Real-time WebSocket multi-user collaborative cursor typing (standard REST polling / optimistic UI state used instead).

---

## 2. Sectioning & Workflow Logic

### Handover Sectioning Logic:
1. **Completed**: Status in `closed`, `resolved`, `done`.
2. **In Progress**: Status in `open`, `in progress`, `investigating` with an assigned engineer.
3. **Blockers/Escalations**: Status in `blocked`, `escalated`, `critical` severity, OR open tickets with **no assignee** at shift end.
4. **Watch-List**: All team chat messages, deployments, and general announcements.

### Task Management Workflow:
1. **Creation**: Admin creates a task and selects an assignee from registered employees (Status: `pending`).
2. **Execution**: Employee logs in, views assigned tasks, and submits proof of completion (GitHub link, Drive link, or `.zip` upload) (Status: `submitted`).
3. **Review**: Admin inspects the submitted artifacts, writes feedback/notes, and approves the task (Status: `completed`) or requests revisions (`pending`).

---

## 3. Methods & Decisions

| Decision Area | Chosen Approach vs Alternatives | Rationale |
|---|---|---|
| **Database** | SQLite via SQLAlchemy ORM vs raw files / PostgreSQL. | Zero-setup portability for quick development and testing while maintaining full ACID compliance and relational integrity. |
| **Authentication** | Flask-Login with secure session cookies vs stateless JWTs. | Simplifies browser session management, allows instant server-side revocation on logout, and integrates seamlessly with both SPA and Flutter. |
| **File Storage** | Local filesystem (`uploads/`) with `secure_filename` vs external cloud bucket. | Eliminates external cloud credential dependencies while supporting `.zip` submission uploads. |
| **Search Engine** | SQL `ILIKE` pattern matching across `name`, `employee_id`, and `email` vs external Elasticsearch. | Lightweight, sub-millisecond response time without extra infrastructure dependencies. |
| **PDF Generation** | Single-file ReportLab document with custom styled tables. | Satisfies requirement for a single, unfragmented, professional document with full source attribution. |

---

## 4. Test Scenarios & Results

| # | Test Scenario | Verified Behavior | Status |
|---|---|---|---|
| **1** | **Authentication & RBAC** | Login validates credentials; `/api/me` returns role; unauthorized users blocked from Admin endpoints. | **PASS** |
| **2** | **Task Creation & Visibility** | Admin assigns task to Employee; Employee sees only their tasks; other employees cannot view or submit it. | **PASS** |
| **3** | **Submission Workflow** | Employee submits GitHub link; Admin reviews and sets status to `completed` with feedback notes. | **PASS** |
| **4** | **Global Search** | Searching `"John"` or `"EMP-101"` instantly returns matching user record; partial queries work. | **PASS** |
| **5** | **Handover Deduplication** | Multi-update ticket `OPS-4830` collapses into 1 item in `Completed` with progression `open → escalated → resolved`. | **PASS** |
| **6** | **Empty Shift Handling** | Shift window with 0 events renders `• Nothing to report` across all 4 sections in PDF and UI. | **PASS** |

---

## 5. How to Run with a Fresh Data Source

1. **Option A: Web Portal**
   - Run `python -m backend.app` and open `http://localhost:5050`.
   - Log in with `admin@example.com` / `admin123`.
   - Manage team members in the **Users** tab, assign work in the **Tasks** tab, and generate handover reports in the **Shift Handover** tab.

2. **Option B: Flutter Mobile/Desktop App**
   - Run `cd frontend_flutter && flutter run`.

3. **Option C: CLI Generation**
   ```bash
   python -m backend.cli --start "2026-09-03T14:00:00" --end "2026-09-03T22:00:00" --timezone "Asia/Kolkata"
   ```
