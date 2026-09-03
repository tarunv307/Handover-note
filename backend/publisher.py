import os
import logging
from pathlib import Path
from typing import Dict, Any
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    HRFlowable,
    KeepTogether,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

from backend.config import OUTPUT_DIR, SECTIONS

logger = logging.getLogger("publisher")


def get_custom_palette():
    return {
        "primary": colors.HexColor("#1e293b"),       # Slate 800
        "secondary": colors.HexColor("#475569"),     # Slate 600
        "accent": colors.HexColor("#2563eb"),        # Blue 600
        "bg_light": colors.HexColor("#f8fafc"),      # Slate 50
        "border": colors.HexColor("#e2e8f0"),        # Slate 200
        "completed_tag": colors.HexColor("#16a34a"), # Green 600
        "inprogress_tag": colors.HexColor("#2563eb"),# Blue 600
        "blocker_tag": colors.HexColor("#dc2626"),   # Red 600
        "watchlist_tag": colors.HexColor("#d97706"), # Amber 600
        "empty_text": colors.HexColor("#64748b"),    # Slate 500
    }


def publish_pdf(note_data: Dict[str, Any], output_path: Path = None) -> Path:
    """
    Stage 3 Pipeline: Publisher
    Renders the handover note as a professional, single-file PDF using ReportLab.
    Fails loudly if anything goes wrong.
    """
    if not note_data or "sections" not in note_data:
        raise ValueError("Invalid note_data: Missing required sections payload")

    note_id = note_data.get("id", "handover-report")
    if output_path is None:
        output_path = OUTPUT_DIR / f"{note_id}.pdf"
    
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        doc = SimpleDocTemplate(
            str(output_path),
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36,
        )

        styles = getSampleStyleSheet()
        palette = get_custom_palette()

        # Define styles
        title_style = ParagraphStyle(
            "DocTitle",
            parent=styles["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=20,
            leading=24,
            textColor=palette["primary"],
            alignment=TA_LEFT,
        )
        
        subtitle_style = ParagraphStyle(
            "DocSubtitle",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=9,
            leading=13,
            textColor=palette["secondary"],
        )

        summary_box_style = ParagraphStyle(
            "SummaryText",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=palette["primary"],
        )

        section_heading_style = ParagraphStyle(
            "SectionHeading",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=16,
            textColor=colors.white,
        )

        item_text_style = ParagraphStyle(
            "ItemText",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=13,
            textColor=palette["primary"],
        )

        item_meta_style = ParagraphStyle(
            "ItemMeta",
            parent=styles["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=8,
            leading=11,
            textColor=palette["secondary"],
        )

        empty_style = ParagraphStyle(
            "EmptyText",
            parent=styles["Italic"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            leading=13,
            textColor=palette["empty_text"],
        )

        story = []

        # Header Title
        meta = note_data.get("meta", {})
        story.append(Paragraph("SHIFT HANDOVER REPORT", title_style))
        story.append(Spacer(1, 4))
        
        shift_info_text = (
            f"<b>Shift Window:</b> {meta.get('shift_start_local', '')} to {meta.get('shift_end_local', '')} "
            f"({meta.get('timezone', 'UTC')}) &nbsp;|&nbsp; "
            f"<b>UTC Window:</b> {meta.get('shift_start_utc', '')} → {meta.get('shift_end_utc', '')}<br/>"
            f"<b>Generated At:</b> {note_data.get('generated_at_utc', '')} &nbsp;|&nbsp; "
            f"<b>Report ID:</b> {note_id} &nbsp;|&nbsp; "
            f"<b>Total Grounded Items:</b> {note_data.get('total_items', 0)}"
        )
        story.append(Paragraph(shift_info_text, subtitle_style))
        story.append(Spacer(1, 10))
        story.append(HRFlowable(width="100%", thickness=1, color=palette["border"], spaceBefore=0, spaceAfter=8))

        # Executive Summary Box
        summary_content = note_data.get("summary", "No summary available.")
        summary_table = Table(
            [[Paragraph(f"<b>Executive Overview:</b> {summary_content}", summary_box_style)]],
            colWidths=[540],
        )
        summary_table.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), palette["bg_light"]),
                ("BORDER", (0, 0), (-1, -1), 1, palette["border"]),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
            ])
        )
        story.append(summary_table)
        story.append(Spacer(1, 14))

        # Color mapping for section headers
        section_colors = {
            "Completed": palette["completed_tag"],
            "In Progress": palette["inprogress_tag"],
            "Blockers/Escalations": palette["blocker_tag"],
            "Watch-List": palette["watchlist_tag"],
        }

        # 4 Sections
        sections_data = note_data.get("sections", {})
        for sec_name in SECTIONS:
            items = sections_data.get(sec_name, [])
            header_color = section_colors.get(sec_name, palette["accent"])
            
            # Section Header Bar
            header_p = Paragraph(f"<b>{sec_name.upper()}</b> ({len(items)} items)", section_heading_style)
            header_table = Table([[header_p]], colWidths=[540])
            header_table.setStyle(
                TableStyle([
                    ("BACKGROUND", (0, 0), (-1, -1), header_color),
                    ("TOPPADDING", (0, 0), (-1, -1), 4),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ])
            )
            
            section_flowables = [header_table, Spacer(1, 4)]
            
            if not items:
                # "Nothing to report" explicitly
                empty_p = Paragraph("• <i>Nothing to report</i>", empty_style)
                empty_table = Table([[empty_p]], colWidths=[540])
                empty_table.setStyle(
                    TableStyle([
                        ("BACKGROUND", (0, 0), (-1, -1), palette["bg_light"]),
                        ("LEFTPADDING", (0, 0), (-1, -1), 12),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                        ("TOPPADDING", (0, 0), (-1, -1), 6),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                        ("LINEBELOW", (0, 0), (-1, -1), 0.5, palette["border"]),
                    ])
                )
                section_flowables.append(empty_table)
            else:
                table_rows = []
                for it in items:
                    # Item line + source metadata line
                    item_p = Paragraph(f"• {it['item']}", item_text_style)
                    meta_details = f"Source: <b>{it['source']}</b> &nbsp;|&nbsp; Timestamp: {it.get('timestamp', 'N/A')} (UTC: {it.get('timestamp_utc', 'N/A')})"
                    meta_p = Paragraph(meta_details, item_meta_style)
                    
                    cell_content = [item_p, Spacer(1, 2), meta_p]
                    table_rows.append([cell_content])

                items_table = Table(table_rows, colWidths=[540])
                items_table.setStyle(
                    TableStyle([
                        ("BACKGROUND", (0, 0), (-1, -1), colors.white),
                        ("LEFTPADDING", (0, 0), (-1, -1), 8),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                        ("LINEBELOW", (0, 0), (-1, -1), 0.5, palette["border"]),
                    ])
                )
                section_flowables.append(items_table)

            section_flowables.append(Spacer(1, 10))
            story.append(KeepTogether(section_flowables))

        # Footer note
        footer_p = Paragraph(
            "<i>This document was automatically generated and grounded against shift telemetry events. All items are traceable.</i>",
            item_meta_style
        )
        story.append(Spacer(1, 10))
        story.append(footer_p)

        # Build PDF
        doc.build(story)

        # Confirm non-zero file created
        if not output_path.exists() or output_path.stat().st_size == 0:
            raise RuntimeError(f"PDF creation failed: output file {output_path} is missing or empty")

        logger.info(f"PDF successfully exported to {output_path} ({output_path.stat().st_size} bytes)")
        return output_path

    except Exception as e:
        logger.error(f"FATAL: PDF export failed: {e}", exc_info=True)
        # Fail loudly per requirement #10
        raise RuntimeError(f"Document export failed: {e}") from e
