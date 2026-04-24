# CoverCraft — Completion Plan (Implementation Roadmap)

This document is the detailed, implementation-ready plan to take CoverCraft from the current “working prototype” to a complete, end-to-end app that reliably produces **sewing-ready, bottom-open cover patterns** for household objects (tools → appliances → car/tarp).

## Definition of “Complete” (v1)

**A user can**:
1. Choose a workflow (scan OR enter measurements).
2. Define cover intent: **bottom-open**, gravity direction, **closed/open top**, **water protection** options, and ease/hem/seam choices.
3. Generate a pattern with adjustable segmentation (coarse → high-res quads/triangles where relevant).
4. Export as PDF (tiled), SVG, and PNG with:
   - Page tiling + registration marks
   - Panel labels + seam pairing info + notches
   - A prominent calibration/scale bar on every page
5. Print or project the pattern and **calibrate scale** quickly and correctly.

**Exit criteria**:
- “Measurement-first” slipcover workflow produces usable patterns without scanning.
- Exports consistently measure true-scale in real-world units.
- App provides sufficient annotations to cut, assemble, and sew without guessing.
- Core flows are covered by automated tests and do not regress.

---

## Phase 0 — Scope Lock + Product Contract (1–2 days)

### 0.1 Make a hard scope decision (required)
- [ ] Decide v1 primary workflow:
  - **Option A (recommended for v1):** “Measured Slipcover” (manual W/H/D + optional tapers/profiles).
  - **Option B:** “Fitted From LiDAR Mesh” (keep as experimental; not required for v1).
- [ ] Define supported object classes for v1 (examples):
  - Rectangular prism (most appliances)
  - Tapered prism (some tools/appliances)
  - “Car/tarp” as large-scale projection use case (measurement-first)

### 0.2 Define the output contract (what export must contain)
- [ ] Minimum required metadata per panel:
  - Panel ID, cut quantity, grain/orientation arrow, seam allowance spec, edge finishing spec.
- [ ] Minimum required assembly metadata:
  - Seam pairings (edge A ↔ edge B), notches, and a simple assembly order.
- [ ] Calibration requirements:
  - Always include a known length bar (e.g., 100mm and 500mm) and a text instruction.

Deliverable:
- A short spec (could live inside this file) declaring v1 scope + export contract.

---

## Phase 1 — Measurement-First Slipcover Workflow (Core v1) (3–7 days)

