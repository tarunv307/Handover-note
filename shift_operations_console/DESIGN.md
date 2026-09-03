---
name: Shift Operations Console
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#45464d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#006398'
  on-secondary: '#ffffff'
  secondary-container: '#5bb8fe'
  on-secondary-container: '#00476e'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#002114'
  on-tertiary-container: '#069669'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#cce5ff'
  secondary-fixed-dim: '#93ccff'
  on-secondary-fixed: '#001d31'
  on-secondary-fixed-variant: '#004b73'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: geist
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  title-md:
    fontFamily: geist
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: geist
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0em
  body-lg:
    fontFamily: geist
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  label-mono:
    fontFamily: jetbrainsMono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.01em
  label-mono-xs:
    fontFamily: jetbrainsMono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: geist
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.06em
  headline-xl-mobile:
    fontFamily: geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  space-xxs: 0.125rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-base: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 3rem
  gutter-desktop: 1.25rem
  gutter-mobile: 0.75rem
  sidebar-width: 16rem
  max-content-width: 96rem
---

## Brand & Style

The design system establishes a high-precision, mission-critical operational workspace tailored for cross-shift engineering leads, plant superintendents, site reliability directors, and enterprise operations controllers. The aesthetic rejects decorative noise in favor of functional density, surgical structure, and immediate cognitive clarity. 

The core tone is disciplined, authoritative, and frictionless. It balances the austere utilitarianism of high-throughput developer consoles with the refined hierarchy of modern data workspaces. The visual rhythm relies on crisp slate architecture, deliberate semantic signals, micro-density, and persistent spatial predictability. Ambient uncertainty is eliminated: incoming teams must parse 12 hours of operational delta, blocker states, critical checklists, and audit trails within 90 seconds.

Key aesthetic principles:
- **Zero Ambiguity:** Strict structural containers, explicit line dividers, and high-legibility typographic scannability.
- **Controlled Information Density:** Dense without clutter; generous padding inside individual data cells paired with compact structural bounds.
- **Deterministic Color Distribution:** Neutral slate dominants spanning 90% of surfaces, with semantic hues strictly reserved for state changes, action requirements, and operational alerts.

## Colors

The palette employs an architectural slate foundation balanced with hyper-disciplined semantic accents. Dominant canvas backgrounds sit on neutral crisp slates to eliminate glare across long workstation shifts while maintaining razor-sharp contrast ratios exceeding WCAG AAA standards for critical telemetry text.

### Base Tones & Surfaces
- **Canvas (`#f8fafc`):** Primary low-strain app ground.
- **Surface (`#ffffff`):** Pure white for elevated data cards, handover logs, and editable sections.
- **Surface Muted (`#f1f5f9`):** Sub-tables, code blocks, meta trays, and disabled form tracks.
- **Border Default (`#e2e8f0`):** Subtle structural dividing lines between cards and columns.
- **Border Strong (`#cbd5e1`):** Interactive boundaries, active inputs, and grid headers.

### Core Brand & Ink
- **Primary Ink / Accent (`#0f172a`):** Deep slate-900 for primary typography, dominant call-to-actions, and navigation anchors.
- **Secondary Accent (`#0284c7`):** Precision sky-600 utilized for active links, focused states, and current shift selection tags.

### Semantic Telemetry Signals
Semantic colors are strictly functional indicators and must never be used as general decorative fills.
- **Success / Completed (`#059669` / bg: `#ecfdf5` / border: `#a7f3d0`):** Signed-off handovers, resolved incidents, and normalized telemetry.
- **Warning / In-Progress (`#d97706` / bg: `#fffbeb` / border: `#fde68a`):** Open work orders, ongoing safety isolations, and unacknowledged shift items.
- **Critical / Blocker / Escalation (`#e11d48` / bg: `#fff1f2` / border: `#fecdd3`):** Unresolved P1/P0 anomalies, active safety permits, and handover blockages.
- **Watch-list / Monitoring (`#4f46e5` / bg: `#eef2ff` / border: `#c7d2fe`):** Systems under observation, temporary bypasses, and deferred maintenance flags.
- **Neutral Audit / Timestamps (`#475569` / bg: `#f8fafc` / border: `#e2e8f0`):** Shift operator metadata, revision hashes, and static machine tags.

## Typography

Typography delivers dense, structured telemetry with exceptional glyph distinction. **Geist** powers universal layout headlines, interactive controls, and editorial handover notes, providing a neutral geometric structure that avoids distracting quirks. 

**JetBrains Mono** is embedded across all technical data layers: shift timestamps, equipment asset identifiers, log hashes, operator badges, and sensor delta measurements. This prevents optical misreadings between similar numerals and letters (such as `0` vs `O`, `1` vs `l`) during rapid handoff briefings.

Typographic Rules:
- All table column titles and field section eyebrows leverage `label-caps` in uppercase with subtle letter-spacing for swift eye anchors.
- Handover summary narratives rely strictly on `body-md` for maximum content efficiency without sacrificing rapid scanning.
- Numerical measurements, status codes, and timestamps must always use `label-mono` or `label-mono-xs`.

## Layout & Spacing

The layout model is anchored on an operational multi-column responsive dashboard structure. Shift handovers require contextual juxtaposition: unresolved tasks on the left, shift metrics in the center, and chronological log journals on the right.

