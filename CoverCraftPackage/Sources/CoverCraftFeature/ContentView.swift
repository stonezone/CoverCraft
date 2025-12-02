import SwiftUI
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
    // MARK: - State
    
    @Environment(\.dependencyContainer) private var container
    
    // MARK: - Dependencies
    
    private var arService: ARScanningService? {
        container.resolve(ARScanningService.self)
    }
    
    private var segmentationService: MeshSegmentationService? {
        container.resolve(MeshSegmentationService.self)
    }
    
    private var flatteningService: PatternFlatteningService? {
        container.resolve(PatternFlatteningService.self)
    }
    
    @State private var appState = AppState()
    @State private var showingScanner = false
    @State private var showingHelp = false
    @State private var isGeneratingPattern = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
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
                    // Navigate to export view
                }
                Button("OK", role: .cancel) { }
            }
            .alert("Pattern Generation Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    // MARK: - Sections
    
    private var scanSection: some View {
        Section {
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
        } header: {
            Text("1. Scan Object")
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
            .disabled(appState.effectiveMesh == nil)

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
        }
    }
    
    private var segmentationSection: some View {
        Section {
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
        } header: {
            Text("3. Panel Configuration")
        } footer: {
            Text("Higher resolution creates more panels for better fit")
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
    
    // MARK: - Actions
    
    private func generatePattern() {
        guard appState.canGeneratePattern else { return }

        guard
            let segmenter = segmentationService,
            let flattener = flatteningService,
            let meshToUse = appState.effectiveMesh
        else {
            print("CRITICAL: Required services not registered in dependency container")
            return
        }

        isGeneratingPattern = true

        Task {
            do {
                let scaledMesh = meshToUse.scaled(by: appState.calibrationData.scaleFactor)
                let panels = try await segmenter.segmentMesh(
                    scaledMesh,
                    targetPanelCount: appState.selectedResolution.targetPanelCount
                )
                
                let flattenedPanels = try await flattener.flattenPanels(panels, from: scaledMesh)
                
                await MainActor.run {
                    appState.currentPanels = panels
                    appState.flattenedPanels = flattenedPanels
                    appState.showPatternReady = true
                    isGeneratingPattern = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingPattern = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

