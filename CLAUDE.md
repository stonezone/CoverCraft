# CoverCraft — Session Briefing for Claude

## What this project is
iOS app (Swift 6, iOS 18, macOS 15) that uses LiDAR + ARKit to scan objects (primarily cars), segments the mesh into panels, flattens them into 2D sewing patterns via LSCM, and exports the result for custom-fitted covers.

## Where to work
- **Open `CoverCraft.xcworkspace` in Xcode** (not the `.xcodeproj`).
- **Nearly all changes land in `CoverCraftPackage/Sources/`**. The `CoverCraft/` app target is a thin shell.
- Xcode buildable folders: files on disk auto-appear in the project — no manual target membership.

## Module layout (strict dependency order)
```
CoverCraftDTO  ←  CoverCraftCore  ←  {AR, Segmentation, Flattening, Export, UI}  ←  CoverCraftFeature
                                                                                          (app shell consumes this)
```
DTOs are immutable `struct`s (`Sendable, Codable, Equatable`, `let`-only). Services are protocols (`<Domain>Service`) with `Default<Name>Service` implementations wired through `DefaultDependencyContainer`.

## Claude OS integration (this project is wired up)
Claude OS runs at `http://localhost:8051`. The `code-forge` MCP is globally registered in `~/.claude.json`, so tools prefixed `mcp__code-forge__*` are available in every session from this directory.

Project ID: **1**. Knowledge bases populated and accessible:

| KB | Purpose | Use when… |
|---|---|---|
| `covercraft-project_profile` | ARCHITECTURE / CODING_STANDARDS / DEVELOPMENT_PRACTICES (15 chunks) | you need design intent, conventions, DI patterns, test targets |
| `covercraft-knowledge_docs` | `docs/*.md` (design analysis, impl plan) | you need recent design decisions |
| `covercraft-project_memories` | decisions / patterns saved across sessions | you suspect prior work touched this area |
| `covercraft-project_index` | semantic code index | *(may be empty — see "Indexing status" below)* |
| `covercraft-code_structure` | tree-sitter structural index | **NOT POPULATED — upstream Claude OS can't parse Swift** (see Known Limitations) |

### Quick access patterns
- Broad recall across everything covercraft: `mcp__code-forge__search_all_knowledge_bases` with `kb_filter: "covercraft-"`
- Specific KB: `mcp__code-forge__search_knowledge_base` with the `kb_name` from the table above
- Save a decision / pattern for future sessions: `mcp__code-forge__upload_document` into `covercraft-project_memories`

### If Claude OS is unreachable
Run `mcp__code-forge__health_check` first. If it reports unhealthy or connection refused:
```
~/claude-os/start.sh            # starts the MCP server on :8051
```
Swift grammar for the structural indexer is missing upstream (`tree_sitter_swift` not bundled in `tree-sitter-languages` 1.10.2) — don't retry structural indexing until that's resolved upstream.

### Indexing status (as of 2026-04-19)
- ✅ `project_profile`: 3 docs ingested
- ✅ `knowledge_docs`: current `docs/` contents ingested
- ✅ `project_memories`: preserved from prior sessions
- ⏸  `project_index` (semantic code): not yet run — kick off with `mcp__code-forge__index_semantic` on `{kb_name: "covercraft-project_index", project_path: "/Users/zackjordan/code/CoverCraft", selective: true}` (~20 min) when needed
- ❌ `code_structure`: blocked on upstream Swift grammar

## Coding conventions (short version — full details in `.claude/CODING_STANDARDS.md`)
- File header: `// Version: X.Y.Z` + module descriptor
- `// MARK: -` section dividers
- Cross-module types must be `public` with an explicit `public init`
- Gate AR/mesh APIs with `@available(iOS 18.0, macOS 15.0, *)`
- Services: protocol `<Domain>Service` (Sendable) + `Default<Name>Service`
- Errors: `enum : Error, LocalizedError` with `errorDescription`
- Logging: `swift-log` with reverse-DNS labels (`com.covercraft.*`)
- Concurrency: `async throws` across service boundaries; `@unchecked Sendable` only with a lock

## Build / test
- Prefer `mcp__XcodeBuildMCP__*` tools over raw `xcodebuild`
- Always call `session_show_defaults` before the first build in a session
- Test plan: `CoverCraft.xctestplan` coordinates 16 test targets (unit, contract, integration, performance, memory, concurrency, regression, UI)
- Test frameworks: Swift Testing (`@Test`), XCUITest, `pointfreeco/swift-snapshot-testing` 1.19.2
- Dependencies pinned `.exact(...)` in `Package.swift`

## Source-of-truth docs (all live in `.claude/`)
- `.claude/ARCHITECTURE.md` — module graph, data flow, design principles
- `.claude/CODING_STANDARDS.md` — file headers, naming, DTO/service/error patterns
- `.claude/DEVELOPMENT_PRACTICES.md` — testing strategy, build config, git/PR flow

## What NOT to do
- Don't open `.xcodeproj` directly — use `.xcworkspace`
- Don't add backwards-compat shims for types that were never shipped
- Don't mutate DTOs in place — return a new DTO with a fresh `id`
- Don't hand-edit `project.pbxproj` for settings that belong in `Config/*.xcconfig`
- Don't retry the structural indexer (`index-structural`) until Swift grammar issue is fixed upstream
