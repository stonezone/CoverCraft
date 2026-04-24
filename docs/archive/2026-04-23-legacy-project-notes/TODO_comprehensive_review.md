# CoverCraft Comprehensive Code Review - Implementation Plan

**Generated**: 2025-12-14
**Scope**: All findings from full codebase review
**Total Items**: 37 findings across 5 categories

---

## P0 - CRITICAL (Must Fix Before Production)

### 1. Implement "View Pattern" Navigation Action
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:68-71`
**Current State**: Button action is empty comment

**Steps**:
1. Read `ContentView.swift` to understand navigation context
2. Add `@State private var showingExportView = false` property
3. Replace empty button action with `showingExportView = true`
4. Add `.sheet(isPresented: $showingExportView)` modifier presenting `ExportView`
5. Pass `appState.flattenedPanels` to `ExportView`
6. Test: Generate pattern → tap "View Pattern" → verify ExportView appears

---

### 2. Add Persistent File Storage for Exports
**File**: `CoverCraftPackage/Sources/CoverCraftUI/Views/ExportView.swift:243`
**Current State**: Saves to `FileManager.default.temporaryDirectory` (may be purged)

**Steps**:
1. Create `FileStorageService` protocol in `CoverCraftCore/ServiceProtocols.swift`
2. Create `DefaultFileStorageService` implementation:
   ```swift
   func savePattern(_ data: Data, filename: String) throws -> URL {
       let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
       let patternsFolderURL = documentsURL.appendingPathComponent("CoverCraft Patterns", isDirectory: true)
       try FileManager.default.createDirectory(at: patternsFolderURL, withIntermediateDirectories: true)
       let fileURL = patternsFolderURL.appendingPathComponent(filename)
       try data.write(to: fileURL, options: .atomic)
       return fileURL
   }
   ```
3. Register service in `DefaultDependencyContainer`
4. Update `ExportView.exportPattern()` to use new service
5. Add "Save to Files" button using `fileExporter` modifier
6. Add "Open in Files" option after successful save
7. Test: Export → close app → reopen → verify file persists in Files app

---

### 3. Hide DXF from Format Picker Until Implemented
**Files**:
- `CoverCraftPackage/Sources/CoverCraftExport/DefaultPatternExportService.swift:48-52`
- `CoverCraftPackage/Sources/CoverCraftCore/ServiceProtocols.swift` (ExportFormat enum)

**Steps**:
1. Read `DefaultPatternExportService.getSupportedFormats()` implementation
2. Remove `.dxf` from returned array in `getSupportedFormats()`
3. Keep enum case for future implementation, just don't expose in UI
4. Update `ExportView` to only show formats from `getSupportedFormats()`
5. Add comment in code: `// DXF: Hidden until full implementation complete`
6. Test: Open export view → verify DXF not visible in picker

---

### 4. Add Input Validation Bounds for Manual Dimensions
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:136-161`
**Current State**: Only checks `> 1`, no upper bound, allows negatives

**Steps**:
1. Create `DimensionConstants` struct in `CoverCraftCore`:
   ```swift
   public struct DimensionConstants {
       public static let minDimension: Double = 10 // 10mm minimum
       public static let maxDimension: Double = 10000 // 10 meters maximum
   }
   ```
2. Update `AppState.canGeneratePattern` to validate bounds
3. Add `.onChange` modifier to TextField to clamp values
4. Add validation feedback below each field (red text for invalid)
5. Disable Generate button with clear message if invalid
6. Test: Enter -50 → verify clamped to 10; Enter 999999 → verify clamped to 10000

---

### 5. Add Warning Dialog for "Fitted (Experimental)" Mode
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:244-249`
**Current State**: No warning when selecting experimental mode

**Steps**:
1. Add `@State private var showFittedWarning = false` to ContentView
2. Add `.onChange(of: appState.patternMode)` modifier
3. When mode changes to `.fitted`, set `showFittedWarning = true`
4. Add `.alert("Experimental Feature", isPresented: $showFittedWarning)`:
   ```swift
   .alert("Experimental Feature", isPresented: $showFittedWarning) {
       Button("Continue Anyway") { }
       Button("Use Slipcover Instead", role: .cancel) {
           appState.patternMode = .slipcover
       }
   } message: {
       Text("Fitted pattern generation is experimental and may produce unreliable results. Slipcover mode is recommended for production use.")
   }
   ```
5. Test: Select Fitted → verify warning appears → test both button actions

---

