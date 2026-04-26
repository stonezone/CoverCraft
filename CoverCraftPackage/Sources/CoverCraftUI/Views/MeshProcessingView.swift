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
                boundsCroppingCard
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

    private var boundsCroppingCard: some View {
        CoverCraftCard(tone: options.enableBoundsCropping ? .accent : .neutral) {
            CleanupToggleHeader(
                title: "Trim to Object Box",
                subtitle: "Remove side, front, back, or top geometry that belongs to the room instead of the object.",
                systemImage: "crop",
                isEnabled: $options.enableBoundsCropping,
                tone: options.enableBoundsCropping ? .accent : .neutral
            )

            if options.enableBoundsCropping {
                VStack(alignment: .leading, spacing: 12) {
                    CoverCraftStatusChip(
                        "Keeps triangle centers inside the selected box",
                        systemImage: "cube.transparent",
                        tone: .neutral
                    )

                    CropRangeSliderPanel(
                        title: "Width crop",
                        minLabel: "Left \(percentLabel(options.cropBounds.minX))",
                        maxLabel: "Right \(percentLabel(options.cropBounds.maxX))",
                        footnote: "Raise Left or lower Right to remove side clutter.",
                        minValue: cropMinXBinding,
                        maxValue: cropMaxXBinding,
                        tint: .blue
                    )

                    CropRangeSliderPanel(
                        title: "Height crop",
                        minLabel: "Bottom \(percentLabel(options.cropBounds.minY))",
                        maxLabel: "Top \(percentLabel(options.cropBounds.maxY))",
                        footnote: "Raise Bottom when the table or floor is still attached.",
                        minValue: cropMinYBinding,
                        maxValue: cropMaxYBinding,
                        tint: .orange
                    )

                    CropRangeSliderPanel(
                        title: "Depth crop",
                        minLabel: "Front \(percentLabel(options.cropBounds.minZ))",
                        maxLabel: "Back \(percentLabel(options.cropBounds.maxZ))",
                        footnote: "Use this when LiDAR captured background behind the target.",
                        minValue: cropMinZBinding,
                        maxValue: cropMaxZBinding,
                        tint: .blue
                    )

                    Button("Reset Crop Box") {
                        options.cropBounds = .full
                    }
                    .buttonStyle(.bordered)
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
        options.enableHoleFilling || options.enablePlaneCropping || options.enableBoundsCropping || options.enableComponentIsolation
    }

    private func resultCard(_ result: MeshProcessingResult) -> some View {
        let isUsable = result.mesh.isValid

        return CoverCraftCard(tone: isUsable ? .success : .warning) {
            CoverCraftSectionHeading(
                step: "Done",
                title: isUsable ? "Processing Complete" : "Processing Removed Mesh",
                subtitle: isUsable ? "The cleaned mesh is now the active source for calibration and generation." : "The selected crop removed all usable triangles. Loosen the crop bounds and apply again.",
                statusTitle: isUsable ? "Updated" : "Not Applied",
                statusImage: isUsable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                tone: isUsable ? .success : .warning
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
                    systemImage: isUsable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    tone: isUsable ? .success : .warning
                )
            }

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(isUsable ? "Done" : "Keep Editing") {
                if isUsable {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isUsable ? .green : .orange)
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
                processedMesh = result.mesh.isValid ? result.mesh : nil
                previewBoundaryInfo = result.mesh.isValid ? result.mesh.analyzeBoundaries() : meshToProcess.analyzeBoundaries()
                isProcessing = false
            }
        }
    }

    private var cropMinXBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.minX },
            set: { updateCropBounds(minX: $0) }
        )
    }

    private var cropMaxXBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.maxX },
            set: { updateCropBounds(maxX: $0) }
        )
    }

    private var cropMinYBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.minY },
            set: { updateCropBounds(minY: $0) }
        )
    }

    private var cropMaxYBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.maxY },
            set: { updateCropBounds(maxY: $0) }
        )
    }

    private var cropMinZBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.minZ },
            set: { updateCropBounds(minZ: $0) }
        )
    }

    private var cropMaxZBinding: Binding<Float> {
        Binding(
            get: { options.cropBounds.maxZ },
            set: { updateCropBounds(maxZ: $0) }
        )
    }

    private func updateCropBounds(
        minX: Float? = nil,
        maxX: Float? = nil,
        minY: Float? = nil,
        maxY: Float? = nil,
        minZ: Float? = nil,
        maxZ: Float? = nil
    ) {
        let minimumSpan: Float = 0.02
        var cropBounds = options.cropBounds

        if let minX {
            cropBounds.minX = min(Self.clamp(minX), max(0, cropBounds.maxX - minimumSpan))
        }
        if let maxX {
            cropBounds.maxX = max(Self.clamp(maxX), min(1, cropBounds.minX + minimumSpan))
        }
        if let minY {
            cropBounds.minY = min(Self.clamp(minY), max(0, cropBounds.maxY - minimumSpan))
        }
        if let maxY {
            cropBounds.maxY = max(Self.clamp(maxY), min(1, cropBounds.minY + minimumSpan))
        }
        if let minZ {
            cropBounds.minZ = min(Self.clamp(minZ), max(0, cropBounds.maxZ - minimumSpan))
        }
        if let maxZ {
            cropBounds.maxZ = max(Self.clamp(maxZ), min(1, cropBounds.minZ + minimumSpan))
        }

        options.cropBounds = cropBounds.normalized
    }

    private func percentLabel(_ value: Float) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func clamp(_ value: Float) -> Float {
        min(max(value, 0), 1)
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

@available(iOS 18.0, macOS 15.0, *)
private struct CropRangeSliderPanel: View {
    let title: String
    let minLabel: String
    let maxLabel: String
    let footnote: String
    @Binding var minValue: Float
    @Binding var maxValue: Float
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(minLabel) / \(maxLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Slider(value: $minValue, in: 0...1, step: 0.01)
                    .tint(tint)
                Slider(value: $maxValue, in: 0...1, step: 0.01)
                    .tint(tint)
            }

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
