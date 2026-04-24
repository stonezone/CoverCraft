import SwiftUI
import simd
import CoverCraftDTO
import CoverCraftCore

#if canImport(UIKit)
import UIKit
#endif

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

    var shortLabel: String {
        switch self {
        case .diagonal: return "Diagonal"
        case .xAxis: return "Width"
        case .yAxis: return "Height"
        case .zAxis: return "Depth"
        case .longestAxis: return "Longest"
        }
    }

    var description: String {
        switch self {
        case .diagonal: return "Corner to corner reference"
        case .xAxis: return "Left to right extent"
        case .yAxis: return "Bottom to top extent"
        case .zAxis: return "Front to back extent"
        case .longestAxis: return "Automatically picks the largest side"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct CalibrationView: View {
    let mesh: MeshDTO?
    @Binding var calibrationData: CalibrationDTO

    @State private var realWorldDistanceText = ""
    @State private var selectedMethod: CalibrationMethod = .longestAxis
    @State private var computedMeshDistance: Float = 0.0
    @Environment(\.dismiss) private var dismiss

    public init(mesh: MeshDTO?, calibrationData: Binding<CalibrationDTO>) {
        self.mesh = mesh
        self._calibrationData = calibrationData
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard

                if let mesh {
                    meshOverviewCard(mesh)
                    methodSelectionCard
                    distanceEntryCard

                    if calibrationData.isComplete {
                        completionCard
                    }
                } else {
                    unavailableCard
                }

                Button("Reset Calibration") {
                    calibrationData = CalibrationDTO.empty()
                    realWorldDistanceText = ""
                    selectedMethod = .longestAxis
                }
                .buttonStyle(.bordered)
                .disabled(mesh == nil)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(CoverCraftScreenBackground().ignoresSafeArea())
        .navigationTitle("Calibration")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if calibrationData.isRealWorldDistanceSet && calibrationData.realWorldDistance > 0 {
                realWorldDistanceText = String(format: "%.2f", calibrationData.realWorldDistance)
            }
            updateComputedDistance()
        }
        .onChange(of: selectedMethod) { _, _ in
            updateComputedDistance()
        }
    }

    private var heroCard: some View {
        CoverCraftCard(tone: calibrationData.isComplete ? .success : .accent) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    CoverCraftStatusChip(
                        calibrationData.isComplete ? "Scale applied" : "Scale required",
                        systemImage: calibrationData.isComplete ? "checkmark.seal.fill" : "ruler",
                        tone: calibrationData.isComplete ? .success : .accent
                    )

                    Text("Calibrate the scan with one measured reference before generating the pattern.")
                        .font(.title3.weight(.semibold))

                    Text("Choose the most trustworthy dimension, then enter its real-world distance in meters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "ruler.fill")
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

    private func meshOverviewCard(_ mesh: MeshDTO) -> some View {
        let bounds = mesh.boundingBox()
        let size = bounds.map { $0.max - $0.min }

        return CoverCraftCard(tone: .neutral) {
            CoverCraftSectionHeading(
                step: "Mesh",
                title: "Current Mesh",
                subtitle: "Use the extents below to pick a reference that matches a real-world measurement.",
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
                    subtitle: "Surface coverage",
                    systemImage: "triangle",
                    tone: .accent
                )

                if let size {
                    CoverCraftMetricTile(
                        title: "Width",
                        value: String(format: "%.3f", size.x),
                        subtitle: "Mesh units",
                        systemImage: "arrow.left.and.right",
                        tone: .neutral
                    )
                    CoverCraftMetricTile(
                        title: "Height",
                        value: String(format: "%.3f", size.y),
                        subtitle: "Mesh units",
                        systemImage: "arrow.up.and.down",
                        tone: .neutral
                    )
                    CoverCraftMetricTile(
                        title: "Depth",
                        value: String(format: "%.3f", size.z),
                        subtitle: "Mesh units",
                        systemImage: "arrow.forward",
                        tone: .neutral
                    )
                }
            }
        }
    }

    private var methodSelectionCard: some View {
        CoverCraftCard(tone: .accent) {
            CoverCraftSectionHeading(
                step: "Step 1",
                title: "Reference Dimension",
                subtitle: "Pick the dimension you can measure most accurately in the physical object.",
                statusTitle: selectedMethod.shortLabel,
                statusImage: selectedMethod.icon,
                tone: .accent
            )

            VStack(spacing: 10) {
                ForEach(CalibrationMethod.allCases) { method in
                    Button {
                        selectedMethod = method
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: method.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedMethod == method ? .white : .blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.rawValue)
                                    .font(.headline)
                                Text(method.description)
                                    .font(.caption)
                                    .foregroundStyle(selectedMethod == method ? Color.white.opacity(0.82) : .secondary)
                            }

                            Spacer()

                            Image(systemName: selectedMethod == method ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMethod == method ? .white : .secondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(selectedMethod == method ? Color.blue : Color.white.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(selectedMethod == method ? Color.blue.opacity(0.25) : Color.black.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if computedMeshDistance > 0 {
                CoverCraftStatusChip(
                    "Selected length: \(String(format: "%.4f", computedMeshDistance)) mesh units",
                    systemImage: "info.circle.fill",
                    tone: .neutral
                )
            }
        }
    }

    private var distanceEntryCard: some View {
        CoverCraftCard(tone: .accent) {
            CoverCraftSectionHeading(
                step: "Step 2",
                title: "Enter Real Distance",
                subtitle: "Use meters for the measured distance of the selected reference line.",
                tone: .accent
            )

            HStack(spacing: 12) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)

                TextField("Distance", text: $realWorldDistanceText)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                Text("meters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text("Example: enter `1.25` for a 1.25 meter reference.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !realWorldDistanceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               parsedRealWorldDistance == nil {
                CoverCraftStatusChip(
                    "Enter a positive distance in meters",
                    systemImage: "exclamationmark.triangle.fill",
                    tone: .warning
                )
            }

            Button(action: applyCalibration) {
                Label("Apply Calibration", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .disabled(mesh == nil || computedMeshDistance <= 0 || parsedRealWorldDistance == nil)
        }
    }

    private var completionCard: some View {
        CoverCraftCard(tone: .success) {
            CoverCraftSectionHeading(
                step: "Done",
                title: "Calibration Applied",
                subtitle: "The scan now carries a real-world scale for flattening and export.",
                statusTitle: "Ready",
                statusImage: "checkmark.seal.fill",
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
                    title: "Scale factor",
                    value: String(format: "%.6f", calibrationData.scaleFactor),
                    subtitle: "Applied to the mesh",
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    tone: .success
                )
                CoverCraftMetricTile(
                    title: "Real distance",
                    value: String(format: "%.3f m", calibrationData.realWorldDistance),
                    subtitle: "Measured reference",
                    systemImage: "ruler",
                    tone: .success
                )
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    private var unavailableCard: some View {
        CoverCraftCard(tone: .warning) {
            CoverCraftSectionHeading(
                step: "Unavailable",
                title: "No Mesh Available",
                subtitle: "A scan is required before calibration tools can do anything useful.",
                statusTitle: "Blocked",
                statusImage: "exclamationmark.triangle.fill",
                tone: .warning
            )

            Text("Capture the object first, then return here to assign scale.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func updateComputedDistance() {
        guard let mesh, let bounds = mesh.boundingBox() else {
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

    private var parsedRealWorldDistance: Double? {
        let trimmedValue = realWorldDistanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let distance = Double(trimmedValue), distance > 0 else {
            return nil
        }

        return distance
    }

    private func applyCalibration() {
        guard let mesh,
              let bounds = mesh.boundingBox(),
              let distance = parsedRealWorldDistance,
              computedMeshDistance > 0
        else { return }

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

        calibrationData = CalibrationDTO.with(
            firstPoint: point1,
            secondPoint: point2,
            realWorldDistance: distance
        )
    }
}