## P1 - HIGH PRIORITY (User Experience)

### 6. Add AR Scan Quality Indicator
**File**: `CoverCraftPackage/Sources/CoverCraftAR/ARScanViewController.swift`
**Current State**: Shows vertex/triangle count only, no quality feedback

**Steps**:
1. Create `ScanQualityMetrics` struct:
   ```swift
   struct ScanQualityMetrics {
       var meshDensity: Float // triangles per square meter
       var coveragePercent: Float // estimated object coverage
       var qualityRating: QualityRating // .poor, .fair, .good, .excellent
   }
   ```
2. Add quality calculation method to ARScanViewController
3. Create quality indicator UI overlay:
   - Circular progress ring showing coverage
   - Color-coded quality badge (red/yellow/green)
   - Text guidance ("Move closer", "Scan other side", "Good coverage!")
4. Update `updateMeshInfo()` to calculate and display metrics
5. Add haptic feedback when quality transitions to "good"
6. Test: Scan object → verify quality indicator updates in real-time

---

### 7. Implement Undo/Redo for Mesh Processing
**Files**:
- `CoverCraftPackage/Sources/CoverCraftFeature/AppState.swift`
- `CoverCraftPackage/Sources/CoverCraftUI/Views/MeshProcessingView.swift`

**Steps**:
1. Create `MeshHistoryManager` class:
   ```swift
   @Observable
   class MeshHistoryManager {
       private var history: [MeshDTO] = []
       private var currentIndex: Int = -1

       var canUndo: Bool { currentIndex > 0 }
       var canRedo: Bool { currentIndex < history.count - 1 }

       func push(_ mesh: MeshDTO)
       func undo() -> MeshDTO?
       func redo() -> MeshDTO?
   }
   ```
2. Add `meshHistory: MeshHistoryManager` to AppState
3. Update `MeshProcessingView.processNow()` to push to history before processing
4. Add Undo/Redo buttons to MeshProcessingView toolbar
5. Wire buttons to history manager
6. Add keyboard shortcuts (Cmd+Z, Cmd+Shift+Z)
7. Test: Process mesh → Undo → verify original restored → Redo → verify processed restored

---

### 8. Create First-Time Onboarding Flow
**Files**: Create new `CoverCraftUI/Views/OnboardingView.swift`

**Steps**:
1. Create `OnboardingView` with 4-5 pages:
   - Page 1: Welcome + app purpose
   - Page 2: LiDAR scanning demo (animated)
   - Page 3: Calibration explanation
   - Page 4: Pattern modes comparison
   - Page 5: Export options
2. Use `TabView` with `PageTabViewStyle`
3. Add `@AppStorage("hasCompletedOnboarding")` flag
4. Update `CoverCraftApp.swift` to show onboarding if flag is false
5. Add "Skip" button and "Get Started" on last page
6. Add "Show Tutorial" button to HelpView for re-access
7. Test: Fresh install → verify onboarding shows → complete → verify doesn't show again

---

### 9. Make Seam Allowance Configurable
**Files**:
- `CoverCraftPackage/Sources/CoverCraftDTO/SlipcoverPatternOptions.swift`
- `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`
- `CoverCraftPackage/Sources/CoverCraftFlattening/DefaultPatternFlatteningService.swift:734`

**Steps**:
1. Add `seamAllowanceMillimeters: Double` to `SlipcoverPatternOptions` (default: 10)
2. Add `seamAllowanceMillimeters: Double` to `AppState` (default: 10)
3. Add Stepper to ContentView segmentation section:
   ```swift
   Stepper("Seam allowance: \(Int(appState.seamAllowanceMillimeters))mm",
           value: $appState.seamAllowanceMillimeters, in: 0...25, step: 1)
   ```
4. Pass seam allowance through to `SlipcoverPatternGenerator`
5. Update `PatternExporter` to use configured value instead of hardcoded 5mm
6. Update export preview to show seam allowance indicator
7. Test: Set 15mm seam allowance → export → verify seam lines reflect setting

---

### 10. Add Haptic Feedback for Key Actions
**File**: Create `CoverCraftCore/HapticService.swift`

**Steps**:
1. Create `HapticService`:
   ```swift
   #if canImport(UIKit)
   import UIKit

   public final class HapticService: Sendable {
       public static let shared = HapticService()

       public func success() {
           UINotificationFeedbackGenerator().notificationOccurred(.success)
       }
       public func error() {
           UINotificationFeedbackGenerator().notificationOccurred(.error)
       }
       public func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
           UIImpactFeedbackGenerator(style: style).impactOccurred()
       }
   }
   #endif
   ```
