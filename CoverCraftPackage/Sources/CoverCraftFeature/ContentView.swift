import SwiftUI
import Logging
import CoverCraftDTO
import CoverCraftCore
import CoverCraftAR
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport
import CoverCraftUI

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct ContentView: View {
    private let logger = Logger(label: "com.covercraft.feature.contentview")

    @Environment(\.dependencyContainer) private var container

    @State private var arService: ARScanningService?
    @State private var segmentationService: MeshSegmentationService?
    @State private var flatteningService: PatternFlatteningService?
    @State private var hapticService: HapticService?
    @State private var servicesResolved = false

    @State private var appState = Self.makeInitialAppState()
    @State private var confirmedManualFields = Self.makeInitialManualFields()
    @State private var lastGeneratedConfiguration: WorkflowConfiguration?
    @State private var showingScanner = false
    @State private var showingHelp = false
    @State private var isGeneratingPattern = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showFittedModeWarning = false

    public init() {}

    private static func makeInitialAppState() -> AppState {
        let state = AppState()

        if ProcessInfo.processInfo.arguments.contains("UITEST_MANUAL_MODE") {
            state.inputMode = .manual
        }

        if ProcessInfo.processInfo.arguments.contains("UITEST_MANUAL_READY") {
            state.inputMode = .manual
            state.manualWidthMillimeters = 400
            state.manualDepthMillimeters = 400
            state.manualHeightMillimeters = 400
        }

        return state
    }

    private static func makeInitialManualFields() -> Set<ManualDimensionField> {
        guard ProcessInfo.processInfo.arguments.contains("UITEST_MANUAL_READY") else {
            return []
        }

        return Set(ManualDimensionField.allCases)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var workflowTone: CoverCraftTone {
        if hasFreshGeneratedPattern {
            return .success
        }

        if canGenerateCurrentWorkflow {
            return .accent
        }

        if appState.inputMode == .manual {
            return .warning
        }

        if appState.inputMode == .scan && appState.currentMesh == nil {
            return .warning
        }

        return .neutral
    }

    private var workflowStatusTitle: String {
        if hasFreshGeneratedPattern {
            return "Pattern ready"
        }

        if canGenerateCurrentWorkflow {
            return "Ready to generate"
        }

        if appState.inputMode == .manual {
            return "Enter dimensions"
        }

        if appState.currentMesh != nil, !appState.calibrationData.isComplete {
            return "Need scale"
        }

        return "Need scan"
    }

    private var workflowStatusImage: String {
        switch workflowTone {
        case .success:
            return "checkmark.seal.fill"
        case .accent:
            return "sparkles"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "circle.dashed"
        }
    }

    private var inputSummary: String {
        switch appState.inputMode {
        case .scan:
            return appState.currentMesh == nil ? "LiDAR pending" : "Scan captured"
        case .manual:
            return hasConfirmedManualDimensions ? "Dimensions set" : "Manual entry"
        }
    }

    private var calibrationSummary: String {
        switch appState.inputMode {
        case .manual:
            return "Skipped"
        case .scan:
            return appState.calibrationData.isComplete ? "Scaled" : "Pending"
        }
    }

    private var outputSummary: String {
        if hasFreshGeneratedPattern, let flattenedPanels = appState.flattenedPanels {
            return "\(flattenedPanels.count) panels"
        }

        return "No export"
    }

    private var currentWorkflowConfiguration: WorkflowConfiguration {
        WorkflowConfiguration(
            inputMode: appState.inputMode,
            currentMeshID: appState.currentMesh?.id,
            processedMeshID: appState.processedMesh?.id,
            calibrationID: appState.calibrationData.id,
            patternMode: appState.patternMode,
            manualWidthMillimeters: appState.manualWidthMillimeters,
            manualDepthMillimeters: appState.manualDepthMillimeters,
            manualHeightMillimeters: appState.manualHeightMillimeters,
            slipcoverTopStyle: appState.slipcoverTopStyle,
            slipcoverEaseMillimeters: appState.slipcoverEaseMillimeters,
            slipcoverSeamAllowanceMillimeters: appState.slipcoverSeamAllowanceMillimeters,
            slipcoverSegmentsPerSide: appState.slipcoverSegmentsPerSide,
            slipcoverVerticalSegments: appState.slipcoverVerticalSegments,
            slipcoverPanelization: appState.slipcoverPanelization,
            selectedResolution: appState.selectedResolution
        )
    }

    private var hasConfirmedManualDimensions: Bool {
        confirmedManualFields.count == ManualDimensionField.allCases.count
    }

    private var canGenerateCurrentWorkflow: Bool {
        switch appState.inputMode {
        case .scan:
            return appState.canGeneratePattern
        case .manual:
            return appState.canGeneratePattern && hasConfirmedManualDimensions
        }
    }

    private var hasFreshGeneratedPattern: Bool {
        guard let flattenedPanels = appState.flattenedPanels, !flattenedPanels.isEmpty else {
            return false
        }

        return lastGeneratedConfiguration == currentWorkflowConfiguration
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    inputCard
                    if appState.inputMode == .scan {
                        meshCleanupCard
                        calibrationCard
                    }
                    patternConfigurationCard
                    workflowHeroCard
                    helpCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background(CoverCraftScreenBackground().ignoresSafeArea())
            .navigationTitle("CoverCraft")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingScanner) {
                #if canImport(UIKit)
                ARScanView(scannedMesh: $appState.currentMesh)
                #else
                Text("AR Scanning not available on this platform")
                    .padding()
                #endif
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .alert("Pattern Generation Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .alert("Experimental Feature", isPresented: $showFittedModeWarning) {
                Button("Continue Anyway") { }
                Button("Use Slipcover", role: .cancel) {
                    appState.patternMode = .slipcover
                }
            } message: {
                Text("Fitted mode uses experimental mesh segmentation that may produce inconsistent results. Slipcover mode is recommended for reliable patterns.")
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .onChange(of: currentWorkflowConfiguration) { _, newConfiguration in
                guard let lastGeneratedConfiguration, lastGeneratedConfiguration != newConfiguration else {
                    return
                }
                invalidateGeneratedOutput()
            }
            .task {
                guard !servicesResolved else { return }
                arService = container.resolve(ARScanningService.self)
                segmentationService = container.resolve(MeshSegmentationService.self)
                flatteningService = container.resolve(PatternFlatteningService.self)
                hapticService = container.resolve(HapticService.self)
                servicesResolved = true
            }
        }
    }

    private var workflowHeroCard: some View {
        CoverCraftCard(tone: workflowTone) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    CoverCraftStatusChip(
                        workflowStatusTitle,
                        systemImage: workflowStatusImage,
                        tone: workflowTone
                    )

                    Text("Generate cleaner sewing patterns from a LiDAR scan or exact dimensions.")
                        .font(.title2.weight(.semibold))

                    Text("The workflow is now organized around the next required action instead of a long settings list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(workflowTone == .success ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
                        .frame(width: 68, height: 68)

                    Image(systemName: appState.inputMode == .scan ? "camera.viewfinder" : "ruler")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(workflowTone == .success ? Color.green : Color.blue)
                }
            }

            LazyVGrid(columns: metricColumns, spacing: 12) {
                CoverCraftMetricTile(
                    title: "Input",
                    value: inputSummary,
                    subtitle: appState.inputMode.rawValue,
                    systemImage: "square.and.pencil",
                    tone: .accent
                )
                CoverCraftMetricTile(
                    title: "Scale",
                    value: calibrationSummary,
                    subtitle: appState.inputMode == .manual ? "Manual mode skips calibration" : "Required before generate",
                    systemImage: "ruler",
                    tone: appState.inputMode == .manual ? .neutral : (appState.calibrationData.isComplete ? .success : .warning)
                )
                CoverCraftMetricTile(
                    title: "Pattern",
                    value: appState.patternMode == .slipcover ? "Slipcover" : "Fitted",
                    subtitle: appState.patternMode == .slipcover ? "Stable bottom-open output" : "Experimental segmentation",
                    systemImage: "square.grid.3x3.fill",
                    tone: appState.patternMode == .slipcover ? .accent : .warning
                )
                CoverCraftMetricTile(
                    title: "Export",
                    value: outputSummary,
                    subtitle: appState.flattenedPanels == nil ? "Generate before exporting" : "Ready for PDF, SVG, PNG",
                    systemImage: "square.and.arrow.up",
                    tone: appState.flattenedPanels == nil ? .neutral : .success
                )
            }
        }
    }

    private var inputCard: some View {
        CoverCraftCard(tone: appState.inputMode == .scan ? .accent : .neutral) {
            CoverCraftSectionHeading(
                step: "Step 1",
                title: "Choose Input",
                subtitle: "Scan for organic geometry or type fixed measurements for rectangular furniture.",
                statusTitle: appState.inputMode == .scan ? "Scan flow" : "Manual flow",
                statusImage: appState.inputMode == .scan ? "camera.viewfinder" : "keyboard",
                tone: appState.inputMode == .scan ? .accent : .neutral
            )

            Picker("Input", selection: $appState.inputMode) {
                ForEach(PatternInputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("covercraft.inputModePicker")

            switch appState.inputMode {
            case .scan:
                scanInputContent
            case .manual:
                manualInputContent
            }
        }
    }

    private var scanInputContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: { showingScanner = true }) {
                Label("Start LiDAR Scan", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .accessibilityIdentifier("covercraft.startScanButton")

            Text("Capture the object from multiple angles, then clean the mesh and calibrate it before generation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let meshDTO = appState.currentMesh {
                let boundaryInfo = meshDTO.analyzeBoundaries()

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    CoverCraftMetricTile(
                        title: "Vertices",
                        value: "\(meshDTO.vertices.count)",
                        subtitle: "Raw point count",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        tone: .accent
                    )
                    CoverCraftMetricTile(
                        title: "Triangles",
                        value: "\(meshDTO.triangleCount)",
                        subtitle: "Surface fidelity",
                        systemImage: "triangle",
                        tone: .accent
                    )
                    CoverCraftMetricTile(
                        title: "Seal",
                        value: boundaryInfo.isWatertight ? "Watertight" : "\(boundaryInfo.holeCount) holes",
                        subtitle: boundaryInfo.isWatertight ? "Good candidate for flattening" : "Cleanup is recommended",
                        systemImage: boundaryInfo.isWatertight ? "checkmark.seal.fill" : "circle.dashed",
                        tone: boundaryInfo.isWatertight ? .success : .warning
                    )
                    CoverCraftMetricTile(
                        title: "Boundary",
                        value: "\(boundaryInfo.boundaryEdges.count)",
                        subtitle: "Open edge count",
                        systemImage: "square.dashed",
                        tone: boundaryInfo.isWatertight ? .neutral : .warning
                    )
                }
            } else {
                CoverCraftStatusChip(
                    "No mesh captured yet",
                    systemImage: "cube.transparent",
                    tone: .warning
                )
            }
        }
    }

    private var manualInputContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ManualDimensionFieldCard(
                title: "Width",
                symbol: "arrow.left.and.right",
                value: $appState.manualWidthMillimeters,
                accessibilityIdentifier: "covercraft.manualWidthField"
            ) { isValid in
                updateManualConfirmation(.width, isValid: isValid)
            }
            ManualDimensionFieldCard(
                title: "Depth",
                symbol: "arrow.up.and.down",
                value: $appState.manualDepthMillimeters,
                accessibilityIdentifier: "covercraft.manualDepthField"
            ) { isValid in
                updateManualConfirmation(.depth, isValid: isValid)
            }
            ManualDimensionFieldCard(
                title: "Height",
                symbol: "arrow.vertical.2",
                value: $appState.manualHeightMillimeters,
                accessibilityIdentifier: "covercraft.manualHeightField"
            ) { isValid in
                updateManualConfirmation(.height, isValid: isValid)
            }

            CoverCraftStatusChip(
                hasConfirmedManualDimensions ? "Manual dimensions ready" : "Enter all three dimensions",
                systemImage: hasConfirmedManualDimensions ? "checkmark.circle.fill" : "square.and.pencil",
                tone: hasConfirmedManualDimensions ? .success : .warning
            )

            Text("Calibration not required for Manual Dimensions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("covercraft.manualCalibrationNote")

            Text("Valid range is 10-10,000 mm. Pattern generation stays disabled until all three values have been entered or confirmed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var meshCleanupCard: some View {
        CoverCraftCard(tone: appState.hasProcessedMesh ? .success : .neutral) {
            CoverCraftSectionHeading(
                step: "Step 1b",
                title: "Clean Up Mesh",
                subtitle: "Optional but useful when the scan includes floor surfaces, fragments, or open holes.",
                statusTitle: appState.hasProcessedMesh ? "Processed" : "Optional",
                statusImage: appState.hasProcessedMesh ? "checkmark.circle.fill" : "wand.and.stars",
                tone: appState.hasProcessedMesh ? .success : .neutral
            )

            if let mesh = appState.currentMesh {
                NavigationLink {
                    MeshProcessingView(
                        mesh: mesh,
                        processedMesh: $appState.processedMesh,
                        options: $appState.processingOptions
                    )
                } label: {
                    WorkflowNavigationRow(
                        title: "Open cleanup tools",
                        subtitle: "Fill holes, crop unwanted surfaces, and isolate the main object before calibration.",
                        systemImage: "wand.and.stars",
                        tone: .accent,
                        trailingText: appState.hasProcessedMesh ? "Updated" : "Review"
                    )
                }
                .buttonStyle(.plain)

                if appState.hasProcessedMesh, let processedMesh = appState.processedMesh {
                    CoverCraftStatusChip(
                        "Using processed mesh • \(processedMesh.triangleCount) triangles",
                        systemImage: "checkmark.circle.fill",
                        tone: .success
                    )
                }
            } else {
                CoverCraftStatusChip(
                    "Capture a LiDAR mesh before mesh cleanup is available",
                    systemImage: "camera.metering.unknown",
                    tone: .warning
                )
            }
        }
    }

    private var calibrationCard: some View {
        CoverCraftCard(tone: appState.calibrationData.isComplete ? .success : .neutral) {
            CoverCraftSectionHeading(
                step: "Step 2",
                title: "Set Real-World Scale",
                subtitle: "Scale the mesh with one measured reference so pattern dimensions stay usable in fabric.",
                statusTitle: appState.inputMode == .manual ? "Skipped" : (appState.calibrationData.isComplete ? "Scaled" : "Required"),
                statusImage: appState.inputMode == .manual ? "minus.circle" : (appState.calibrationData.isComplete ? "checkmark.seal.fill" : "ruler"),
                tone: appState.inputMode == .manual ? .neutral : (appState.calibrationData.isComplete ? .success : .warning)
            )

            if appState.inputMode == .manual {
                CoverCraftStatusChip(
                    "Manual mode does not need calibration",
                    systemImage: "ruler",
                    tone: .neutral
                )

                Text("Calibration not required for Manual Dimensions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("covercraft.manualCalibrationNote")
            } else if let effectiveMesh = appState.effectiveMesh {
                NavigationLink {
                    CalibrationView(
                        mesh: effectiveMesh,
                        calibrationData: $appState.calibrationData
                    )
                } label: {
                    WorkflowNavigationRow(
                        title: appState.calibrationData.isComplete ? "Review calibration" : "Open calibration tools",
                        subtitle: "Pick a reference dimension, enter the measured distance, and apply scale.",
                        systemImage: "ruler",
                        tone: .accent,
                        trailingText: appState.calibrationData.isComplete ? "Edit" : "Open"
                    )
                }
                .buttonStyle(.plain)

                if appState.calibrationData.isComplete {
                    CoverCraftStatusChip(
                        "Scale factor: \(String(format: "%.3f", appState.calibrationData.scaleFactor))",
                        systemImage: "checkmark.circle.fill",
                        tone: .success
                    )
                }
            } else {
                CoverCraftStatusChip(
                    "A scan is required before calibration becomes available",
                    systemImage: "cube.transparent",
                    tone: .warning
                )
            }
        }
    }

    private var patternConfigurationCard: some View {
        CoverCraftCard(tone: appState.patternMode == .slipcover ? .accent : .warning) {
            CoverCraftSectionHeading(
                step: "Step 3",
                title: "Configure Panels",
                subtitle: "Choose the stable slipcover path or the experimental fitted path, then tune the output.",
                statusTitle: appState.patternMode == .slipcover ? "Stable" : "Experimental",
                statusImage: appState.patternMode == .slipcover ? "checkmark.shield.fill" : "flame.fill",
                tone: appState.patternMode == .slipcover ? .accent : .warning
            )

            Picker("Pattern Type", selection: $appState.patternMode) {
                Text("Slipcover").tag(PatternMode.slipcover)
                Text("Fitted").tag(PatternMode.fitted)
            }
            .pickerStyle(.segmented)
            .disabled(appState.inputMode == .manual)
            .onChange(of: appState.patternMode) { _, newMode in
                if newMode == .fitted {
                    showFittedModeWarning = true
                }
            }

            if appState.inputMode == .manual {
                Text("Manual dimensions only support slipcover generation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            switch appState.patternMode {
            case .fitted:
                fittedConfiguration
            case .slipcover:
                slipcoverConfiguration
            }
        }
    }

    private var fittedConfiguration: some View {
        VStack(alignment: .leading, spacing: 14) {
            CoverCraftStatusChip(
                "Fitted mode can need retries on noisy meshes",
                systemImage: "exclamationmark.triangle.fill",
                tone: .warning
            )

            Picker("Resolution", selection: $appState.selectedResolution) {
                Text("Low").tag(SegmentationResolution.low)
                Text("Medium").tag(SegmentationResolution.medium)
                Text("High").tag(SegmentationResolution.high)
            }
            .pickerStyle(.segmented)

            if let effectiveMesh = appState.effectiveMesh {
                NavigationLink {
                    SegmentationPreview(
                        mesh: effectiveMesh,
                        resolution: appState.selectedResolution,
                        panels: $appState.currentPanels
                    )
                } label: {
                    WorkflowNavigationRow(
                        title: "Preview segmentation",
                        subtitle: "See estimated panel count before you flatten the fitted pattern.",
                        systemImage: "square.grid.3x3",
                        tone: .warning,
                        trailingText: "Preview"
                    )
                }
                .buttonStyle(.plain)
            } else {
                CoverCraftStatusChip(
                    "Segmentation preview unlocks after capture and calibration",
                    systemImage: "eye.slash",
                    tone: .neutral
                )
            }

            Text("Higher resolution produces more panels and more seam lines.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var slipcoverConfiguration: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Top", selection: $appState.slipcoverTopStyle) {
                Text("Closed").tag(SlipcoverTopStyle.closed)
                Text("Open").tag(SlipcoverTopStyle.open)
            }
            .pickerStyle(.segmented)

            ValueSliderCard(
                title: "Ease",
                valueLabel: "\(Int(appState.slipcoverEaseMillimeters)) mm",
                systemImage: "arrow.up.left.and.arrow.down.right",
                tone: .accent,
                slider: AnyView(
                    Slider(value: $appState.slipcoverEaseMillimeters, in: 0...200, step: 5)
                        .tint(.blue)
                ),
                footnote: "Extra room added around the object before panel generation."
            )

            ValueSliderCard(
                title: "Seam Allowance",
                valueLabel: "\(Int(appState.slipcoverSeamAllowanceMillimeters)) mm",
                systemImage: "scissors",
                tone: .accent,
                slider: AnyView(
                    Slider(value: $appState.slipcoverSeamAllowanceMillimeters, in: 3...50, step: 1)
                        .tint(.blue)
                ),
                footnote: "Fabric edge margin included around each panel."
            )

            HStack(spacing: 12) {
                StepperCard(
                    title: "Segments per side",
                    value: appState.slipcoverSegmentsPerSide,
                    systemImage: "square.split.2x2",
                    tone: .accent
                ) {
                    Stepper(
                        "Segments per side: \(appState.slipcoverSegmentsPerSide)",
                        value: $appState.slipcoverSegmentsPerSide,
                        in: 1...16
                    )
                    .labelsHidden()
                }

                StepperCard(
                    title: "Vertical segments",
                    value: appState.slipcoverVerticalSegments,
                    systemImage: "rectangle.split.3x1",
                    tone: .accent
                ) {
                    Stepper(
                        "Vertical segments: \(appState.slipcoverVerticalSegments)",
                        value: $appState.slipcoverVerticalSegments,
                        in: 1...16
                    )
                    .labelsHidden()
                }
            }

            Picker("Panels", selection: $appState.slipcoverPanelization) {
                ForEach(SlipcoverPanelization.allCases, id: \.self) { panelization in
                    Text(panelization.rawValue).tag(panelization)
                }
            }
            .pickerStyle(.segmented)

            Text("Slipcover output stays bottom-open and is the most reliable path for production use.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var helpCard: some View {
        CoverCraftCard(tone: .neutral) {
            CoverCraftSectionHeading(
                step: "Help",
                title: "Need the workflow guide?",
                subtitle: "Open the built-in instructions for scanning, calibration, and export recommendations.",
                tone: .neutral
            )

            Button(action: { showingHelp = true }) {
                Label("How to Use", systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            CoverCraftCard(tone: hasFreshGeneratedPattern ? .success : workflowTone) {
                if hasFreshGeneratedPattern, let flattenedPanels = appState.flattenedPanels, !flattenedPanels.isEmpty {
                    HStack(spacing: 12) {
                        NavigationLink {
                            ExportView(flattenedPanels: flattenedPanels)
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityIdentifier("covercraft.exportPatternLink")
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button(action: generatePattern) {
                            if isGeneratingPattern {
                                Label("Generating...", systemImage: "hourglass")
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canGenerateCurrentWorkflow || isGeneratingPattern)
                    }
                } else {
                    Button(action: generatePattern) {
                        if isGeneratingPattern {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Generating...")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else {
                            Label("Generate Pattern", systemImage: "scissors")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityIdentifier("covercraft.generatePatternButton")
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.blue)
                    .disabled(!canGenerateCurrentWorkflow || isGeneratingPattern)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func generatePattern() {
        guard canGenerateCurrentWorkflow else { return }

        guard let flattener = flatteningService else {
            let message = "Required services are not available. Please restart the app."
            logger.critical("\(message)")
            errorMessage = message
            showErrorAlert = true
            return
        }

        isGeneratingPattern = true

        Task {
            do {
                switch appState.patternMode {
                case .fitted:
                    guard appState.inputMode == .scan, let meshToUse = appState.effectiveMesh else {
                        throw NSError(domain: "CoverCraft", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fitted patterns require a LiDAR scan and calibration."])
                    }
                    let scaledMesh = meshToUse.scaled(by: appState.calibrationData.scaleFactor)
                    guard let segmenter = segmentationService else {
                        throw NSError(domain: "CoverCraft", code: 1, userInfo: [NSLocalizedDescriptionKey: "Segmentation service not available"])
                    }

                    let panels = try await segmenter.segmentMesh(
                        scaledMesh,
                        targetPanelCount: appState.selectedResolution.targetPanelCount
                    )

                    let flattenedPanels = try await flattener.flattenPanels(panels, from: scaledMesh)
                    let optimizedPanels = try await flattener.optimizeForCutting(flattenedPanels)

                    await MainActor.run {
                        appState.currentPanels = panels
                        appState.flattenedPanels = optimizedPanels
                        appState.showPatternReady = false
                        lastGeneratedConfiguration = currentWorkflowConfiguration
                        isGeneratingPattern = false
                        hapticService?.success()
                    }
                case .slipcover:
                    let options = SlipcoverPatternOptions(
                        topStyle: appState.slipcoverTopStyle,
                        easeMillimeters: appState.slipcoverEaseMillimeters,
                        seamAllowanceMillimeters: appState.slipcoverSeamAllowanceMillimeters,
                        segmentsPerSide: appState.slipcoverSegmentsPerSide,
                        verticalSegments: appState.slipcoverVerticalSegments,
                        panelization: appState.slipcoverPanelization
                    )
                    let inputMode = appState.inputMode
                    let effectiveMesh = appState.effectiveMesh
                    let scaleFactor = appState.calibrationData.scaleFactor
                    let manualWidth = appState.manualWidthMillimeters
                    let manualDepth = appState.manualDepthMillimeters
                    let manualHeight = appState.manualHeightMillimeters

                    let generatedPanels: [FlattenedPanelDTO] = try await Task.detached {
                        let generator = SlipcoverPatternGenerator()
                        switch inputMode {
                        case .scan:
                            guard let meshToUse = effectiveMesh else {
                                throw NSError(domain: "CoverCraft", code: 3, userInfo: [NSLocalizedDescriptionKey: "No mesh available."])
                            }
                            let scaledMesh = meshToUse.scaled(by: scaleFactor)
                            return try generator.generate(from: scaledMesh, options: options)
                        case .manual:
                            return try generator.generate(
                                widthMillimeters: manualWidth,
                                depthMillimeters: manualDepth,
                                heightMillimeters: manualHeight,
                                options: options
                            )
                        }
                    }.value

                    let optimizedPanels = try await flattener.optimizeForCutting(generatedPanels)

                    await MainActor.run {
                        appState.currentPanels = nil
                        appState.flattenedPanels = optimizedPanels
                        appState.showPatternReady = false
                        lastGeneratedConfiguration = currentWorkflowConfiguration
                        isGeneratingPattern = false
                        hapticService?.success()
                    }
                }
            } catch {
                await MainActor.run {
                    isGeneratingPattern = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    hapticService?.error()
                }
            }
        }
    }

    private func invalidateGeneratedOutput() {
        guard appState.currentPanels != nil || appState.flattenedPanels != nil else { return }

        appState.output.clearOutput()
        lastGeneratedConfiguration = nil
    }

    private func updateManualConfirmation(_ field: ManualDimensionField, isValid: Bool) {
        if isValid {
            confirmedManualFields.insert(field)
        } else {
            confirmedManualFields.remove(field)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct WorkflowNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tone: CoverCraftTone
    let trailingText: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tone == .warning ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tone == .warning ? Color.orange : Color.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            VStack(spacing: 4) {
                Text(trailingText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

@available(iOS 18.0, macOS 15.0, *)
private enum ManualDimensionField: CaseIterable {
    case width
    case depth
    case height
}

@available(iOS 18.0, macOS 15.0, *)
private struct WorkflowConfiguration: Equatable {
    let inputMode: PatternInputMode
    let currentMeshID: UUID?
    let processedMeshID: UUID?
    let calibrationID: UUID
    let patternMode: PatternMode
    let manualWidthMillimeters: Double
    let manualDepthMillimeters: Double
    let manualHeightMillimeters: Double
    let slipcoverTopStyle: SlipcoverTopStyle
    let slipcoverEaseMillimeters: Double
    let slipcoverSeamAllowanceMillimeters: Double
    let slipcoverSegmentsPerSide: Int
    let slipcoverVerticalSegments: Int
    let slipcoverPanelization: SlipcoverPanelization
    let selectedResolution: SegmentationResolution
}

@available(iOS 18.0, macOS 15.0, *)
private struct ManualDimensionFieldCard: View {
    let title: String
    let symbol: String
    @Binding var value: Double
    let accessibilityIdentifier: String
    let onValidityChange: (Bool) -> Void

    @State private var text: String

    init(
        title: String,
        symbol: String,
        value: Binding<Double>,
        accessibilityIdentifier: String,
        onValidityChange: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self._value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onValidityChange = onValidityChange
        self._text = State(initialValue: Self.text(for: value.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)
                .font(.headline)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                TextField("Required", text: $text)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier(accessibilityIdentifier)
                    #if canImport(UIKit)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(width: 92)
                    .onChange(of: text) { _, newValue in
                        applyText(newValue)
                    }

                Text("mm")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.75))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private static func text(for value: Double) -> String {
        guard value > 0 else { return "" }
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }

    private func applyText(_ rawValue: String) {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, let parsedValue = Double(trimmedValue) else {
            value = 0
            onValidityChange(false)
            return
        }

        value = parsedValue
        onValidityChange((10...10000).contains(parsedValue))
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct ValueSliderCard: View {
    let title: String
    let valueLabel: String
    let systemImage: String
    let tone: CoverCraftTone
    let slider: AnyView
    let footnote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)

                Spacer()

                Text(valueLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tone == .warning ? Color.orange : Color.blue)
            }

            slider

            Text(footnote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct StepperCard<Control: View>: View {
    let title: String
    let value: Int
    let systemImage: String
    let tone: CoverCraftTone
    @ViewBuilder let control: () -> Control

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone == .warning ? Color.orange : Color.blue)

            Text("\(value)")
                .font(.title2.weight(.semibold))

            control()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}
