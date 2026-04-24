# Covercraft Review TODO

**Generated**: 2025-12-13
**Updated**: 2025-12-13
**Review Source**: `Covercraft_review_121325.txt`
**Analysis Status**: All findings verified against current codebase
**Implementation Status**: 8 items completed

---

## Critical (Must Fix) ✅ ALL COMPLETE

- [x] **Replace fatalError with thrown error in Edge.other()** — Changed `fatalError` to return `Int?` and updated call site with guard. Prevents production crashes.

- [x] **Add mesh anchor pruning/downsampling during AR scanning** — Added FIFO eviction with `maxAnchorCount = 150` limit. Prevents unbounded memory growth during long scans.

- [x] **Move SlipcoverPatternGenerator.generate() off the main actor** — Wrapped synchronous generation in `Task.detached` with captured values. UI remains responsive during pattern generation.

---

## High Priority (3/4 Complete)

- [x] **Remove location permission requirement** — Removed from `Config/Shared.xcconfig`. Verified ARWorldTrackingConfiguration uses `.gravity` not `.gravityAndHeading`, so location is not needed.

- [x] **Resolve DXF export path inconsistency** — PatternExporter now throws `ExportError.unsupportedFormat` for DXF. Removed dead stub code. Added documentation warning about unsupported format.

- [x] **Document cutting optimization algorithm** — Added comprehensive docstring to `optimizeForCutting()` explaining it's a basic grid layout, not bin packing. Lists alternatives (guillotine, shelf algorithms, libnest2d).

- [ ] **Add CI workflow for build + tests** — Repo lacks `.github/workflows/` — Create a GitHub Actions workflow that: (1) builds the Xcode project, (2) runs SPM package tests, (3) runs UI tests on simulator. Prevents regressions and validates PRs.

---

## Medium Priority (1/4 Complete)

- [x] **Fix README documentation references** — Removed references to non-existent files (CLAUDE.md, .cursor/*.mdc, CHANGELOG.md, etc.). Simplified documentation section.

- [ ] **Improve user-facing error messages with error codes** — `CoverCraftPackage/Sources/CoverCraftUI/Views/ExportView.swift` and other UI files — Replace generic `error.localizedDescription` with structured error codes and actionable guidance (e.g., "CCV-101: Camera permission denied. Please enable in Settings > Privacy > Camera").

- [ ] **Parallelize per-panel flattening with TaskGroup** — `CoverCraftPackage/Sources/CoverCraftFlattening/DefaultPatternFlatteningService.swift:30-86` — The sequential for-loop could leverage `withThrowingTaskGroup` to flatten panels concurrently, improving throughput on multi-panel meshes.

- [ ] **Optimize panel overlap validation (currently O(n^2))** — `CoverCraftPackage/Sources/CoverCraftFlattening/PatternValidator.swift:504-530` — For large panel counts, consider spatial indexing (R-tree or grid) to reduce comparison count. Low priority unless panel counts regularly exceed ~50.

---

## Low Priority / Deferred (1/4 Complete)

- [x] **Fix indentation inconsistencies in ServiceContainer** — Fixed `resolve()` method indentation inside `lock.withLock {}` closure.

- [ ] **Replace placeholder UI tests with smoke tests** — `CoverCraftUITests/CoverCraftUITests.swift:17-25` — Current test is `XCTAssertTrue(true)`. Add at minimum: (1) app launch verification, (2) basic navigation checks, (3) export UI state validation.

- [ ] **Triage disabled test files** — `CoverCraftPackage/Tests/**/*.swift.disabled` (19 files) — Either re-enable and fix, or delete to avoid false confidence. Key disabled files include:
  - `DefaultARScanningServiceTests.swift.disabled`
  - `FlatteningServiceTests.swift.disabled`
  - `ExportServiceTests.swift.disabled`
  - `EndToEndWorkflowTests.swift.disabled`

- [ ] **Implement or remove empty contract tests** — `CoverCraftPackage/Tests/ContractTests/ContractTestsPlaceholder.swift` — File contains only `import Foundation`. Either add actual contract tests for DTO serialization/versioning, or remove the placeholder.

---

## Review Corrections (FYI)

- **Location permission claim (Finding #9)**: Review stated "I did not find CoreLocation usage" and marked this as over-permissioning. **PARTIAL** — ARKit's `ARWorldTrackingConfiguration` can use location for world alignment (`worldAlignment: .gravityAndHeading`). The permission may be legitimate, but should be verified against actual usage.

- **UI thread blocking (Finding #3)**: Review claimed slipcover generation "can run on the main actor." **PARTIAL** — While `Task {}` from a `@MainActor` context does inherit the actor until first suspension, the code does eventually await `flattener.optimizeForCutting()`. The synchronous `generate()` portion is the concern, not the entire flow.

- **MeshDTO.isValid (Finding #1, Section 2)**: Review referenced `MeshDTO.swift:39-44` for validation. **CORRECT** — Validation exists and is called appropriately.

- **Thread-safety (Finding #4, Section 2)**: Review noted `DefaultDependencyContainer` uses `@unchecked Sendable` with locking. **CORRECT** — Implementation uses `NSRecursiveLock` correctly with `lock.withLock {}`.

---

## Verification Checklist

| # | Finding | Verdict | Evidence |
|---|---------|---------|----------|
| 1 | fatalError in Edge.other() | CORRECT | Line 782: `fatalError("Vertex \(vertex) is not part of edge...")` |
| 2 | DXF export inconsistency | CORRECT | Two competing implementations confirmed |
| 3 | UI-thread blocking risk | PARTIAL | Synchronous generate() exists but async optimization follows |
| 4 | Grid layout placeholder | CORRECT | Comment at line 91: "Placeholder optimization" |
| 5 | AR memory growth | CORRECT | Anchors accumulated without pruning |
| 6 | O(n^2) overlap check | CORRECT | Nested loops in validatePanelOverlaps() |
| 7 | Sequential flattening | CORRECT | for-loop without TaskGroup |
| 8 | Location over-permissioning | PARTIAL | May be needed for ARKit heading alignment |
| 9 | ServiceContainer formatting | CORRECT | Inconsistent indentation in resolve() |
| 10 | README mismatches | CORRECT | Referenced files do not exist |
| 11 | UI tests placeholder | CORRECT | Test body is XCTAssertTrue(true) |
| 12 | Contract tests empty | CORRECT | Only `import Foundation` |
| 13 | Disabled test files | CORRECT | 19 .swift.disabled files found |
| 14 | Safe file export | CORRECT | Uses temporaryDirectory with atomic writes |

---

**Next Steps**: Prioritize Critical items first. High Priority items affect UX and maintainability. Medium/Low can be addressed during refactoring sprints.