2. Add haptics to key actions:
   - Pattern generation complete → `.success()`
   - Pattern generation failed → `.error()`
   - Export complete → `.success()`
   - Scan complete → `.success()`
   - Button taps → `.impact(.light)`
3. Test: Trigger each action → verify haptic felt

---

## P2 - MEDIUM PRIORITY (Code Quality)

### 11. Enable and Fix Disabled Test Files
**Location**: `CoverCraftPackage/Tests/**/*.swift.disabled` (19 files)

**Steps**:
1. List all disabled files:
   ```
   DefaultARScanningServiceTests.swift.disabled
   FlatteningServiceTests.swift.disabled
   ExportServiceTests.swift.disabled
   EndToEndWorkflowTests.swift.disabled
   ... (15 more)
   ```
2. For each file:
   a. Rename to remove `.disabled` extension
   b. Run tests: `swift test --filter <TestName>`
   c. Fix compilation errors (update APIs, imports)
   d. Fix failing assertions
   e. Commit when passing
3. Track progress: aim for 3-4 files per session
4. Ensure minimum 80% line coverage when complete
5. Test: `swift test` passes with all tests enabled

---

### 12. Create GitHub Actions CI/CD Workflow
**File**: Create `.github/workflows/ci.yml`

**Steps**:
1. Create workflow file:
   ```yaml
   name: CI
   on: [push, pull_request]
   jobs:
     build-and-test:
       runs-on: macos-14
       steps:
         - uses: actions/checkout@v4
         - name: Select Xcode
           run: sudo xcode-select -s /Applications/Xcode_15.4.app
         - name: Build Package
           run: cd CoverCraftPackage && swift build
         - name: Run Tests
           run: cd CoverCraftPackage && swift test
         - name: Build Xcode Project
           run: xcodebuild -workspace CoverCraft.xcworkspace -scheme CoverCraft -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
   ```
2. Add build status badge to README.md
3. Configure branch protection requiring CI pass
4. Test: Push branch → verify workflow runs → fix any failures

---

### 13. Optimize O(n²) Panel Overlap Validation
**File**: `CoverCraftPackage/Sources/CoverCraftFlattening/PatternValidator.swift:504-530`

**Steps**:
1. Implement spatial grid index:
   ```swift
   struct SpatialGrid {
       private var cells: [GridCell: [Int]] = [:]
       private let cellSize: Double

       mutating func insert(panelIndex: Int, boundingBox: BoundingBox)
       func potentialOverlaps(for boundingBox: BoundingBox) -> [Int]
   }
   ```
2. Update `validatePanelOverlaps`:
   a. Build spatial grid from all panels (O(n))
   b. For each panel, query grid for nearby panels (O(1) average)
   c. Only check overlaps with nearby panels
3. Complexity reduces from O(n²) to O(n) average case
4. Add performance test with 100+ panels
5. Test: Generate 100 panels → verify validation completes in <1 second

---

### 14. Parallelize Panel Flattening with TaskGroup
**File**: `CoverCraftPackage/Sources/CoverCraftFlattening/DefaultPatternFlatteningService.swift:30-86`

**Steps**:
1. Replace sequential loop:
   ```swift
   // BEFORE
   for panel in panels {
       let flattenedPanel = try await flattenSinglePanel(panel, from: mesh)
       flattenedPanels.append(flattenedPanel)
   }

   // AFTER
   let flattenedPanels = try await withThrowingTaskGroup(of: FlattenedPanelDTO.self) { group in
       for panel in panels {
           group.addTask {
               try await self.flattenSinglePanel(panel, from: mesh)
           }
       }
       var results: [FlattenedPanelDTO] = []
       for try await result in group {
           results.append(result)
       }
       return results
   }
   ```
2. Ensure `flattenSinglePanel` is thread-safe (no shared mutable state)
3. Add panel index to maintain order if needed
4. Add performance benchmark test
5. Test: Flatten 10 panels → verify 2-4x speedup on multi-core device

---

### 15. Extract Magic Numbers to Configuration
**Files**: Multiple (ARScanViewController, SegmentationService, FlatteningService)

