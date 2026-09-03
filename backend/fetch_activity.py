import json
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import pytz
from backend.config import DATA_DIR

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("fetch_activity")


def parse_to_utc(dt_str: str, default_tz: str = "UTC") -> Optional[datetime]:
    """
    Parses an ISO 8601 or common timestamp string into a timezone-aware UTC datetime.
    Supports offsets (+05:30, -04:00, Z), and applies default_tz if naive.
    """
    if not dt_str or not isinstance(dt_str, str):
        return None
    try:
        # Standard ISO parse
        dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            tz = pytz.timezone(default_tz)
            dt = tz.localize(dt)
        return dt.astimezone(pytz.UTC)
    except Exception as e:
        logger.warning(f"Failed to parse timestamp '{dt_str}': {e}")
        return None


def parse_shift_window(
    start_str: str, end_str: str, timezone_str: str = "Asia/Kolkata"
) -> Tuple[datetime, datetime]:
    """
    Converts shift start and end strings in a given local timezone to UTC datetime boundaries.
    """
    try:
        tz = pytz.timezone(timezone_str)
    except Exception:
        logger.warning(f"Invalid timezone '{timezone_str}', defaulting to UTC")
        tz = pytz.UTC

    # Try ISO parse
    try:
        if "T" in start_str or "-" in start_str:
            start_dt = datetime.fromisoformat(start_str.replace("Z", "+00:00"))
        else:
            start_dt = datetime.strptime(start_str, "%Y-%m-%d %H:%M:%S")
        if start_dt.tzinfo is None:
            start_dt = tz.localize(start_dt)
        start_utc = start_dt.astimezone(pytz.UTC)
    except Exception as e:
        raise ValueError(f"Invalid shift start timestamp '{start_str}': {e}")

    try:
        if "T" in end_str or "-" in end_str:
            end_dt = datetime.fromisoformat(end_str.replace("Z", "+00:00"))
        else:
            end_dt = datetime.strptime(end_str, "%Y-%m-%d %H:%M:%S")
        if end_dt.tzinfo is None:
            end_dt = tz.localize(end_dt)
        end_utc = end_dt.astimezone(pytz.UTC)
    except Exception as e:
        raise ValueError(f"Invalid shift end timestamp '{end_str}': {e}")

    if start_utc >= end_utc:
        raise ValueError(f"Shift start ({start_utc}) must be strictly before shift end ({end_utc})")

    return start_utc, end_utc


