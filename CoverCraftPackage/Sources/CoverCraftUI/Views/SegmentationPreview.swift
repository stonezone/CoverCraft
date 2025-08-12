import SwiftUI

import SwiftUI
import CoverCraftDTO
import CoverCraftCore
import CoverCraftSegmentation

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct SegmentationPreview: View {
    let mesh: Mesh?
    let resolution: SegmentationResolution
    @Binding var panels: [Panel]?
    
    @State private var isSegmenting = false
    @State private var errorMessage: String?
    
    public init(mesh: Mesh?, resolution: SegmentationResolution, panels: Binding<[Panel]?>) {
        self.mesh = mesh
        self.resolution = resolution
        self._panels = panels
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Segmentation Preview")
                .font(.largeTitle)
                .bold()
            
            Text("Preview how the mesh will be segmented into panels.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Resolution info
            VStack(spacing: 8) {
                Text("Resolution: \(resolution.rawValue)")
                    .font(.headline)
                
                Text("Target panels: \(resolution.targetPanelCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            if let mesh = mesh {
                // Segmentation visualization
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 300)
                    
                    if isSegmenting {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Segmenting mesh...")
                                .font(.headline)
                                .padding(.top)
                        }
                    } else if let panels = panels {
                        VStack {
                            Image(systemName: "square.grid.3x3")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("\(panels.count) panels generated")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            // Panel colors preview
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30)), count: min(panels.count, 8)), spacing: 4) {
                                ForEach(Array(panels.prefix(8).enumerated()), id: \.offset) { index, panel in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: panel.color.red, green: panel.color.green, blue: panel.color.blue, opacity: panel.color.alpha))
                                        .frame(width: 30, height: 30)
                                }
                                
                                if panels.count > 8 {
                                    Text("+\(panels.count - 8)")
                                        .font(.caption)
                                        .frame(width: 30, height: 30)
                                        .background(.gray.opacity(0.3))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        VStack {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Tap 'Generate Preview' to segment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Generate preview button
                Button(action: generatePreview) {
                    if isSegmenting {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Segmenting...")
                        }
                    } else {
                        Text("Generate Preview")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSegmenting)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Panel details
                if let panels = panels {
                    List {
                        ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: panel.color.red, green: panel.color.green, blue: panel.color.blue, opacity: panel.color.alpha))
                                    .frame(width: 20, height: 20)
                                
                                VStack(alignment: .leading) {
                                    Text("Panel \(index + 1)")
                                        .font(.headline)
                                    Text("\(panel.vertexIndices.count) vertices")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 200)
                }
                
            } else {
                Text("No mesh available for segmentation")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Segmentation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func generatePreview() {
        guard let mesh = mesh else { return }
        
        isSegmenting = true
        errorMessage = nil
        
        Task {
            do {
                let segmenter = DefaultMeshSegmentationService()
                let generatedPanels = try await segmenter.segmentMesh(
                    mesh,
                    targetPanelCount: resolution.targetPanelCount
                )
                
                await MainActor.run {
                    panels = generatedPanels
                    isSegmenting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSegmenting = false
                }
            }
        }
    }
}