**Steps**:
1. Create `CoverCraftCore/Configuration.swift`:
   ```swift
   public struct CoverCraftConfiguration: Sendable {
       // AR Scanning
       public var maxAnchorCount: Int = 150
       public var scanDepthLimit: Float = 2.0

       // Segmentation
       public var maxKMeansIterations: Int = 50
       public var convergenceThreshold: Float = 1e-4

       // Flattening
       public var maxLSCMIterations: Int = 1000
       public var seamAllowanceDefault: Double = 10.0

       // Export
       public var pdfDPI: CGFloat = 72
       public var pngDPI: CGFloat = 300

       public static let `default` = CoverCraftConfiguration()
   }
   ```
2. Inject configuration through dependency container
3. Update all services to read from configuration
4. Add configuration override for testing
5. Test: Modify config → verify behavior changes accordingly

---

### 16. Add Analytics/Crash Reporting
**Files**: Create `CoverCraftCore/AnalyticsService.swift`

**Steps**:
1. Create `AnalyticsService` protocol:
   ```swift
   public protocol AnalyticsService: Sendable {
       func trackEvent(_ name: String, properties: [String: Any]?)
       func trackError(_ error: Error, context: [String: Any]?)
       func setUserProperty(_ key: String, value: String?)
   }
   ```
2. Create `DefaultAnalyticsService` implementation (no-op for now)
3. Add analytics calls to key flows:
   - `scan_started`, `scan_completed`, `scan_failed`
   - `pattern_generated`, `pattern_exported`
   - All error cases
4. Create optional Firebase/Sentry adapter when ready
5. Ensure GDPR compliance (opt-in, data minimization)
6. Test: Trigger events → verify logging (console for dev)

---

### 17. Add Input Validation UI Feedback
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:131-166`

**Steps**:
1. Create `DimensionInputField` component:
   ```swift
   struct DimensionInputField: View {
       let label: String
       @Binding var value: Double
       var isValid: Bool { value >= 10 && value <= 10000 }

       var body: some View {
           VStack(alignment: .leading) {
               HStack {
                   Text(label)
                   Spacer()
                   TextField("mm", value: $value, format: .number)
                       .foregroundColor(isValid ? .primary : .red)
               }
               if !isValid {
                   Text("Must be between 10mm and 10,000mm")
                       .font(.caption2)
                       .foregroundColor(.red)
               }
           }
       }
   }
   ```
2. Replace TextField instances with DimensionInputField
3. Add shake animation on invalid submit attempt
4. Test: Enter invalid values → verify error message shows

---

### 18. Add Rate Limiting to Pattern Generation
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:348-440`

**Steps**:
1. Add debounce state:
   ```swift
   @State private var lastGenerationTime: Date?
   private let minimumGenerationInterval: TimeInterval = 2.0
   ```
2. Update `generatePattern()`:
   ```swift
   private func generatePattern() {
       if let lastTime = lastGenerationTime,
          Date().timeIntervalSince(lastTime) < minimumGenerationInterval {
           return // Debounce rapid taps
       }
       lastGenerationTime = Date()
       // ... existing code
   }
   ```
3. Disable button during generation (already done via `isGeneratingPattern`)
4. Test: Rapidly tap Generate → verify only one generation starts

---

## P2 - ARCHITECTURAL IMPROVEMENTS

