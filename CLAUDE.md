# CoverCraft Claude Notes

Use this file only for current project behavior. Historical handoffs, generated TODOs, and old review dumps should stay out of GitHub.

## Current Product Direction

CoverCraft is an iOS 18+ Swift app for generating sewing-pattern exports from either manual furniture dimensions or LiDAR/AR scans. Manual dimensions are the primary reliability path until export scale, seam allowance, and print layout are proven on real output.

## Work Location

- Open `CoverCraft.xcworkspace`, not `CoverCraft.xcodeproj`.
- Keep app-shell code in `CoverCraft/` minimal.
- Put production code in `CoverCraftPackage/Sources/`.
- Put package tests in `CoverCraftPackage/Tests/<TargetName>/`.
- Put UI automation in `CoverCraftUITests/`.

## Module Flow

```text
CoverCraftDTO -> CoverCraftCore -> domain modules/UI -> CoverCraftFeature -> app shell
```

Do not introduce reverse dependencies between modules.

## Build And Test

```bash
swift build --package-path CoverCraftPackage
swift test --package-path CoverCraftPackage
xcodebuild -workspace CoverCraft.xcworkspace -scheme CoverCraft -testPlan CoverCraft -destination 'platform=iOS Simulator,name=iPhone 17' test
```

For device builds, build from the workspace and install the resulting `.app` with `xcrun devicectl`.

## Repository Hygiene

- Do not commit local assistant state, caches, generated reports, device build output, or root-level handoff/TODO scratch files.
- The app target uses Xcode synchronized folders. If a local-only file lives under `CoverCraft/`, add both a `.gitignore` rule and an Xcode synchronized-folder membership exception so it cannot be copied into the app bundle.
- Keep `Package.resolved` tracked only at `CoverCraftPackage/Package.resolved`.
- Keep docs short and current. If a document is not actionable for future maintainers, remove it from the tracked tree.

## Coding Rules

- Swift style: 4-space indentation, `// MARK: -` section dividers, and existing file header conventions.
- Public cross-module APIs need explicit `public` access and `public init`.
- Prefer immutable DTO structs.
- Use `async throws` service boundaries.
- Use `LocalizedError` for error enums.
- Use `swift-log`, not `print()`, in production paths.
- Add `@unchecked Sendable` only with a documented synchronization reason.
