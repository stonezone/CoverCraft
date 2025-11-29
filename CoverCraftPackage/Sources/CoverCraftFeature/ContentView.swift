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
    
    @State private var appState = AppState()
    @State private var showingScanner = false
    @State private var showingHelp = false
    @State private var isGeneratingPattern = false
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            List {
                scanSection
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
        }
    }
    
    // MARK: - Sections
    
    private var scanSection: some View {
        Section {
            Button(action: { showingScanner = true }) {
                Label("Start LiDAR Scan", systemImage: "camera.viewfinder")
            }
            
            if let meshDTO = appState.currentMesh {
                HStack {
                    Label("Vertices: \(meshDTO.vertices.count)", systemImage: "cube")
                        .font(.caption)
                    Spacer()
                    Label("Triangles: \(meshDTO.triangleCount)", systemImage: "triangle")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        } header: {
            Text("1. Scan Object")
        }
    }
    
    private var calibrationSection: some View {
        Section {
            NavigationLink {
                CalibrationView(
                    mesh: appState.currentMesh,
                    calibrationData: appState.calibrationData
                )
            } label: {
                Label("Set Real-World Scale", systemImage: "ruler")
            }
            .disabled(appState.currentMesh == nil)
            
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
                    mesh: appState.currentMesh,
                    resolution: appState.selectedResolution,
                    panels: $appState.currentPanels
                )
            } label: {
                Label("Preview Segmentation", systemImage: "square.grid.3x3")
            }
            .disabled(appState.currentMesh == nil)
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
        
        isGeneratingPattern = true
        
        Task {
            do {
                // Generate pattern using injected services
                let serviceContainer = DefaultDependencyContainer.shared
                let segmenter = try serviceContainer.requireService(MeshSegmentationService.self)
                let flattener = try serviceContainer.requireService(PatternFlatteningService.self)
                
                let scaledMesh = appState.currentMesh!.scaled(by: appState.calibrationData.scaleFactor)
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
                    // TODO: Show error alert to user
                    print("Pattern generation failed: \(error.localizedDescription)")
                }
            }
        }
    }
}


