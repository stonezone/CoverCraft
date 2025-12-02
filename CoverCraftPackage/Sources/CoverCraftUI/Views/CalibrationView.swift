import SwiftUI
import simd
import CoverCraftDTO
import CoverCraftCore

#if canImport(UIKit)
import UIKit
#endif

/// Calibration method options for determining reference points
enum CalibrationMethod: String, CaseIterable, Identifiable {
    case diagonal = "Bounding Box Diagonal"
    case xAxis = "X-Axis (Width)"
    case yAxis = "Y-Axis (Height)"
    case zAxis = "Z-Axis (Depth)"
    case longestAxis = "Longest Axis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .diagonal: return "cube.transparent"
        case .xAxis: return "arrow.left.and.right"
        case .yAxis: return "arrow.up.and.down"
        case .zAxis: return "arrow.forward"
        case .longestAxis: return "ruler"
        }
    }

    var description: String {
        switch self {
        case .diagonal: return "Corner to corner (longest possible)"
        case .xAxis: return "Left to right extent"
        case .yAxis: return "Bottom to top extent"
        case .zAxis: return "Front to back extent"
        case .longestAxis: return "Automatically picks longest dimension"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct CalibrationView: View {
    let mesh: MeshDTO?
    @Binding var calibrationData: CalibrationDTO

    @State private var realWorldDistanceText: String = "1.0"
    @State private var selectedMethod: CalibrationMethod = .longestAxis
    @State private var computedMeshDistance: Float = 0.0
    @Environment(\.dismiss) private var dismiss

    public init(mesh: MeshDTO?, calibrationData: Binding<CalibrationDTO>) {
        self.mesh = mesh
        self._calibrationData = calibrationData
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                if let mesh = mesh {
                    meshInfoSection(mesh: mesh)
                    calibrationMethodSection
                    distanceInputSection
                    applyCalibrationButton

                    if calibrationData.isComplete {
                        calibrationCompleteSection
                    }
                } else {
                    noMeshSection
                }

                Spacer(minLength: 20)
                resetButton
            }
            .padding()
        }
        .navigationTitle("Calibration")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if calibrationData.realWorldDistance > 0 {
                realWorldDistanceText = String(format: "%.2f", calibrationData.realWorldDistance)
            }
            updateComputedDistance()
        }
        .onChange(of: selectedMethod) { _, _ in
            updateComputedDistance()
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Calibration")
                .font(.largeTitle)
                .bold()

            Text("Select a reference dimension and enter its real-world measurement.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }

    private func meshInfoSection(mesh: MeshDTO) -> some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))

                VStack(spacing: 8) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)

                    Text("\(mesh.vertices.count) vertices")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bounds = mesh.boundingBox() {
                        let size = bounds.max - bounds.min
                        VStack(spacing: 4) {
                            Text("Mesh Dimensions (units)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 16) {
                                dimensionLabel("X", value: size.x, color: .red)
                                dimensionLabel("Y", value: size.y, color: .green)
                                dimensionLabel("Z", value: size.z, color: .blue)
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(height: 140)
        }
    }

    private func dimensionLabel(_ axis: String, value: Float, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(axis)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(String(format: "%.3f", value))
                .font(.system(.caption, design: .monospaced))
        }
    }

    private var calibrationMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reference Dimension")
                .font(.headline)

            ForEach(CalibrationMethod.allCases) { method in
                methodRow(method)
            }

            if computedMeshDistance > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Selected dimension: \(String(format: "%.4f", computedMeshDistance)) mesh units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    private func methodRow(_ method: CalibrationMethod) -> some View {
        Button {
            selectedMethod = method
        } label: {
            HStack {
                Image(systemName: method.icon)
                    .frame(width: 24)
                    .foregroundColor(selectedMethod == method ? .white : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(method.description)
                        .font(.caption2)
                        .foregroundColor(selectedMethod == method ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if selectedMethod == method {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedMethod == method ? Color.blue : Color.gray.opacity(0.1))
            )
            .foregroundColor(selectedMethod == method ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var distanceInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Real-World Distance")
                .font(.headline)

            HStack {
                TextField("Distance", text: $realWorldDistanceText)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                Text("meters")
                    .foregroundColor(.secondary)
            }

            Text("Enter the actual measurement of the selected dimension")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var applyCalibrationButton: some View {
        Button(action: applyCalibration) {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("Apply Calibration")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(mesh == nil || realWorldDistanceText.isEmpty)
    }

    private var calibrationCompleteSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Calibration Applied")
                    .font(.headline)
                    .foregroundColor(.green)
            }

            VStack(spacing: 4) {
                Text("Scale factor: \(String(format: "%.6f", calibrationData.scaleFactor))")
                    .font(.subheadline)
                Text("Mesh distance: \(String(format: "%.4f", calibrationData.meshDistance)) units")
                    .font(.caption)
                Text("Real distance: \(String(format: "%.3f", calibrationData.realWorldDistance)) meters")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
        )
    }

    private var noMeshSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("No mesh available for calibration")
                .foregroundColor(.secondary)
            Text("Scan an object first to enable calibration")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var resetButton: some View {
        Button("Reset Calibration") {
            calibrationData = CalibrationDTO.empty()
            realWorldDistanceText = "1.0"
            selectedMethod = .longestAxis
        }
        .buttonStyle(.bordered)
        .disabled(mesh == nil)
    }

    // MARK: - Calibration Logic

    private func updateComputedDistance() {
        guard let mesh = mesh, let bounds = mesh.boundingBox() else {
            computedMeshDistance = 0
            return
        }

        let size = bounds.max - bounds.min

        switch selectedMethod {
        case .diagonal:
            computedMeshDistance = simd_length(size)
        case .xAxis:
            computedMeshDistance = size.x
        case .yAxis:
            computedMeshDistance = size.y
        case .zAxis:
            computedMeshDistance = size.z
        case .longestAxis:
            computedMeshDistance = max(size.x, max(size.y, size.z))
        }
    }

    private func applyCalibration() {
        guard let mesh = mesh, let bounds = mesh.boundingBox() else { return }

        let size = bounds.max - bounds.min
        let point1: SIMD3<Float>
        let point2: SIMD3<Float>

        switch selectedMethod {
        case .diagonal:
            point1 = bounds.min
            point2 = bounds.max
        case .xAxis:
            point1 = SIMD3<Float>(bounds.min.x, (bounds.min.y + bounds.max.y) / 2, (bounds.min.z + bounds.max.z) / 2)
            point2 = SIMD3<Float>(bounds.max.x, (bounds.min.y + bounds.max.y) / 2, (bounds.min.z + bounds.max.z) / 2)
        case .yAxis:
            point1 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, bounds.min.y, (bounds.min.z + bounds.max.z) / 2)
            point2 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, bounds.max.y, (bounds.min.z + bounds.max.z) / 2)
        case .zAxis:
            point1 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, (bounds.min.y + bounds.max.y) / 2, bounds.min.z)
            point2 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, (bounds.min.y + bounds.max.y) / 2, bounds.max.z)
        case .longestAxis:
            // Pick the longest axis
            if size.x >= size.y && size.x >= size.z {
                point1 = SIMD3<Float>(bounds.min.x, (bounds.min.y + bounds.max.y) / 2, (bounds.min.z + bounds.max.z) / 2)
                point2 = SIMD3<Float>(bounds.max.x, (bounds.min.y + bounds.max.y) / 2, (bounds.min.z + bounds.max.z) / 2)
            } else if size.y >= size.x && size.y >= size.z {
                point1 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, bounds.min.y, (bounds.min.z + bounds.max.z) / 2)
                point2 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, bounds.max.y, (bounds.min.z + bounds.max.z) / 2)
            } else {
                point1 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, (bounds.min.y + bounds.max.y) / 2, bounds.min.z)
                point2 = SIMD3<Float>((bounds.min.x + bounds.max.x) / 2, (bounds.min.y + bounds.max.y) / 2, bounds.max.z)
            }
        }

        let distance = Double(realWorldDistanceText) ?? 1.0

        calibrationData = CalibrationDTO.with(
            firstPoint: point1,
            secondPoint: point2,
            realWorldDistance: distance
        )
    }
}