def fetch_tickets(data_dir: Path = DATA_DIR) -> List[Dict[str, Any]]:
    """Loads tickets from JSON file with error resilience."""
    ticket_file = data_dir / "tickets.json"
    if not ticket_file.exists():
        logger.warning(f"Tickets source not found at {ticket_file}. Skipping.")
        return []
    try:
        with open(ticket_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if not isinstance(data, list):
                logger.warning(f"Malformed tickets.json: Expected list, got {type(data)}. Skipping.")
                return []
            events = []
            for item in data:
                if not isinstance(item, dict):
                    continue
                record_id = str(item.get("id", "")).strip()
                if not record_id:
                    continue
                events.append({
                    "source": item.get("source", "ticketing"),
                    "record_id": record_id,
                    "timestamp": item.get("timestamp"),
                    "summary": item.get("summary") or item.get("title") or "No summary provided",
                    "status": str(item.get("status", "open")).lower().strip(),
                    "assignee": item.get("assignee"),
                    "priority": item.get("priority", "medium"),
                    "raw": item
                })
            return events
    except Exception as e:
        logger.warning(f"Error reading tickets source: {e}. Skipping.")
        return []


def fetch_incidents(data_dir: Path = DATA_DIR) -> List[Dict[str, Any]]:
    """Loads incidents from JSON file with error resilience."""
    incident_file = data_dir / "incidents.json"
    if not incident_file.exists():
        logger.warning(f"Incidents source not found at {incident_file}. Skipping.")
        return []
    try:
        with open(incident_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if not isinstance(data, list):
                logger.warning(f"Malformed incidents.json: Expected list. Skipping.")
                return []
            events = []
            for item in data:
                if not isinstance(item, dict):
                    continue
                record_id = str(item.get("id", "")).strip()
                if not record_id:
                    continue
                status = item.get("status")
                if not status:
                    status = "resolved" if item.get("resolved") is True else "investigating"
                events.append({
                    "source": item.get("source", "incident"),
                    "record_id": record_id,
                    "timestamp": item.get("timestamp"),
                    "summary": item.get("description") or item.get("summary") or "Incident reported",
                    "status": str(status).lower().strip(),
                    "assignee": item.get("assignee"),
                    "severity": item.get("severity", "high"),
                    "service": item.get("service", "core"),
                    "raw": item
                })
            return events
    except Exception as e:
        logger.warning(f"Error reading incidents source: {e}. Skipping.")
        return []


def fetch_chat(data_dir: Path = DATA_DIR) -> List[Dict[str, Any]]:
    """Loads chat messages from JSON file with error resilience."""
    chat_file = data_dir / "chat.json"
    if not chat_file.exists():
        logger.warning(f"Chat source not found at {chat_file}. Skipping.")
        return []
    try:
        with open(chat_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if not isinstance(data, list):
                logger.warning(f"Malformed chat.json: Expected list. Skipping.")
                return []
            events = []
            for item in data:
                if not isinstance(item, dict):
                    continue
                record_id = str(item.get("id", "")).strip()
                if not record_id:
                    continue
                events.append({
                    "source": item.get("source", "chat"),
                    "record_id": record_id,
                    "timestamp": item.get("timestamp"),
                    "summary": item.get("text") or item.get("message") or "Message logged",
                    "status": "chat",
                    "user": item.get("user", "unknown"),
                    "channel": item.get("channel", "general"),
                    "raw": item
                })
            return events
    except Exception as e:
        logger.warning(f"Error reading chat source: {e}. Skipping.")
        return []


def fetch_shift_activity(
    shift_start_str: str,
    shift_end_str: str,
    timezone_str: str = "Asia/Kolkata",
    data_dir: Path = DATA_DIR,
    custom_sources: Optional[Dict[str, Any]] = None
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """
    Stage 1 Pipeline: Fetch-Activity
    Pulls events from configured sources, normalizes timestamps to UTC,
    and filters strictly to [shift_start, shift_end).
    
    Returns:
        (filtered_events, metadata_dict)
    """
    start_utc, end_utc = parse_shift_window(shift_start_str, shift_end_str, timezone_str)
    
    all_raw_events: List[Dict[str, Any]] = []
    source_stats: Dict[str, int] = {}
    
    if custom_sources:
        # Use provided memory sources if given (e.g. in test fixtures or live API)
        for src_name, items in custom_sources.items():
            if isinstance(items, list):
                all_raw_events.extend(items)
    else:
        # Load from configured data files
        tickets = fetch_tickets(data_dir)
        incidents = fetch_incidents(data_dir)
        chat = fetch_chat(data_dir)
        
        all_raw_events.extend(tickets)
        all_raw_events.extend(incidents)
        all_raw_events.extend(chat)
        
        source_stats = {
            "tickets_total": len(tickets),
            "incidents_total": len(incidents),
            "chat_total": len(chat)
        }

    filtered_events: List[Dict[str, Any]] = []
    skipped_count = 0
    
    for event in all_raw_events:
        if not isinstance(event, dict):
            skipped_count += 1
            continue
        
        record_id = str(event.get("record_id", "")).strip()
        if not record_id:
            skipped_count += 1
            continue

        ts_str = event.get("timestamp")
        event_utc = parse_to_utc(ts_str, default_tz=timezone_str)
        if event_utc is None:
            skipped_count += 1
            continue
        
        # Strict window check: [shift_start, shift_end)
        if start_utc <= event_utc < end_utc:
            event_copy = dict(event)
            event_copy["parsed_datetime_utc"] = event_utc
            event_copy["timestamp_utc"] = event_utc.strftime("%Y-%m-%dT%H:%M:%SZ")
            filtered_events.append(event_copy)

    meta = {
        "shift_start_local": shift_start_str,
        "shift_end_local": shift_end_str,
        "timezone": timezone_str,
        "shift_start_utc": start_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "shift_end_utc": end_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "total_source_events": len(all_raw_events),
        "in_window_events": len(filtered_events),
        "skipped_events": skipped_count,
        "source_stats": source_stats
    }
    
    logger.info(
        f"Fetch completed: {len(filtered_events)} events inside window [{start_utc.isoformat()} -> {end_utc.isoformat()}]"
    )
    return filtered_events, meta
