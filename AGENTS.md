# Repository Guidelines

## Project Structure & Module Organization
Open `CoverCraft.xcworkspace`, not `CoverCraft.xcodeproj`. The app target in `CoverCraft/` is a thin shell with `CoverCraftApp.swift`, assets, and the Xcode test plan. Most code lives in `CoverCraftPackage/`.

`CoverCraftPackage/Sources/` is split by module: `CoverCraftDTO`, `CoverCraftCore`, `CoverCraftAR`, `CoverCraftSegmentation`, `CoverCraftFlattening`, `CoverCraftExport`, `CoverCraftUI`, and `CoverCraftFeature`. Keep dependency flow one-way: DTO -> Core -> domain modules/UI -> Feature. Tests live in `CoverCraftPackage/Tests/<TargetName>/`; UI automation lives in `CoverCraftUITests/`. Build settings are in `Config/*.xcconfig`.

## Build, Test, and Development Commands
- `open CoverCraft.xcworkspace`: open the full workspace in Xcode.
- `swift build --package-path CoverCraftPackage`: build the Swift package quickly.
- `swift test --package-path CoverCraftPackage`: run package test targets without the app shell.
- `xcodebuild -workspace CoverCraft.xcworkspace -scheme CoverCraft -testPlan CoverCraft -destination 'platform=iOS Simulator,name=iPhone 17' test`: run the full app test plan.
- `xcodebuild -list -workspace CoverCraft.xcworkspace`: list available schemes and shared test targets.

## Coding Style & Naming Conventions
Use Swift 6 style with 4-space indentation. Follow the existing file layout: `// Version: x.y.z` header on source files and `// MARK: -` section dividers. Match filenames to the primary type.

Use established names:
- Protocols: `<Domain>Service`
- Implementations: `Default<Name>Service`
- DTOs: `<Domain>DTO`
- Views: `<Name>View` or `<Name>ViewController`
- Tests: `<Subject>Tests.swift`

Public cross-module APIs must be explicitly `public` with a `public init`. Prefer immutable DTO structs, `async throws` service boundaries, `LocalizedError` for error enums, and `swift-log` over `print()`.

## Testing Guidelines
Package tests use Swift Testing (`@Suite`, `@Test`, `#expect`); UI tests use XCUITest. Add tests to the matching module target and keep fixtures under `Tests/<Target>/Fixtures/`. Cover new behavior, regressions, and availability guards for AR or platform-specific code. Keep the full `CoverCraft.xctestplan` green before review.

## Commit & Pull Request Guidelines
Recent history uses Conventional-Commits-lite prefixes: `fix(ar): ...`, `test: ...`, `chore(tests): ...`, `deps: ...`. Keep subjects short and factual; use the body for rationale or risk.

PRs should state scope, affected modules, and exact test evidence. Include screenshots for UI changes. Call out any new dependency, public API, DTO schema change, or `@unchecked Sendable` usage.

## Current Branch Note
Keep the GitHub tree minimal. Historical handoffs, generated TODOs, old review dumps, local assistant state, and device build artifacts do not belong in the tracked repository. Verify current git status, package tests, and the full `CoverCraft.xctestplan` before branch or release decisions.
