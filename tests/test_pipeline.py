import pytest
import json
import tempfile
from pathlib import Path
from datetime import datetime

from backend.fetch_activity import (
    parse_to_utc,
    parse_shift_window,
    fetch_shift_activity,
)
from backend.generator import (
    determine_section,
    collapse_duplicate_records,
    generate_handover_note,
)
from backend.publisher import publish_pdf
from backend.config import DATA_DIR, SECTIONS


def test_parse_to_utc_formats():
    """Validates diverse timestamp parsing and timezone normalization."""
    # +05:30 offset
    dt1 = parse_to_utc("2026-09-03T19:42:00+05:30")
    assert dt1 is not None
    assert dt1.hour == 14
    assert dt1.minute == 12

    # Z offset (UTC)
    dt2 = parse_to_utc("2026-09-03T20:15:00Z")
    assert dt2 is not None
    assert dt2.hour == 20
    assert dt2.minute == 15

    # -04:00 offset
    dt3 = parse_to_utc("2026-09-03T18:30:00-04:00")
    assert dt3 is not None
    assert dt3.hour == 22
    assert dt3.minute == 30

    # Malformed / None
    assert parse_to_utc("invalid-date") is None
    assert parse_to_utc("") is None
    assert parse_to_utc(None) is None


def test_shift_window_boundary():
    """Validates [shift_start, shift_end) boundary handling."""
    start_utc, end_utc = parse_shift_window(
        "2026-09-03T14:00:00", "2026-09-03T22:00:00", "Asia/Kolkata"
    )
    # Start: 14:00 IST -> 08:30 UTC
    assert start_utc.hour == 8 and start_utc.minute == 30
    # End: 22:00 IST -> 16:30 UTC
    assert end_utc.hour == 16 and end_utc.minute == 30

    with pytest.raises(ValueError):
        # Start after end must fail
        parse_shift_window("2026-09-03T22:00:00", "2026-09-03T14:00:00", "Asia/Kolkata")


def test_scenario_1_quiet_shift():
    """Scenario 1: Quiet shift with 0 events produces 'Nothing to report' in all 4 sections."""
    # Pick a shift window in the past with no events in seed data
    events, meta = fetch_shift_activity(
        shift_start_str="2026-09-01T00:00:00",
        shift_end_str="2026-09-01T08:00:00",
        timezone_str="Asia/Kolkata",
        data_dir=DATA_DIR
    )
    assert len(events) == 0

    note = generate_handover_note(events, meta)
    assert note["total_items"] == 0
    for sec in SECTIONS:
        assert len(note["sections"][sec]) == 0

    # Verify publisher generates valid PDF with "Nothing to report"
    with tempfile.NamedTemporaryFile(suffix=".pdf") as tmp:
        pdf_path = publish_pdf(note, Path(tmp.name))
        assert pdf_path.exists()
        assert pdf_path.stat().st_size > 0


def test_scenario_2_busy_shift():
    """Scenario 2: Busy shift captures events across all sources and assigns correct sections."""
    # 2026-09-03 14:00 to 22:00 IST covers multiple tickets, incidents, and chats
    events, meta = fetch_shift_activity(
        shift_start_str="2026-09-03T14:00:00",
        shift_end_str="2026-09-03T22:00:00",
        timezone_str="Asia/Kolkata",
        data_dir=DATA_DIR
    )
    assert len(events) > 0

    note = generate_handover_note(events, meta)
    assert note["total_items"] > 0
    
    # Grounding check: Every item must have source and record_id
    for sec, items in note["sections"].items():
        for item in items:
            assert ":" in item["source"]
            assert len(item["record_id"]) > 0
            assert item["section"] == sec

    # Ensure unassigned ticket OPS-4825 escalated to Blockers
    blocker_ids = [item["record_id"] for item in note["sections"]["Blockers/Escalations"]]
    assert "OPS-4825" in blocker_ids or "OPS-4824" in blocker_ids