### 19. Split Monolithic AppState into Focused State Objects
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/AppState.swift`
**Current State**: 67 lines, 15+ properties in single class

**Steps**:
1. Create `ScanState.swift`:
   ```swift
   @Observable
   @MainActor
   public final class ScanState {
       public var currentMesh: MeshDTO?
       public var processedMesh: MeshDTO?
       public var processingOptions = MeshProcessingOptions()
       public var calibrationData = CalibrationDTO()

       public var effectiveMesh: MeshDTO? {
           processedMesh ?? currentMesh
       }
       public var hasProcessedMesh: Bool {
           processedMesh != nil
       }
   }
   ```

2. Create `PatternState.swift`:
   ```swift
   @Observable
   @MainActor
   public final class PatternState {
       public var patternMode: PatternMode = .slipcover
       public var inputMode: PatternInputMode = .scan

       // Manual dimensions
       public var manualWidthMillimeters: Double = 400
       public var manualDepthMillimeters: Double = 400
       public var manualHeightMillimeters: Double = 400

       // Slipcover options
       public var slipcoverTopStyle: SlipcoverTopStyle = .closed
       public var slipcoverEaseMillimeters: Double = 20
       public var slipcoverSegmentsPerSide: Int = 1
       public var slipcoverVerticalSegments: Int = 1
       public var slipcoverPanelization: SlipcoverPanelization = .quads

       // Fitted options
       public var selectedResolution = SegmentationResolution.medium
   }
   ```

3. Create `OutputState.swift`:
   ```swift
   @Observable
   @MainActor
   public final class OutputState {
       public var currentPanels: [PanelDTO]?
       public var flattenedPanels: [FlattenedPanelDTO]?
       public var showPatternReady = false
   }
   ```

4. Update `AppState` to compose these:
   ```swift
   @Observable
   @MainActor
   public final class AppState {
       public var scan = ScanState()
       public var pattern = PatternState()
       public var output = OutputState()

       public var canGeneratePattern: Bool {
           switch pattern.inputMode {
           case .scan:
               return scan.effectiveMesh != nil && scan.calibrationData.isComplete
           case .manual:
               guard pattern.patternMode == .slipcover else { return false }
               return pattern.manualWidthMillimeters > 1 &&
                      pattern.manualDepthMillimeters > 1 &&
                      pattern.manualHeightMillimeters > 1
           }
       }
   }
   ```

5. Update all ContentView references:
   - `appState.currentMesh` → `appState.scan.currentMesh`
   - `appState.patternMode` → `appState.pattern.patternMode`
   - `appState.flattenedPanels` → `appState.output.flattenedPanels`

6. Test: Full workflow → verify all functionality preserved

---

### 20. Add Caching Layer for Mesh Processing
**Files**: Create `CoverCraftCore/CacheService.swift`

**Steps**:
1. Create `ProcessingCache`:
   ```swift
   actor ProcessingCache {
       private var flatteningCache: [String: [FlattenedPanelDTO]] = [:]
       private var segmentationCache: [String: [PanelDTO]] = [:]

       func cacheKey(for mesh: MeshDTO, options: Any) -> String {
           // Hash mesh vertices + options
       }

       func getCachedFlattening(key: String) -> [FlattenedPanelDTO]?
       func setCachedFlattening(key: String, panels: [FlattenedPanelDTO])

       func invalidate()
   }
   ```
2. Inject cache into services via dependency container
3. Update `PatternFlatteningService` to check cache before processing
4. Add cache invalidation when mesh changes
5. Add cache size limit with LRU eviction
6. Test: Generate pattern → regenerate → verify cached result used (faster)

---

### 21. Fix Service Resolution Per-Render Issue
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift:22-31`

**Steps**:
1. Change from computed properties to resolved-once pattern:
   ```swift
   // BEFORE (resolves on every render)
   private var arService: ARScanningService? {
       container.resolve(ARScanningService.self)
   }

   // AFTER (resolves once on appear)
   @State private var arService: ARScanningService?
   @State private var segmentationService: MeshSegmentationService?
   @State private var flatteningService: PatternFlatteningService?

   // In body:
   .onAppear {
       arService = container.resolve(ARScanningService.self)
       segmentationService = container.resolve(MeshSegmentationService.self)
       flatteningService = container.resolve(PatternFlatteningService.self)
   }
   ```
2. Add nil checks with user-friendly error messages
3. Test: Profile with Instruments → verify fewer dictionary lookups

---

### 22. Add Offline Export Resilience
**File**: `CoverCraftPackage/Sources/CoverCraftUI/Views/ExportView.swift`

**Steps**:
1. Wrap export in background task:
   ```swift
   #if os(iOS)
   func exportPattern() {
       var backgroundTask: UIBackgroundTaskIdentifier = .invalid
       backgroundTask = UIApplication.shared.beginBackgroundTask {
           UIApplication.shared.endBackgroundTask(backgroundTask)
       }

       // ... export logic

       UIApplication.shared.endBackgroundTask(backgroundTask)
   }
   #endif
   ```
2. Save export state for recovery:
   - Before export: save pending export to UserDefaults
   - After success: clear pending
   - On app launch: check for pending exports, offer to retry
3. Add export queue for multiple exports
4. Test: Start export → background app → verify completes

---

## P3 - NICE TO HAVE (Future Enhancements)

### 23. Add 3D Mesh Preview
**Files**: Create `CoverCraftUI/Views/MeshPreviewView.swift`

