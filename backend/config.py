import os
import logging
from pathlib import Path
from dotenv import load_dotenv

logger = logging.getLogger("config")

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

# App directories
DATA_DIR = Path(os.getenv("DATA_DIR", BASE_DIR / "backend" / "data"))
OUTPUT_DIR = Path(os.getenv("OUTPUT_DIR", BASE_DIR / "backend" / "output"))
UPLOAD_FOLDER = Path(os.getenv("UPLOAD_FOLDER", BASE_DIR / "backend" / "uploads"))

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
DATA_DIR.mkdir(parents=True, exist_ok=True)
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

# Database & Security
SECRET_KEY = os.getenv("SECRET_KEY", "super-secret-enterprise-handover-key-2026")
DEFAULT_SQLITE_URL = f"sqlite:///{BASE_DIR / 'backend' / 'app.db'}"

# Read Supabase / PostgreSQL URL from env
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_SQLITE_URL)

# SQLAlchemy requires 'postgresql://' instead of 'postgres://'
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

SQLALCHEMY_DATABASE_URI = DATABASE_URL
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_ENGINE_OPTIONS = {
    "pool_pre_ping": True,
    "pool_recycle": 300,
}

# Server config
PORT = int(os.getenv("PORT", "5050"))
HOST = os.getenv("HOST", "0.0.0.0")
DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "1", "t")

# Standard Section Names
SECTIONS = [
    "Completed",
    "In Progress",
    "Blockers/Escalations",
    "Watch-List",
]

STATUS_COMPLETED = {"closed", "resolved", "done"}
STATUS_IN_PROGRESS = {"open", "in progress", "investigating"}
STATUS_BLOCKERS = {"blocked", "escalated", "critical"}