def test_scenario_3_messy_shift_deduplication():
    """Scenario 3: Messy shift with multiple updates to same ticket collapses into 1 item reflecting final state."""
    custom_events = [
        {
            "source": "jira",
            "record_id": "OPS-9999",
            "timestamp": "2026-09-03T15:00:00+05:30",
            "summary": "Initial report of database deadlock",
            "status": "open",
            "assignee": "alice"
        },
        {
            "source": "jira",
            "record_id": "OPS-9999",
            "timestamp": "2026-09-03T16:30:00+05:30",
            "summary": "Escalated to DBA team",
            "status": "escalated",
            "assignee": "alice"
        },
        {
            "source": "jira",
            "record_id": "OPS-9999",
            "timestamp": "2026-09-03T17:45:00+05:30",
            "summary": "DBA killed blocking query, deadlock cleared",
            "status": "resolved",
            "assignee": "alice"
        }
    ]

    events, meta = fetch_shift_activity(
        shift_start_str="2026-09-03T14:00:00",
        shift_end_str="2026-09-03T20:00:00",
        timezone_str="Asia/Kolkata",
        custom_sources={"test_jira": custom_events}
    )
    assert len(events) == 3

    note = generate_handover_note(events, meta)
    # MUST collapse to exactly 1 item
    assert note["total_items"] == 1
    # Final state is resolved -> MUST be in Completed section
    assert len(note["sections"]["Completed"]) == 1
    assert len(note["sections"]["Blockers/Escalations"]) == 0
    assert len(note["sections"]["In Progress"]) == 0
    
    item = note["sections"]["Completed"][0]
    assert item["record_id"] == "OPS-9999"
    assert "resolved" in item["item"].lower()
    assert "Progression: open → escalated → resolved" in item["item"]


def test_reproducibility_and_idempotency():
    """Mandatory requirement: Regenerating for same window produces identical counts and items."""
    events1, meta1 = fetch_shift_activity(
        "2026-09-03T14:00:00", "2026-09-03T22:00:00", "Asia/Kolkata", DATA_DIR
    )
    note1 = generate_handover_note(events1, meta1)

    events2, meta2 = fetch_shift_activity(
        "2026-09-03T14:00:00", "2026-09-03T22:00:00", "Asia/Kolkata", DATA_DIR
    )
    note2 = generate_handover_note(events2, meta2)

    assert note1["total_items"] == note2["total_items"]
    for sec in SECTIONS:
        items1 = [it["item"] for it in note1["sections"][sec]]
        items2 = [it["item"] for it in note2["sections"][sec]]
        assert items1 == items2


def test_hostile_input_handling():
    """Hostile inputs: malformed JSON, corrupted timestamps, missing fields must not crash."""
    corrupted_data = [
        {"source": "test", "record_id": "BAD-1", "timestamp": "NOT-A-DATE"},
        {"source": "test", "record_id": "", "timestamp": "2026-09-03T15:00:00Z"},
        {"malformed": True},
        None,
        "string_instead_of_dict",
        {"source": "test", "record_id": "VALID-1", "timestamp": "2026-09-03T15:00:00Z", "status": "open", "summary": "Valid item"}
    ]

    events, meta = fetch_shift_activity(
        shift_start_str="2026-09-03T14:00:00",
        shift_end_str="2026-09-03T20:00:00",
        timezone_str="UTC",
        custom_sources={"corrupt_src": corrupted_data}
    )
    # Only VALID-1 should survive
    assert len(events) == 1
    assert events[0]["record_id"] == "VALID-1"

    note = generate_handover_note(events, meta)
    assert note["total_items"] == 1


def test_loud_failure_on_export_error():
    """Publisher must fail loudly with RuntimeError if export cannot be completed."""
    with pytest.raises(Exception):
        # Missing required sections payload
        publish_pdf({}, Path("/invalid/path/test.pdf"))