**Steps**:
1. Create SceneKit-based preview:
   ```swift
   import SceneKit

   struct MeshPreviewView: UIViewRepresentable {
       let mesh: MeshDTO

       func makeUIView(context: Context) -> SCNView {
           let sceneView = SCNView()
           sceneView.scene = SCNScene()
           sceneView.allowsCameraControl = true
           sceneView.autoenablesDefaultLighting = true
           return sceneView
       }

       func updateUIView(_ sceneView: SCNView, context: Context) {
           let geometry = createGeometry(from: mesh)
           let node = SCNNode(geometry: geometry)
           sceneView.scene?.rootNode.addChildNode(node)
       }

       private func createGeometry(from mesh: MeshDTO) -> SCNGeometry {
           // Convert MeshDTO vertices to SCNGeometry
       }
   }
   ```
2. Add "Preview Mesh" button to scan section
3. Present in sheet with rotate/zoom controls
4. Add panel coloring when segmentation is available
5. Test: Scan → preview → verify 3D model renders correctly

---

### 24. Add Fitted vs Slipcover Comparison View
**Files**: Create `CoverCraftUI/Views/PatternComparisonView.swift`

**Steps**:
1. Create side-by-side comparison layout:
   ```swift
   struct PatternComparisonView: View {
       let fittedPanels: [FlattenedPanelDTO]?
       let slipcoverPanels: [FlattenedPanelDTO]?

       var body: some View {
           HStack {
               VStack {
                   Text("Fitted").font(.headline)
                   PatternPreview(panels: fittedPanels)
               }
               Divider()
               VStack {
                   Text("Slipcover").font(.headline)
                   PatternPreview(panels: slipcoverPanels)
               }
           }
       }
   }
   ```
2. Generate both patterns when "Compare" button tapped
3. Show metrics comparison (panel count, total area, fabric usage)
4. Allow selecting preferred pattern for export
5. Test: Generate comparison → verify both patterns display

---

### 25. Add Print Tiling for Large Patterns
**Files**:
- `CoverCraftPackage/Sources/CoverCraftExport/DefaultPatternExportService.swift`
- Create `TiledPatternGenerator.swift`

**Steps**:
1. Detect when panel exceeds page size
2. Create `TiledPatternGenerator`:
   ```swift
   struct TiledPatternGenerator {
       let pageSize: CGSize
       let overlap: CGFloat = 10 // mm overlap for alignment

       func tile(panel: FlattenedPanelDTO) -> [TiledPage] {
           // Split panel into printable tiles
           // Add alignment marks at overlaps
           // Add page numbers and assembly guide
       }
   }
   ```
3. Add "Tile Large Panels" toggle in export options
4. Generate multi-page PDF with assembly instructions
5. Add tile alignment marks at overlap regions
6. Test: Export large panel → verify tiles assemble correctly

---

### 26. Add Grain Line Indicators
**Files**:
- `CoverCraftPackage/Sources/CoverCraftDTO/FlattenedPanelDTO.swift`
- `CoverCraftPackage/Sources/CoverCraftExport/PatternExporter.swift`

**Steps**:
1. Add `grainLineAngle: Double` property to `FlattenedPanelDTO`
2. Calculate optimal grain line from panel orientation
3. Create `GrainLineRenderer`:
   ```swift
   func drawGrainLine(in context: CGContext, panel: FlattenedPanelDTO) {
       // Draw double-headed arrow through panel center
       // Add "GRAIN" text label
       // Optionally show bias direction
   }
   ```
4. Add grain line toggle in export options
5. Integrate into PDF/SVG export rendering
6. Test: Export with grain lines → verify arrows display correctly

---

### 27. Add Notch and Alignment Marks
**Files**:
- `CoverCraftPackage/Sources/CoverCraftDTO/FlattenedPanelDTO.swift`
- `CoverCraftPackage/Sources/CoverCraftExport/PatternExporter.swift`

**Steps**:
1. Add `notches: [NotchMark]` to `FlattenedPanelDTO`:
   ```swift
   public struct NotchMark: Codable, Sendable {
       public var position: Point2D
       public var edgeIndex: Int
       public var matchingPanelID: String?
       public var label: String
   }
   ```
2. Generate notches during pattern flattening:
   - Place at seam midpoints
   - Match corresponding notches on adjacent panels
   - Add unique labels (A-A, B-B, etc.)
3. Create `NotchRenderer`:
   ```swift
   func drawNotch(in context: CGContext, at position: CGPoint, label: String) {
       // Draw small triangle/diamond shape
       // Add label text
   }
   ```
4. Add notch toggle in export options
5. Test: Export with notches → verify matching marks on seams

---

### 28. Add Firebase/Sentry Crash Reporting Integration
**Files**:
- `Package.swift` (add dependency)
- `CoverCraftApp.swift` (initialize)
- `CoverCraftCore/AnalyticsService.swift` (adapter)

