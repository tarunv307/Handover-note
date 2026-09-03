import logging
from collections import defaultdict
from datetime import datetime
from typing import List, Dict, Any, Tuple
from backend.config import SECTIONS, STATUS_COMPLETED, STATUS_IN_PROGRESS, STATUS_BLOCKERS

logger = logging.getLogger("generator")


def determine_section(event: Dict[str, Any]) -> str:
    """
    Applies fixed, deterministic sectioning rules according to spec:
    - Completed: status is closed, resolved, done
    - In Progress: status is open, in progress, investigating (non-chat)
    - Blockers/Escalations: status is blocked, escalated, critical OR no assignee at shift end
    - Watch-List: chat messages, alerts, and fallback
    """
    status = str(event.get("status", "")).lower().strip()
    source = str(event.get("source", "")).lower().strip()
    assignee = event.get("assignee")
    severity = str(event.get("severity", "")).lower().strip()

    # Chat messages always go to Watch-List
    if source in ("slack", "chat", "teams", "discord") or status == "chat":
        return "Watch-List"

    # Completed items
    if status in STATUS_COMPLETED:
        return "Completed"

    # Blockers / Escalations
    # 1. Explicit blocker/escalated status or critical severity
    if status in STATUS_BLOCKERS or severity == "critical":
        return "Blockers/Escalations"

    # 2. Open/In-progress ticket with NO assignee at shift end becomes a blocker/escalation
    if status in STATUS_IN_PROGRESS:
        if assignee is None or str(assignee).strip().lower() in ("", "unassigned", "none", "null"):
            return "Blockers/Escalations"
        return "In Progress"

    # Fallback
    return "Watch-List"


def format_item_text(event: Dict[str, Any], history: List[Dict[str, Any]]) -> str:
    """
    Generates a single-line, grounded item text reflecting final state and source details.
    """
    record_id = event.get("record_id", "UNKNOWN")
    summary = event.get("summary", "No details").strip()
    status = event.get("status", "unknown").strip()
    source = event.get("source", "source").strip()
    assignee = event.get("assignee")
    user = event.get("user")
    channel = event.get("channel")
    severity = event.get("severity")

    # If status progressed across multiple updates during the shift, show progression
    status_progression = []
    for h in history:
        h_status = h.get("status")
        if h_status and h_status not in status_progression:
            status_progression.append(h_status)

    progression_str = ""
    if len(status_progression) > 1:
        progression_str = f" (Progression: {' → '.join(status_progression)})"

    if source in ("slack", "chat", "teams", "discord") or status == "chat":
        user_info = f"@{user}" if user else "chat"
        chan_info = f" in {channel}" if channel else ""
        return f"{record_id} — [{user_info}{chan_info}] \"{summary}\""

    details = []
    if status:
        details.append(f"Status: {status.title()}")
    if severity:
        details.append(f"Severity: {severity.upper()}")
    if assignee:
        details.append(f"Assignee: {assignee}")
    elif status not in STATUS_COMPLETED and source not in ("slack", "chat"):
        details.append("Assignee: UNASSIGNED")

    details_str = f" [{', '.join(details)}]" if details else ""
    return f"{record_id} — {summary}{details_str}{progression_str}"


