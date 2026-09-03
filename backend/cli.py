import argparse
import sys
import json
from pathlib import Path

from backend.config import DATA_DIR, OUTPUT_DIR
from backend.fetch_activity import fetch_shift_activity
from backend.generator import generate_handover_note
from backend.publisher import publish_pdf


def main():
    parser = argparse.ArgumentParser(
        description="Shift Handover Note Generator CLI — Automated, traceable, grounded shift reports."
    )
    parser.add_argument(
        "--start", "-s",
        required=True,
        help="Shift start timestamp (ISO format, e.g. '2026-09-03T14:00:00' or '2026-09-03 14:00:00')"
    )
    parser.add_argument(
        "--end", "-e",
        required=True,
        help="Shift end timestamp (ISO format, e.g. '2026-09-03T22:00:00' or '2026-09-03 22:00:00')"
    )
    parser.add_argument(
        "--timezone", "-tz",
        default="Asia/Kolkata",
        help="Local shift timezone (default: 'Asia/Kolkata')"
    )
    parser.add_argument(
        "--out", "-o",
        default=None,
        help="Custom PDF output file path"
    )
    parser.add_argument(
        "--json-out", "-j",
        default=None,
        help="Optional path to save JSON note structure"
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress verbose terminal output"
    )

    args = parser.parse_args()

    try:
        if not args.quiet:
            print("=" * 60)
            print("🚀 SHIFT HANDOVER NOTE GENERATOR")
            print(f"Shift Window: {args.start} → {args.end} ({args.timezone})")
            print("=" * 60)

        # Stage 1: Fetch
        events, meta = fetch_shift_activity(
            shift_start_str=args.start,
            shift_end_str=args.end,
            timezone_str=args.timezone,
            data_dir=DATA_DIR
        )

        # Stage 2: Generate
        note_data = generate_handover_note(events, meta)

        # Stage 3: Publish
        out_pdf_path = Path(args.out) if args.out else OUTPUT_DIR / f"{note_data['id']}.pdf"
        publish_pdf(note_data, out_pdf_path)

        if args.json_out:
            json_path = Path(args.json_out)
            json_path.parent.mkdir(parents=True, exist_ok=True)
            with open(json_path, "w", encoding="utf-8") as f:
                json.dump(note_data, f, indent=2)
            if not args.quiet:
                print(f"📄 JSON metadata saved to: {json_path}")

        if not args.quiet:
            print("\n📌 EXECUTIVE SUMMARY:")
            print(note_data.get("summary"))
            print("\n📋 SECTION SUMMARY:")
            for sec, items in note_data["sections"].items():
                print(f"\n[{sec.upper()}] ({len(items)} items)")
                if not items:
                    print("  • Nothing to report")
                else:
                    for it in items:
                        print(f"  • {it['item']} ({it['source']})")

            print("\n" + "=" * 60)
            print(f"✅ Handover PDF generated successfully: {out_pdf_path}")
            print("=" * 60)

        sys.exit(0)

    except Exception as e:
        print(f"\n❌ FATAL ERROR: Handover generation failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
