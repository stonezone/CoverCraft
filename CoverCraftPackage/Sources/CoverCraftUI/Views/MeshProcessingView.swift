import SwiftUI
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct MeshProcessingView: View {
    let mesh: MeshDTO
    @Binding var processedMesh: MeshDTO?
    @Binding var options: MeshProcessingOptions

    @State private var isProcessing = false
    @State private var lastResult: MeshProcessingResult?
    @State private var previewBoundaryInfo: MeshBoundaryInfo?
    @Environment(\.dismiss) private var dismiss

    public init(
        mesh: MeshDTO,
        processedMesh: Binding<MeshDTO?>,
        options: Binding<MeshProcessingOptions>
    ) {
        self.mesh = mesh
        self._processedMesh = processedMesh
        self._options = options
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                meshSummaryCard
                holeFillingCard
                planeCroppingCard
                fragmentRemovalCard
                actionCard

                if let lastResult {
                    resultCard(lastResult)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(CoverCraftScreenBackground().ignoresSafeArea())
        .navigationTitle("Mesh Processing")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            previewBoundaryInfo = mesh.analyzeBoundaries()
        }
    }

    private var heroCard: some View {
        CoverCraftCard(tone: hasAnyOptionEnabled ? .accent : .neutral) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    CoverCraftStatusChip(
                        hasAnyOptionEnabled ? "Isolation configured" : "Review needed",
                        systemImage: hasAnyOptionEnabled ? "slider.horizontal.3" : "wand.and.stars",
                        tone: hasAnyOptionEnabled ? .accent : .warning
                    )

                    Text("Isolate the intended object before calibration or segmentation.")
                        .font(.title3.weight(.semibold))

                    Text("Raw LiDAR reconstruction often includes floor, wall, table, or nearby objects. Use this step to remove geometry that should not become fabric.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 58, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                    )
            }
        }
    }

    private var meshSummaryCard: some View {
        CoverCraftCard(tone: .neutral) {
            CoverCraftSectionHeading(
                step: "Mesh",
                title: "Scan Summary",
                subtitle: "Review the raw mesh before applying cleanup operations.",
                tone: .neutral
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                CoverCraftMetricTile(
                    title: "Vertices",
                    value: "\(mesh.vertices.count)",
                    subtitle: "Captured points",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    tone: .accent
                )
                CoverCraftMetricTile(
                    title: "Triangles",
                    value: "\(mesh.triangleCount)",
                    subtitle: "Surface density",
                    systemImage: "triangle",
                    tone: .accent
                )

                if let info = previewBoundaryInfo {
                    CoverCraftMetricTile(
                        title: "Seal",
                        value: info.isWatertight ? "Watertight" : "\(info.holeCount) holes",
                        subtitle: info.isWatertight ? "No hole filling needed" : "Gap repair is available below",
                        systemImage: info.isWatertight ? "checkmark.seal.fill" : "circle.dashed",
                        tone: info.isWatertight ? .success : .warning
                    )
                    CoverCraftMetricTile(
                        title: "Boundary edges",
                        value: "\(info.boundaryEdges.count)",
                        subtitle: "Open-edge count",
                        systemImage: "square.dashed",
                        tone: info.isWatertight ? .neutral : .warning
                    )
                }
            }
        }
    }

    private var holeFillingCard: some View {
        CoverCraftCard(tone: options.enableHoleFilling ? .accent : .neutral) {
            CleanupToggleHeader(
                title: "Fill Small Holes",
                subtitle: "Automatically close small gaps left by incomplete capture.",
                systemImage: "circle.dashed",
                isEnabled: $options.enableHoleFilling,
                tone: options.enableHoleFilling ? .accent : .neutral
            )

            if options.enableHoleFilling {
                ValueSliderPanel(
                    title: "Max hole size",
                    valueLabel: "\(options.maxHoleEdges) edges",
                    footnote: "Higher values repair larger gaps, but can overreach on complex shapes."
                ) {
                    Slider(
                        value: Binding(
                            get: { Float(options.maxHoleEdges) },
                            set: { options.maxHoleEdges = Int($0) }
                        ),
                        in: 3...50,
                        step: 1
                    )
                    .tint(.blue)
                }
            }
        }
    }

    private var planeCroppingCard: some View {
        CoverCraftCard(tone: options.enablePlaneCropping ? .warning : .neutral) {
            CleanupToggleHeader(
                title: "Remove Floor or Ceiling",
                subtitle: "Crop a large support plane when the scan includes the room or table surface.",
                systemImage: "square.split.bottomrightquarter",
                isEnabled: $options.enablePlaneCropping,
                tone: options.enablePlaneCropping ? .warning : .neutral
            )

            if options.enablePlaneCropping {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Direction", selection: $options.cropDirection) {
                        ForEach(CropDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)

                    ValueSliderPanel(
                        title: "Cut height",
                        valueLabel: "\(Int(options.cropPlaneHeightFraction * 100))% from bottom",
                        footnote: "Keep the crop conservative so it removes only the support surface."
                    ) {
                        Slider(
                            value: $options.cropPlaneHeightFraction,
                            in: 0...0.5,
                            step: 0.01
                        )
                        .tint(.orange)
                    }
                }
            }
        }
    }

    private var fragmentRemovalCard: some View {
        CoverCraftCard(tone: options.enableComponentIsolation ? .warning : .neutral) {
            CleanupToggleHeader(
                title: "Remove Fragments",
                subtitle: "Keep the main object and discard floating scraps or background shards.",
                systemImage: "square.on.square.dashed",
                isEnabled: $options.enableComponentIsolation,
                tone: options.enableComponentIsolation ? .warning : .neutral
            )

            if options.enableComponentIsolation {
                ValueSliderPanel(
                    title: "Minimum fragment size",
                    valueLabel: "\(options.minComponentTriangles) triangles",
                    footnote: "Pieces smaller than this threshold will be removed."
                ) {
                    Slider(
                        value: Binding(
                            get: { Float(options.minComponentTriangles) },
                            set: { options.minComponentTriangles = Int($0) }
                        ),
                        in: 10...500,
                        step: 10
                    )
                    .tint(.orange)
                }
            }
        }
    }

    private var actionCard: some View {
        CoverCraftCard(tone: hasAnyOptionEnabled ? .accent : .neutral) {
            CoverCraftSectionHeading(
                step: "Apply",
                title: "Apply Isolation",
                subtitle: "Apply the selected mesh fixes, then use the processed object mesh for review, calibration, and generation.",
                tone: hasAnyOptionEnabled ? .accent : .neutral
            )

            Button(action: processNow) {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Processing...")
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Label("Apply Processing", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .disabled(isProcessing || !hasAnyOptionEnabled)

            HStack(spacing: 12) {
                Button("Use Recommended") {
                    options = .recommended()
                }
                .buttonStyle(.bordered)

                Button("Reset All") {
                    options = .disabled()
                    lastResult = nil
                    processedMesh = nil
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var hasAnyOptionEnabled: Bool {
        options.enableHoleFilling || options.enablePlaneCropping || options.enableComponentIsolation
    }

    private func resultCard(_ result: MeshProcessingResult) -> some View {
        CoverCraftCard(tone: .success) {
            CoverCraftSectionHeading(
                step: "Done",
                title: "Processing Complete",
                subtitle: "The cleaned mesh is now the active source for calibration and generation.",
                statusTitle: "Updated",
                statusImage: "checkmark.circle.fill",
                tone: .success
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                CoverCraftMetricTile(
                    title: "Before",
                    value: "\(result.originalTriangleCount)",
                    subtitle: "Triangles",
                    systemImage: "triangle",
                    tone: .neutral
                )
                CoverCraftMetricTile(
                    title: "After",
                    value: "\(result.finalTriangleCount)",
                    subtitle: "Triangles",
                    systemImage: "checkmark.circle.fill",
                    tone: .success
                )
            }

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    private func processNow() {
        isProcessing = true

        let meshToProcess = mesh
        let processingOptions = options

        Task.detached {
            let result = meshToProcess.processed(with: processingOptions)

            await MainActor.run {
                lastResult = result
                processedMesh = result.mesh
                previewBoundaryInfo = result.mesh.analyzeBoundaries()
                isProcessing = false
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct CleanupToggleHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isEnabled: Bool
    let tone: CoverCraftTone

    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tone == .warning ? Color.orange : Color.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct ValueSliderPanel<Content: View>: View {
    let title: String
    let valueLabel: String
    let footnote: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(valueLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            content()

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
