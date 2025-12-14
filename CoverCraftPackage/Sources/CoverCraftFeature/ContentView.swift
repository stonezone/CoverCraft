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

    // MARK: - State
    
    @Environment(\.dependencyContainer) private var container
    
    // MARK: - Dependencies (resolved once on appear)

    @State private var arService: ARScanningService?
    @State private var segmentationService: MeshSegmentationService?
    @State private var flatteningService: PatternFlatteningService?
    @State private var hapticService: HapticService?
    @State private var servicesResolved = false

    @State private var appState = AppState()
    @State private var showingScanner = false
    @State private var showingHelp = false
    @State private var showingExportView = false
    @State private var isGeneratingPattern = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showFittedModeWarning = false

    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            List {
                scanSection
                processingSection
                calibrationSection
                segmentationSection
                exportSection
                helpSection
            }
            .navigationTitle("CoverCraft")
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
            .alert("Pattern Generated", isPresented: $appState.showPatternReady) {
                Button("View Pattern") {
                    showingExportView = true
                }
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $showingExportView) {
                NavigationStack {
                    ExportView(flattenedPanels: appState.flattenedPanels)
                }
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
    
    // MARK: - Sections
    
    private var scanSection: some View {
        Section {
            Picker("Input", selection: $appState.inputMode) {
                ForEach(PatternInputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            switch appState.inputMode {
            case .scan:
                Button(action: { showingScanner = true }) {
                    Label("Start LiDAR Scan", systemImage: "camera.viewfinder")
                }

                if let meshDTO = appState.currentMesh {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Vertices: \(meshDTO.vertices.count)", systemImage: "cube")
                                .font(.caption)
                            Spacer()
                            Label("Triangles: \(meshDTO.triangleCount)", systemImage: "triangle")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        // Mesh quality info
                        let boundaryInfo = meshDTO.analyzeBoundaries()
                        HStack {
                            if boundaryInfo.isWatertight {
                                Label("Watertight", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("\(boundaryInfo.holeCount) hole\(boundaryInfo.holeCount == 1 ? "" : "s")", systemImage: "circle.dashed")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            if !boundaryInfo.isWatertight {
                                Text("\(boundaryInfo.boundaryEdges.count) boundary edges")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

            case .manual:
                VStack(alignment: .leading, spacing: 10) {
                    dimensionField("Width (W)", value: $appState.manualWidthMillimeters)
                    dimensionField("Depth (D)", value: $appState.manualDepthMillimeters)
                    dimensionField("Height (H)", value: $appState.manualHeightMillimeters)
                    Text("Enter object dimensions (10-10,000mm). Ease is added during pattern generation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("1. Input")
        }
    }
    
    private var processingSection: some View {
        Section {
            NavigationLink {
                if let mesh = appState.currentMesh {
                    MeshProcessingView(
                        mesh: mesh,
                        processedMesh: $appState.processedMesh,
                        options: $appState.processingOptions
                    )
                }
            } label: {
                HStack {
                    Label("Clean Up Mesh", systemImage: "wand.and.rays")
                    Spacer()
                    if appState.hasProcessedMesh {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .disabled(appState.currentMesh == nil)

            if appState.hasProcessedMesh, let processed = appState.processedMesh {
                HStack {
                    Text("Using processed mesh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(processed.triangleCount) triangles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("1b. Mesh Cleanup (Optional)")
        } footer: {
            Text("Fill holes, remove floor, and isolate your object")
        }
    }

    private var calibrationSection: some View {
        Section {
            NavigationLink {
                CalibrationView(
                    mesh: appState.effectiveMesh,
                    calibrationData: $appState.calibrationData
                )
            } label: {
                Label("Set Real-World Scale", systemImage: "ruler")
            }
            .disabled(appState.inputMode != .scan || appState.effectiveMesh == nil)

            if appState.calibrationData.isComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Scale: \(String(format: "%.3f", appState.calibrationData.scaleFactor))")
                        .font(.caption)
                }
            }
        } header: {
            Text("2. Calibration")
        } footer: {
            if appState.inputMode == .manual {
                Text("Not required for Manual Dimensions.")
            }
        }
    }
    
    private var segmentationSection: some View {
        Section {
            Picker("Pattern Type", selection: $appState.patternMode) {
                ForEach(PatternMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .disabled(appState.inputMode == .manual)
            .onChange(of: appState.patternMode) { _, newMode in
                if newMode == .fitted {
                    showFittedModeWarning = true
                }
            }

            switch appState.patternMode {
            case .fitted:
                Picker("Resolution", selection: $appState.selectedResolution) {
                    ForEach(SegmentationResolution.allCases, id: \.self) { resolution in
                        Text(resolution.rawValue).tag(resolution)
                    }
                }
                .pickerStyle(.menu)

                NavigationLink {
                    SegmentationPreview(
                        mesh: appState.effectiveMesh,
                        resolution: appState.selectedResolution,
                        panels: $appState.currentPanels
                    )
                } label: {
                    Label("Preview Segmentation", systemImage: "square.grid.3x3")
                }
                .disabled(appState.effectiveMesh == nil)
            case .slipcover:
                Picker("Top", selection: $appState.slipcoverTopStyle) {
                    ForEach(SlipcoverTopStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ease")
                        Spacer()
                        Text("\(Int(appState.slipcoverEaseMillimeters))mm")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $appState.slipcoverEaseMillimeters, in: 0...200, step: 5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Seam Allowance")
                        Spacer()
                        Text("\(Int(appState.slipcoverSeamAllowanceMillimeters))mm")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $appState.slipcoverSeamAllowanceMillimeters, in: 3...50, step: 1)
                }

                Stepper("Segments per side: \(appState.slipcoverSegmentsPerSide)", value: $appState.slipcoverSegmentsPerSide, in: 1...16)
                Stepper("Vertical segments: \(appState.slipcoverVerticalSegments)", value: $appState.slipcoverVerticalSegments, in: 1...16)

                Picker("Panels", selection: $appState.slipcoverPanelization) {
                    ForEach(SlipcoverPanelization.allCases, id: \.self) { panelization in
                        Text(panelization.rawValue).tag(panelization)
                    }
                }
                .pickerStyle(.segmented)
            }
        } header: {
            Text("3. Panel Configuration")
        } footer: {
            switch appState.patternMode {
            case .fitted:
                Text("Higher resolution creates more panels for better fit")
            case .slipcover:
                Text("Slipcover patterns are robust and gravity-based (bottom-open)")
            }
        }
    }
    
    private var exportSection: some View {
        Section {
            Button(action: generatePattern) {
                if isGeneratingPattern {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Generating...")
                    }
                } else {
                    Label("Generate Pattern", systemImage: "scissors")
                }
            }
            .disabled(!appState.canGeneratePattern || isGeneratingPattern)
            
            if appState.flattenedPanels != nil {
                NavigationLink {
                    ExportView(flattenedPanels: appState.flattenedPanels)
                } label: {
                    Label("Export Pattern", systemImage: "square.and.arrow.up")
                }
            }
        } header: {
            Text("4. Generate Pattern")
        }
    }
    
    private var helpSection: some View {
        Section {
            Button(action: { showingHelp = true }) {
                Label("How to Use", systemImage: "questionmark.circle")
            }
        }
    }
    
    // MARK: - Helper Views

    private func dimensionField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("mm", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                #if canImport(UIKit)
                .keyboardType(.decimalPad)
                #endif
                .frame(minWidth: 80)
                .onChange(of: value.wrappedValue) { _, newValue in
                    // Clamp to valid range: 10-10,000mm
                    let clamped = min(max(newValue, 10), 10000)
                    if clamped != newValue {
                        value.wrappedValue = clamped
                    }
                }
            Text("mm")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func generatePattern() {
        guard appState.canGeneratePattern else { return }

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
                        appState.showPatternReady = true
                        isGeneratingPattern = false
                        hapticService?.success()
                    }
                case .slipcover:
                    // Capture values from @MainActor state before background work
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

                    // Run synchronous generation off main actor to avoid UI blocking
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
                        appState.showPatternReady = true
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
}