**Steps**:
1. Choose provider (Sentry recommended for iOS):
   ```swift
   // Package.swift
   .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
   ```
2. Create `SentryAnalyticsAdapter`:
   ```swift
   import Sentry

   public final class SentryAnalyticsAdapter: AnalyticsService {
       public init(dsn: String) {
           SentrySDK.start { options in
               options.dsn = dsn
               options.enableAutoSessionTracking = true
           }
       }

       public func trackEvent(_ name: String, properties: [String: Any]?) {
           SentrySDK.capture(message: name) { scope in
               properties?.forEach { scope.setExtra(value: $1, key: $0) }
           }
       }

       public func trackError(_ error: Error, context: [String: Any]?) {
           SentrySDK.capture(error: error)
       }
   }
   ```
3. Add privacy consent flow before enabling
4. Create admin dashboard for viewing crashes
5. Test: Force crash → verify appears in Sentry dashboard

---

### 29. Add Unit Selector for Manual Dimensions
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`

**Steps**:
1. Add unit enum and state:
   ```swift
   enum DimensionUnit: String, CaseIterable {
       case millimeters = "mm"
       case centimeters = "cm"
       case inches = "in"

       var toMillimeters: Double {
           switch self {
           case .millimeters: return 1.0
           case .centimeters: return 10.0
           case .inches: return 25.4
           }
       }
   }

   @State private var dimensionUnit: DimensionUnit = .millimeters
   ```
2. Add unit picker to manual dimensions section
3. Convert displayed values based on selected unit
4. Store internally always as millimeters
5. Test: Enter 10 inches → verify converts to 254mm internally

---

### 30. Add Accessibility Labels Throughout
**Files**: All View files in `CoverCraftUI/Views/`

**Steps**:
1. Audit all interactive elements
2. Add accessibility modifiers:
   ```swift
   Button("Generate Pattern") { ... }
       .accessibilityLabel("Generate cutting pattern")
       .accessibilityHint("Double tap to create pattern pieces from your scan")

   Slider(value: $ease, in: 0...200)
       .accessibilityLabel("Ease adjustment")
       .accessibilityValue("\(Int(ease)) millimeters")
   ```
3. Add accessibility grouping for related elements
4. Test with VoiceOver enabled
5. Verify Dynamic Type scaling works
6. Test: Enable VoiceOver → navigate entire app → verify all elements announced

---

### 31. Add Dark Mode Color Optimization
**Files**:
- Create `CoverCraftUI/Theme/ColorTheme.swift`
- Update all hardcoded colors

**Steps**:
1. Create semantic color definitions:
   ```swift
   extension Color {
       static let ccPrimary = Color("Primary", bundle: .module)
       static let ccSecondary = Color("Secondary", bundle: .module)
       static let ccBackground = Color("Background", bundle: .module)
       static let ccError = Color("Error", bundle: .module)
   }
   ```
2. Add color assets with light/dark variants
3. Replace all hardcoded colors:
   - `.blue` → `.ccPrimary`
   - `.gray.opacity(0.1)` → `.ccBackground`
4. Add high contrast mode support
5. Test: Toggle dark mode → verify all elements visible and readable

---

### 32. Modernize UI to Card-Based Layout
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`

**Steps**:
1. Create `CardView` component:
   ```swift
   struct CardView<Content: View>: View {
       let title: String
       let icon: String
       @ViewBuilder let content: () -> Content

       var body: some View {
           VStack(alignment: .leading, spacing: 12) {
               HStack {
                   Image(systemName: icon)
                   Text(title).font(.headline)
               }
               content()
           }
           .padding()
           .background(RoundedRectangle(cornerRadius: 16).fill(.background))
           .shadow(radius: 2)
       }
   }
   ```
2. Replace `List` with `ScrollView` + `LazyVStack`
3. Wrap each section in `CardView`
4. Add expand/collapse animation for sections
5. Add drag-to-reorder for workflow customization
6. Test: Visual comparison → verify modern appearance

---

### 33. Fix Section Numbering Consistency
**File**: `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`

**Steps**:
1. Rename sections to consistent scheme:
   - "1. Scan or Enter Dimensions"
   - "2. Mesh Cleanup (Optional)"
   - "3. Calibration"
   - "4. Pattern Configuration"
   - "5. Generate & Export"
2. Or remove numbers entirely and use icons only
3. Add visual step indicator at top showing progress
4. Test: Review flow → verify logical progression