### 1.1 Add “Manual Dimensions” pattern source
Target modules:
- UI: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`, `AppState.swift`
- Core: `CoverCraftPackage/Sources/CoverCraftCore/SlipcoverPatternGenerator.swift`
- DTO: `CoverCraftPackage/Sources/CoverCraftDTO/SlipcoverPatternOptions.swift`

Tasks:
- [ ] Add a new input mode: `PatternInputMode = scan | manual`.
- [ ] Manual inputs:
  - Width (W), Depth (D), Height (H) in mm (or user-selectable units with conversion).
  - Gravity axis / bottom opening (default: bottom open).
  - Ease (mm) and per-axis ease overrides (optional).
  - Top style: closed / open.
  - Water protection mode: none / rainproof / waterproof (initially maps to seam/hem defaults).
- [ ] Validate manual inputs (non-zero, sane min/max, warnings for huge sizes).

Acceptance tests:
- [ ] Manual entry can generate a basic cover without any mesh.

### 1.2 Upgrade slipcover geometry from “bbox only” to v1-usable shapes
Target modules:
- Core generator: `SlipcoverPatternGenerator.swift`

Tasks (in order):
- [ ] Rectangular prism panels (already effectively present via bbox) with bottom-open hem.
- [ ] Optional top closure (top panel on/off).
- [ ] Add **taper support**:
  - Separate top W/D from bottom W/D (or single “taper %” control).
  - Generator produces trapezoid side panels.
- [ ] Add “profile” mode (simple):
  - User provides 2–4 cross-section widths at heights (e.g., base/mid/top).
  - Linear interpolate between sections; generate panels as piecewise trapezoids.

Acceptance tests:
- [ ] A tapered cover produces correct panel shapes and edge pairings.

---

## Phase 2 — Sewing-Ready Pattern Metadata (5–10 days)

### 2.1 Extend DTOs to represent sewing intent (not just geometry)
Target modules:
- DTO: `CoverCraftPackage/Sources/CoverCraftDTO/*`

Add/extend DTOs:
- [ ] `PanelMetadataDTO`:
  - `panelName`, `quantity`, `material`, `notes`
- [ ] `EdgeRoleDTO` (semantic edge types beyond cut/seam):
  - hem/bottom opening, top seam, side seam, closure seam, reinforcement edge
- [ ] `SeamPairDTO`:
  - `panelA/edgeA ↔ panelB/edgeB`, notch count/positions
- [ ] `NotchDTO`:
  - normalized position along an edge, notch style (single/double/T)
- [ ] `AssemblyPlanDTO` (v1 simple):
  - ordered steps or groups (e.g., “Join side seams”, “Attach top”, “Finish hem”)

Acceptance tests:
- [ ] Serialization/deserialization of new DTOs (Codable).

### 2.2 Generate seam pairings + notches in the generator
Target modules:
- Core: `SlipcoverPatternGenerator.swift`

Tasks:
- [ ] Explicitly generate panel adjacency graph (which edges stitch together).
- [ ] Add default notches:
  - 1 notch at mid-edge for long seams
  - 2 notches for asymmetric seams (taper/profile)
- [ ] Add bottom hem metadata (bottom-open finishing).

Acceptance tests:
- [ ] A generated pattern includes non-empty seam pairings and notch data.

---

## Phase 3 — Export “Cuttable + Projectable” (5–10 days)

Target module:
- Export: `CoverCraftPackage/Sources/CoverCraftExport/DefaultPatternExportService.swift`

### 3.1 Page tiling UX + registration marks
Tasks:
- [ ] Add “tiling preview” in UI (even a simple page count + bounding box preview to start).
- [ ] Add registration marks per page:
  - corner targets + crosshair
  - page row/col labels (A1, A2… or (r,c))
- [ ] Include panel labels on pattern geometry (not just header text).

Verify:
- [ ] Tiled PDF can be taped together reliably using registration marks.

### 3.2 Calibration on every page + projector guidance
Tasks:
- [ ] Print/projection calibration bar on **every** page:
  - 100mm bar + 500mm bar (or configurable)
- [ ] Add a “Calibration” export note (e.g., “Measure bar; adjust print scaling until exact”).
- [ ] Add a dedicated “Projector Mode” export preset:
  - bigger calibration bar
  - high-contrast line styling
  - optional single-page huge PDF (if feasible) OR keep tiled but provide clear instructions

Verify:
- [ ] A user can calibrate projector scaling with <2 minutes of trial.

### 3.3 Sewing annotations in export (v1 minimum)
Tasks:
- [ ] Render:
  - Panel name + quantity
  - Notches
  - Seam allowance indicator
  - Hem fold line (optional)
- [ ] Optional layers (PDF/SVG) if feasible:
  - cut line, seam line, fold/hem, notches, labels

Verify:
- [ ] Printed pattern communicates assembly without external notes.

---

## Phase 4 — “Fitted From Scan” Hardening (Optional v1 / v2) (2–6 weeks)

If kept for v1, treat as “Experimental” clearly in UI.

Targets:
- Segmentation: `CoverCraftPackage/Sources/CoverCraftSegmentation/*`
- Flattening: `CoverCraftPackage/Sources/CoverCraftFlattening/*`
- UI: `CoverCraftPackage/Sources/CoverCraftUI/*`, `CoverCraftFeature/*`

Tasks:
- [ ] Mesh preprocessing:
  - clean degenerate triangles, unify winding, remove isolated components
  - find gravity axis / “bottom plane” estimate
- [ ] Robust calibration requirements and failure modes:
  - guide user to pick two far-apart points
  - reject calibrations without explicit real-world distance (already enforced in DTO)
- [ ] Improve flattening stability:
  - detect near-singular panels early and fallback to simpler panelization
- [ ] Panel packing (optimizeForCutting) improvements:
  - deterministic layout, avoid overlaps, handle huge panels via splitting

Acceptance tests:
- [ ] A curated set of fixture meshes produce a non-empty pattern without crashes.

---

## Phase 5 — App Polish + Guardrails (3–10 days)

### 5.1 Onboarding + guided flow
Tasks:
- [ ] Replace “one screen does everything” with a stepper:
  1) Choose input (manual/scan)
  2) Choose cover options
  3) Generate preview
  4) Export
- [ ] Add clear copy for:
  - bottom-open meaning
  - ease guidance
  - waterproof vs rainproof defaults

### 5.2 Error handling + performance guardrails
Tasks:
- [ ] Timeouts/cancellation are respected for segmentation/flattening (partially present; ensure consistent).
- [ ] Explicit user-facing errors (not logs) when:
  - mesh missing
  - calibration incomplete
  - export fails
- [ ] Add “max page count” warning and “split pattern” suggestions for huge objects.

---

## Phase 6 — Tests + Regression Coverage (ongoing, but gate for release)

Targets:
- `CoverCraftPackage/Tests/*`

Add/extend tests:
- [ ] Generator unit tests:
  - rectangular prism, tapered prism, profile mode
  - verifies seam pairings + notch counts
- [ ] Export tests:
  - PDF/SVG includes calibration bars
  - PDF tiling produces expected page counts for known bounds
- [ ] Snapshot tests (where stable) for exported SVG strings and PDF metadata.
- [ ] “Golden” manual dimension patterns for common sizes (toolbox, chair, appliance).

Release gate:
- [ ] Tests pass in CI and locally on macOS.

---

## Recommended Milestones

### Milestone A (1 week): “Manual Slipcover MVP”
- Manual W/H/D workflow
- Bottom-open + optional top
- PDF tiling + calibration bar
- Minimal labels

### Milestone B (2–3 weeks): “Sewing-Ready”
- Seam pairings + notches
- Panel metadata (qty, names)
- Export annotations + registration marks

### Milestone C (4–6 weeks): “Advanced Shapes + Projection”
- Taper + profile mode
- Projector preset + guided calibration flow

---

## Out of Scope for v1 (explicit)
- Full fitted patterns from arbitrary LiDAR meshes with guaranteed sewable results.
- Complex closures (zippers with placement planning, vents, gussets) beyond simple presets.
- Fabric grain optimization beyond basic orientation hints.
