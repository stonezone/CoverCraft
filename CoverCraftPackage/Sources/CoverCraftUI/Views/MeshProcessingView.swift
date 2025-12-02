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
            VStack(spacing: 24) {
                headerSection
                meshInfoSection
                holeFillingSectionView
                planeCroppingSectionView
                componentIsolationSectionView
                actionButtons
                if let result = lastResult {
                    resultSection(result)
                }
            }
            .padding()
        }
        .navigationTitle("Mesh Processing")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            previewBoundaryInfo = mesh.analyzeBoundaries()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "wand.and.rays")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("Clean Up Your Scan")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable options below to automatically fix common scanning issues")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Mesh Info

    private var meshInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(mesh.vertices.count)", systemImage: "circle.fill")
                    .font(.caption)
                Text("vertices")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("\(mesh.triangleCount)", systemImage: "triangle.fill")
                    .font(.caption)
                Text("triangles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let info = previewBoundaryInfo {
                HStack {
                    if info.isWatertight {
                        Label("Watertight", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("\(info.holeCount) holes", systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Hole Filling Section

    private var holeFillingSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $options.enableHoleFilling) {
                HStack {
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("Fill Small Holes")
                            .fontWeight(.medium)
                        Text("Automatically close gaps in the mesh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if options.enableHoleFilling {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Max hole size:")
                            .font(.caption)
                        Spacer()
                        Text("\(options.maxHoleEdges) edges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Float(options.maxHoleEdges) },
                            set: { options.maxHoleEdges = Int($0) }
                        ),
                        in: 3...50,
                        step: 1
                    )
                    Text("Larger holes require manual fixing")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(options.enableHoleFilling ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }

    // MARK: - Plane Cropping Section

    private var planeCroppingSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $options.enablePlaneCropping) {
                HStack {
                    Image(systemName: "square.split.bottomrightquarter")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("Remove Floor/Ceiling")
                            .fontWeight(.medium)
                        Text("Crop geometry above or below a plane")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if options.enablePlaneCropping {
                VStack(alignment: .leading, spacing: 12) {
                    // Direction picker
                    Picker("Direction", selection: $options.cropDirection) {
                        ForEach(CropDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Height slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Cut height:")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(options.cropPlaneHeightFraction * 100))% from bottom")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $options.cropPlaneHeightFraction,
                            in: 0...0.5,
                            step: 0.01
                        )
                        Text("Adjust to remove only the unwanted surface")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(options.enablePlaneCropping ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }

    // MARK: - Component Isolation Section

    private var componentIsolationSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $options.enableComponentIsolation) {
                HStack {
                    Image(systemName: "square.on.square.dashed")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("Remove Fragments")
                            .fontWeight(.medium)
                        Text("Keep only the main object, remove floating pieces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if options.enableComponentIsolation {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Min fragment size:")
                            .font(.caption)
                        Spacer()
                        Text("\(options.minComponentTriangles) triangles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Float(options.minComponentTriangles) },
                            set: { options.minComponentTriangles = Int($0) }
                        ),
                        in: 10...500,
                        step: 10
                    )
                    Text("Smaller pieces below this threshold are removed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(options.enableComponentIsolation ? Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: processNow) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isProcessing ? "Processing..." : "Apply Processing")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
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

    // MARK: - Result Section

    private func resultSection(_ result: MeshProcessingResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Processing Complete")
                    .font(.headline)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Before:")
                    Spacer()
                    Text("\(result.originalTriangleCount) triangles")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("After:")
                    Spacer()
                    Text("\(result.finalTriangleCount) triangles")
                        .foregroundColor(.secondary)
                }

                Divider()

                Text(result.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    // MARK: - Actions

    private func processNow() {
        isProcessing = true

        // Capture values for background processing
        let meshToProcess = mesh
        let processingOptions = options

        // Run processing on background thread
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