---

### 34. Add Pattern Measurement Display on Exports
**Files**:
- `CoverCraftPackage/Sources/CoverCraftExport/PatternExporter.swift`
- `CoverCraftPackage/Sources/CoverCraftUI/Views/ExportView.swift`

**Steps**:
1. Calculate and store panel dimensions in millimeters
2. Add dimension lines to export rendering:
   ```swift
   func drawDimensionLine(context: CGContext, from: CGPoint, to: CGPoint, label: String) {
       // Draw line with arrows at ends
       // Add centered measurement text
       // Format: "245mm" or "9.6in"
   }
   ```
3. Add width/height dimensions to each panel
4. Add total fabric usage calculation
5. Show dimensions in ExportView preview
6. Test: Export → verify dimensions printed on pattern pieces

---

### 35. Add Scan History/Persistence
**Files**:
- Create `CoverCraftCore/PersistenceService.swift`
- Update `AppState.swift`

**Steps**:
1. Create `ScanRecord` model:
   ```swift
   struct ScanRecord: Codable, Identifiable {
       let id: UUID
       let createdAt: Date
       let name: String
       let mesh: MeshDTO
       let calibration: CalibrationDTO?
       let thumbnail: Data?
   }
   ```
2. Create `PersistenceService`:
   ```swift
   actor PersistenceService {
       private let fileManager = FileManager.default

       func saveScan(_ record: ScanRecord) async throws
       func loadScans() async throws -> [ScanRecord]
       func deleteScan(id: UUID) async throws
   }
   ```
3. Add "Save Scan" button after successful scan
4. Create "Scan Library" view showing saved scans
5. Allow loading saved scans into current session
6. Test: Scan → save → close app → reopen → load → verify mesh restored

---

### 36. Add Multi-Object Support
**Files**:
- `CoverCraftPackage/Sources/CoverCraftFeature/AppState.swift`
- `CoverCraftPackage/Sources/CoverCraftFeature/ContentView.swift`

**Steps**:
1. Change `currentMesh` to `meshes: [MeshDTO]` array
2. Add mesh selection UI (thumbnail strip or list)
3. Allow scanning additional objects to add to collection
4. Generate patterns for all selected meshes
5. Combined export with all patterns
6. Add "Clear All" and individual delete options
7. Test: Scan 3 objects → generate patterns for all → export combined

---

### 37. Improve Error Message User-Friendliness
**Files**: All error enums in `CoverCraftCore/CoverCraftErrors.swift`

**Steps**:
1. Review all `userMessage` strings for technical jargon
2. Replace with actionable guidance:
   ```swift
   // BEFORE
   case .algorithmsFailure(let reason):
       return "Segmentation algorithm failed: \(reason)"

   // AFTER
   case .algorithmsFailure:
       return "We couldn't divide your scan into pattern pieces. Try scanning with more overlap, or use Slipcover mode instead."
   ```
3. Add "Learn More" links where applicable
4. Add error codes only in debug builds
5. Test: Trigger each error → verify message is helpful

---

## Implementation Order Recommendation

### Week 1-2: P0 Critical
1. #1 View Pattern navigation
2. #2 Persistent file storage
3. #3 Hide DXF
4. #4 Input validation
5. #5 Fitted mode warning

### Week 3-4: P1 High Priority
6. #6 AR scan quality
7. #9 Seam allowance config
8. #10 Haptic feedback
9. #8 Onboarding flow
10. #7 Undo/redo

### Week 5-6: P2 Code Quality
11. #12 CI/CD pipeline
12. #11 Enable tests (ongoing)
13. #15 Extract configuration
14. #19 Split AppState
15. #21 Fix service resolution

### Week 7-8: P2 Performance
16. #13 Optimize O(n²)
17. #14 Parallelize flattening
18. #20 Add caching
19. #18 Rate limiting
20. #22 Offline resilience

### Ongoing/Future: P3
21-37. Implement based on user feedback and priorities

---

## Success Metrics

- [ ] All P0 items complete and verified
- [ ] 80%+ test coverage after enabling disabled tests
- [ ] CI/CD pipeline passing on all PRs
- [ ] No crashes in production (analytics verified)
- [ ] User onboarding completion rate >80%
- [ ] Pattern generation success rate >95%
- [ ] Export completion rate >99%

---

**Total Implementation Effort**: ~8-12 weeks for P0-P2, ongoing for P3
**Files Modified**: ~25 source files
**New Files Created**: ~15 new files