def collapse_duplicate_records(events: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Mandatory Deduplication: Groups events by (source, record_id).
    Sorts by timestamp ascending, keeping all historical updates for progression
    and producing a single collapsed record representing the final state at shift end.
    """
    grouped = defaultdict(list)
    for ev in events:
        key = (ev.get("source", "unknown").lower(), str(ev.get("record_id", "")).strip())
        grouped[key].append(ev)

    collapsed_list = []
    for (src, rec_id), history in grouped.items():
        # Sort history by parsed timestamp ascending
        history_sorted = sorted(
            history,
            key=lambda x: x.get("parsed_datetime_utc", datetime.min)
        )
        final_event = dict(history_sorted[-1])
        final_event["_history"] = history_sorted
        collapsed_list.append(final_event)

    return collapsed_list


def generate_executive_summary(section_items: Dict[str, List[Dict[str, Any]]], meta: Dict[str, Any]) -> str:
    """
    Synthesizes a grounded 1-2 sentence executive overview without hallucinations.
    """
    c_count = len(section_items["Completed"])
    p_count = len(section_items["In Progress"])
    b_count = len(section_items["Blockers/Escalations"])
    w_count = len(section_items["Watch-List"])
    total = c_count + p_count + b_count + w_count

    if total == 0:
        return f"Quiet shift ({meta.get('shift_start_local')} to {meta.get('shift_end_local')}). No qualifying events recorded in the shift window across configured sources."

    parts = []
    if c_count:
        parts.append(f"{c_count} completed task{'s' if c_count > 1 else ''}")
    if p_count:
        parts.append(f"{p_count} in-progress item{'s' if p_count > 1 else ''}")
    if b_count:
        parts.append(f"{b_count} blocker{'s' if b_count > 1 else ''}/escalation{'s' if b_count > 1 else ''}")
    if w_count:
        parts.append(f"{w_count} watch-list item{'s' if w_count > 1 else ''}")

    summary_text = f"Shift window ({meta.get('shift_start_local')} - {meta.get('shift_end_local')} {meta.get('timezone')}) logged {total} total activity record{'s' if total > 1 else ''}: "
    summary_text += ", ".join(parts) + "."

    if b_count > 0:
        blocker_ids = [item["record_id"] for item in section_items["Blockers/Escalations"]]
        summary_text += f" Immediate handover attention required for: {', '.join(blocker_ids)}."

    return summary_text


def format_slack_markdown(note_data: Dict[str, Any]) -> str:
    """
    Formats the note into a clean, ready-to-paste Slack/Teams message.
    """
    meta = note_data.get("meta", {})
    lines = [
        f":clipboard: *SHIFT HANDOVER NOTE* ({meta.get('shift_start_local')} → {meta.get('shift_end_local')} {meta.get('timezone')})",
        f"> {note_data.get('summary', '')}",
        ""
    ]
    
    sections = note_data.get("sections", {})
    emoji_map = {
        "Completed": ":white_check_mark:",
        "In Progress": ":hourglass_flowing_sand:",
        "Blockers/Escalations": ":rotating_light:",
        "Watch-List": ":eyes:"
    }
    
    for sec_name in SECTIONS:
        emoji = emoji_map.get(sec_name, ":pushpin:")
        lines.append(f"*{emoji} {sec_name}*")
        items = sections.get(sec_name, [])
        if not items:
            lines.append("• _Nothing to report_")
        else:
            for it in items:
                lines.append(f"• `{it['source']}` — {it['item']}")
        lines.append("")
        
    return "\n".join(lines).strip()


def generate_handover_note(
    events: List[Dict[str, Any]], meta: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Stage 2 Pipeline: Generator
    1. Deduplicates multiple updates to the same record (No-Duplicate Rule).
    2. Assigns each surviving event to one of 4 sections.
    3. Sorts deterministically by timestamp, source, record_id.
    4. Handles empty sections with 'Nothing to report'.
    5. Produces formatted item structures matching interface contract.
    """
    # Step 1: Collapse duplicates
    collapsed_events = collapse_duplicate_records(events)

    # Step 2: Initialize section containers
    section_items: Dict[str, List[Dict[str, Any]]] = {sec: [] for sec in SECTIONS}

    # Step 3: Assign sections and build formatted item
    for ev in collapsed_events:
        target_section = determine_section(ev)
        history = ev.get("_history", [ev])
        item_text = format_item_text(ev, history)
        
        # Sourced identifier per spec: source:record_id (e.g. ticketing:OPS-4821 or jira:OPS-4821)
        src_label = ev.get("source", "source")
        record_id = str(ev.get("record_id", "unknown"))
        source_tag = f"{src_label}:{record_id}"

        item_entry = {
            "section": target_section,
            "item": item_text,
            "source": source_tag,
            "record_id": record_id,
            "timestamp": ev.get("timestamp"),
            "timestamp_utc": ev.get("timestamp_utc"),
            "status": ev.get("status"),
            "assignee": ev.get("assignee"),
            "raw": ev.get("raw", {})
        }
        section_items[target_section].append(item_entry)

    # Step 4: Deterministic sorting within each section (by timestamp_utc, source, record_id)
    for sec in SECTIONS:
        section_items[sec].sort(
            key=lambda x: (
                x.get("timestamp_utc") or "",
                x.get("source") or "",
                x.get("record_id") or ""
            )
        )

    # Step 5: Summary generation
    exec_summary = generate_executive_summary(section_items, meta)

    import pytz
    now_utc = datetime.now(pytz.UTC)
    note_data = {
        "id": f"handover-{now_utc.strftime('%Y%m%d%H%M%S')}-{abs(hash(meta.get('shift_start_utc', '')))%10000:04d}",
        "generated_at_utc": now_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "meta": meta,
        "summary": exec_summary,
        "sections": section_items,
        "total_items": sum(len(items) for items in section_items.values())
    }

    note_data["slack_markdown"] = format_slack_markdown(note_data)
    
    logger.info(
        f"Handover note generated: {note_data['total_items']} items across 4 sections."
    )
    return note_data
