# CoverCraft

CoverCraft is an iOS 18+ Swift app for generating sewing-pattern exports from either a LiDAR scan or manual furniture dimensions. The app shell is intentionally thin; production code lives in the Swift package modules.

## Project Architecture

```
CoverCraft/
├── CoverCraft.xcworkspace/              # Open this file in Xcode
├── CoverCraft.xcodeproj/                # App shell project
├── CoverCraft/                          # App target (minimal)
│   ├── Assets.xcassets/                # App-level assets (icons, colors)
│   ├── CoverCraftApp.swift              # App entry point
│   └── CoverCraft.xctestplan            # Test configuration, excluded from app bundle
├── CoverCraftPackage/                   # Primary development area
│   ├── Package.swift                    # Package configuration
│   ├── Sources/                         # DTO/Core/AR/Segmentation/Flattening/Export/UI/Feature
│   └── Tests/                           # Swift Testing targets and fixtures
└── CoverCraftUITests/                   # UI automation tests
```

## Key Architecture Points

### Workspace + SPM Structure
- **App Shell**: `CoverCraft/` contains minimal app lifecycle code
- **Package Code**: `CoverCraftPackage/Sources/` contains the actual modules
- **Separation**: business logic lives in the Swift package; the app target imports `CoverCraftFeature`

### Module Flow
Keep dependencies one-way:

```
CoverCraftDTO -> CoverCraftCore -> domain modules/UI -> CoverCraftFeature
```

Current modules:
- `CoverCraftDTO`: immutable data contracts
- `CoverCraftCore`: protocols, dependency container, services, slipcover generation
- `CoverCraftAR`: ARKit scanning integration
- `CoverCraftSegmentation`: mesh-to-panel segmentation
- `CoverCraftFlattening`: 3D-to-2D panel flattening and validation
- `CoverCraftExport`: PDF/SVG/PNG export
- `CoverCraftUI`: reusable SwiftUI screens and components
- `CoverCraftFeature`: app workflow orchestration

### Buildable Folders (Xcode 16)
- Files added to the filesystem automatically appear in Xcode
- No need to manually add normal source files to project targets
- Local assistant/cached files inside synchronized folders must be ignored and excluded from target membership
- Reduces project file conflicts in teams

## Development Notes

### Code Organization
Make changes in the module that owns the behavior. Keep cross-module APIs `public` with explicit `public init` declarations.

### Public API Requirements
Types exposed to the app target need `public` access:
```swift
public struct NewView: View {
    public init() {}
    
    public var body: some View {
        // Your view code
    }
}
```

### Adding Dependencies
Edit `CoverCraftPackage/Package.swift` to add SPM dependencies:
```swift
dependencies: [
    .package(url: "https://github.com/example/SomePackage", from: "1.0.0")
],
targets: [
    .target(
        name: "CoverCraftFeature",
        dependencies: ["SomePackage"]
    ),
]
```

### Test Structure
- **Package Tests**: `CoverCraftPackage/Tests/<TargetName>/` (Swift Testing framework)
- **UI Tests**: `CoverCraftUITests/` (XCUITest framework)
- **Test Plan**: `CoverCraft/CoverCraft.xctestplan` coordinates package and UI tests

Useful commands:

```bash
swift build --package-path CoverCraftPackage
swift test --package-path CoverCraftPackage
xcodebuild -workspace CoverCraft.xcworkspace -scheme CoverCraft -testPlan CoverCraft -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Configuration

### XCConfig Build Settings
Build settings are managed through **XCConfig files** in `Config/`:
- `Config/Shared.xcconfig` - Common settings (bundle ID, versions, deployment target)
- `Config/Debug.xcconfig` - Debug-specific settings  
- `Config/Release.xcconfig` - Release-specific settings
- `Config/Tests.xcconfig` - Test-specific settings

### Entitlements Management
App capabilities are managed through a **declarative entitlements file**:
- `Config/CoverCraft.entitlements` - All app entitlements and capabilities
- AI agents can safely edit this XML file to add HealthKit, CloudKit, Push Notifications, etc.
- No need to modify complex Xcode project files

### Asset Management
- **App-Level Assets**: `CoverCraft/Assets.xcassets/` (app icon, accent color)
- **Feature Assets**: Add `Resources/` folder to SPM package if needed

### SPM Package Resources
To include assets in your feature package:
```swift
.target(
    name: "CoverCraftFeature",
    dependencies: [],
    resources: [.process("Resources")]
)
```

## Documentation

Active project guidance lives in `AGENTS.md`, `CLAUDE.md`, this README, and inline source comments. Historical handoffs, review dumps, generated TODO lists, and assistant scratch files are intentionally kept out of the GitHub tree.

### Generated with XcodeBuildMCP
This project was scaffolded using [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP), which provides tools for AI-assisted iOS development workflows.