### Layout Grid & Alignment
- **Desktop (>= 1280px):** Fixed navigation rail (`16rem`), followed by an asymmetric 12-column grid. Main summary and log canvas occupies 8 columns, while the metadata panel, sign-off card, and blocker tracker occupy 4 columns. Gutter is fixed at `1.25rem` (`space-lg`).
- **Tablet (768px - 1279px):** Collapsed navigation bar to icon rail (`4rem`), shifting the grid into a single-column layout with stacked module cards. Gutter contracts to `1rem` (`space-base`).
- **Mobile (< 768px):** Single vertical stream with bottom-anchored action bar for handover review and signing. Outer page margins contract to `0.75rem` (`space-md`).

### Spacing Density Philosophy
Vertical and horizontal rhythm adheres strictly to an 8pt base grid (with 4pt sub-steps for dense micro-components like badges, input chips, and table rows). Interior padding inside telemetry cards is clamped to `space-base` (`1rem`) to maximize visible information above the digital fold on field laptops and operational tablets.

## Elevation & Depth

Visual hierarchy is communicated through structural planar layering and low-contrast perimeter borders rather than heavy drop shadows. The design avoids excessive z-index float to maintain a stable, instrument-like feel suitable for industrial workstations.

Depth Levels:
- **Base Ground (Level 0):** `#f8fafc`. Recessed background for overall interface canvas.
- **Card Tier (Level 1):** Solid `#ffffff` background bounded by a 1px crisp border in `#e2e8f0`. Zero ambient drop shadow.
- **Interactive Hover & Drag (Level 2):** Applied exclusively when hovering over list rows, reordering handover items, or expanding collapsible logs. Surface remains `#ffffff`, accompanied by a sharp hairline shadow: `0 1px 3px 0 rgba(15, 23, 42, 0.06), 0 1px 2px -1px rgba(15, 23, 42, 0.04)`.
- **Flyouts & Modals (Level 3):** Handover audit history, operator switcher, and sign-off dialogs utilize `#ffffff` with a structural outline (`#cbd5e1`) and a concentrated dark slate drop shadow: `0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.04)`. Backdrop employs an ultra-subtle slate tint (`rgba(15, 23, 42, 0.35)`).
- **Divider Hairlines:** All horizontal card dividers, panel headers, and table separations must use a razor-sharp 1px border (`#e2e8f0`).

## Shapes

The geometric framework favors controlled, compact softness (`roundedness: 1`). Radii are kept small and measured to prevent wasted peripheral space and preserve an engineered, utilitarian appearance.

- **Primary Cards and Panels:** `0.25rem` (4px) or `0.375rem` (6px) maximum.
- **Buttons, Form Inputs, and Selectors:** `0.25rem` (4px) to retain structural alignment with tabular grids.
- **Traceability Badges & Status Chips:** `0.25rem` (4px) border-radius with a 1px border. Oval/pill shapes are expressly forbidden for statuses to prevent them from looking like consumer consumer-social tags.
- **Inner Checkboxes & Radio Cells:** `0.25rem` (4px) for checkboxes; full circle for radio buttons.

## Components

### Buttons
- **Primary Action (Sign Shift, Submit Handover):** Background `#0f172a`, text `#ffffff`, hover `#1e293b`, active `#334155`. Height: 36px (compact 32px in data tables). Monospaced action indicators where relevant.
- **Secondary (Add Log, Export PDF):** White surface `#ffffff`, 1px border `#cbd5e1`, text `#0f172a`. Hover: `#f8fafc` with border `#94a3b8`.
- **Destructive / Reject Handover:** Background `#fff1f2`, text `#e11d48`, border 1px solid `#fecdd3`. Hover: `#ffe4e6`.

### Badges & Traceability Tags
- **Structure:** Height 22px, padding `2px 6px`, font `label-mono-xs`. 1px solid border matching semantic intent.
- **Variants:**
  - *Completed:* `#ecfdf5` background, `#059669` text, `#a7f3d0` border.
  - *In-Progress:* `#fffbeb` background, `#d97706` text, `#fde68a` border.
  - *Blocker:* `#fff1f2` background, `#e11d48` text, `#fecdd3` border. Left-edge 3px solid accent line for high-priority visual tripping.
  - *Watch-list:* `#eef2ff` background, `#4f46e5` text, `#c7d2fe` border.
  - *Audit Timestamp:* `#f1f5f9` background, `#475569` text, `#cbd5e1` border.

### Input Fields & Structured Form Controls
- **Text Inputs & Textareas:** Background `#ffffff`, border 1px `#cbd5e1`, text `#0f172a`, placeholder `#94a3b8`. Focus state applies a 1px border in `#0284c7` accompanied by a 1px ring in `rgba(2, 132, 199, 0.2)`. No aggressive glows.
- **Shift Metadata Pickers:** Compact inline inputs with fixed label caps aligned left to reduce vertical height consumption.

### Handover Cards & Section Containers
- Top-level card wrappers feature a 1px `#e2e8f0` border, `#ffffff` surface, and explicit header bar separated by a 1px border line.
- Header bars must include: category icon, section label (`label-caps`), count counter in `label-mono`, and direct contextual action (e.g., "+ Add Item").

### Checklist Rows & Incident Logs
- Checklist rows feature a dense vertical height (36px default), alternating muted row hover `#f8fafc`, integrated status badge, asset ID indicator (`JetBrains Mono`), and assign-shift avatar stamp.
- Completed items strike through the label text in `#94a3b8` while maintaining the asset ID at full legibility.

### Shift Transition Status Bar
- Fixed bottom or persistent top utility bar summarizing outgoing vs incoming shift lead profiles, system state checklist progress (e.g., "14/14 Completed"), active blockers warning count (`label-mono`), and the dual-signature verification trigger.