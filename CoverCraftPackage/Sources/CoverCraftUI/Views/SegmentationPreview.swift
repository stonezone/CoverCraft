import SwiftUI
import CoverCraftDTO
import CoverCraftCore
import CoverCraftSegmentation

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct SegmentationPreview: View {
    @Environment(\.dependencyContainer) private var container

    let mesh: MeshDTO?
    let resolution: SegmentationResolution
    @Binding var panels: [PanelDTO]?

    @State private var isSegmenting = false
    @State private var errorMessage: String?

    public init(mesh: MeshDTO?, resolution: SegmentationResolution, panels: Binding<[PanelDTO]?>) {
        self.mesh = mesh
        self.resolution = resolution
        self._panels = panels
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard

                if mesh != nil {
                    resolutionCard
                    previewCard
                    actionCard

                    if let panels {
                        panelListCard(panels)
                    }
                } else {
                    unavailableCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(CoverCraftScreenBackground().ignoresSafeArea())
        .navigationTitle("Segmentation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var heroCard: some View {
        CoverCraftCard(tone: panels == nil ? .warning : .success) {
            CoverCraftSectionHeading(
                step: "Preview",
                title: "Fitted Panel Estimate",
                subtitle: "Run segmentation before flattening so you can check how many panels the fitted path will create.",
                statusTitle: panels == nil ? "Not generated" : "Preview ready",
                statusImage: panels == nil ? "square.grid.3x3" : "checkmark.seal.fill",
                tone: panels == nil ? .warning : .success
            )
        }
    }

    private var resolutionCard: some View {
        CoverCraftCard(tone: .warning) {
            CoverCraftSectionHeading(
                step: "Resolution",
                title: "Current Target",
                subtitle: "Higher resolution increases panel count and seam complexity.",
                statusTitle: resolution.rawValue,
                statusImage: "dial.medium",
                tone: .warning
            )

            CoverCraftMetricTile(
                title: "Target panels",
                value: "\(resolution.targetPanelCount)",
                subtitle: "Approximate before flattening",
                systemImage: "square.grid.3x3.fill",
                tone: .warning
            )
        }
    }

    private var previewCard: some View {
        CoverCraftCard(tone: panels == nil ? .neutral : .success) {
            CoverCraftSectionHeading(
                step: "Canvas",
                title: "Segmentation State",
                subtitle: "This view only reports status and generated panel colors.",
                tone: panels == nil ? .neutral : .success
            )

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 280)

                if isSegmenting {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.4)
                        Text("Segmenting mesh...")
                            .font(.headline)
                    }
                } else if let panels {
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(.green)

                        Text("\(panels.count) panels generated")
                            .font(.headline)
                            .foregroundStyle(.green)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(32), spacing: 6), count: min(max(panels.count, 1), 8)),
                            spacing: 6
                        ) {
                            ForEach(Array(panels.prefix(8).enumerated()), id: \.offset) { index, panel in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(
                                        red: panel.color.red,
                                        green: panel.color.green,
                                        blue: panel.color.blue,
                                        opacity: panel.color.alpha
                                    ))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 54))
                            .foregroundStyle(.blue)

                        Text("Run preview to estimate fitted panels")
                            .font(.headline)

                        Text("This does not export anything. It only previews the segmentation output.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    private var actionCard: some View {
        CoverCraftCard(tone: errorMessage == nil ? .accent : .warning) {
            CoverCraftSectionHeading(
                step: "Run",
                title: "Generate Preview",
                subtitle: "The segmentation service will split the scaled mesh into the current target panel count.",
                tone: errorMessage == nil ? .accent : .warning
            )

            Button(action: generatePreview) {
                if isSegmenting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Segmenting...")
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Label("Generate Preview", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .disabled(isSegmenting)

            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
    }

    private func panelListCard(_ panels: [PanelDTO]) -> some View {
        CoverCraftCard(tone: .success) {
            CoverCraftSectionHeading(
                step: "Panels",
                title: "Generated Pieces",
                subtitle: "Use this list to sanity-check how aggressive the segmentation became.",
                statusTitle: "\(panels.count)",
                statusImage: "list.number",
                tone: .success
            )

            VStack(spacing: 10) {
                ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(
                                red: panel.color.red,
                                green: panel.color.green,
                                blue: panel.color.blue,
                                opacity: panel.color.alpha
                            ))
                            .frame(width: 18, height: 18)

                        Text("Panel \(index + 1)")
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text("\(panel.vertexIndices.count) vertices")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.45))
                    )
                }
            }
        }
    }

    private var unavailableCard: some View {
        CoverCraftCard(tone: .warning) {
            CoverCraftSectionHeading(
                step: "Unavailable",
                title: "No Mesh Available",
                subtitle: "Capture and calibrate a scan first. Fitted preview cannot run without mesh geometry.",
                statusTitle: "Blocked",
                statusImage: "exclamationmark.triangle.fill",
                tone: .warning
            )
        }
    }

    private func generatePreview() {
        guard let meshToSegment = mesh else {
            errorMessage = "No mesh available for segmentation"
            return
        }

        guard let segmenter = container.resolve(MeshSegmentationService.self) else {
            errorMessage = "Segmentation service not available"
            return
        }

        isSegmenting = true
        errorMessage = nil

        let targetPanelCount = resolution.targetPanelCount
        Task {
            do {
                let generatedPanels = try await Task.detached {
                    try await segmenter.segmentMesh(
                        meshToSegment,
                        targetPanelCount: targetPanelCount
                    )
                }.value

                panels = generatedPanels
                isSegmenting = false
            } catch {
                errorMessage = error.localizedDescription
                isSegmenting = false
            }
        }
    }
}
