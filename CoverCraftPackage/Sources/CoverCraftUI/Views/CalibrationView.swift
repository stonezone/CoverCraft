import SwiftUI
import simd
import CoverCraftDTO
import CoverCraftCore

#if canImport(UIKit)
import UIKit
#endif

enum CalibrationDistanceUnit: String, CaseIterable, Identifiable {
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case inches = "in"

    var id: String { rawValue }

    var metersPerUnit: Double {
        switch self {
        case .millimeters: return 0.001
        case .centimeters: return 0.01
        case .meters: return 1
        case .inches: return 0.0254
        }
    }

    var exampleText: String {
        switch self {
        case .millimeters: return "Example: enter `500` for a 500 mm reference."
        case .centimeters: return "Example: enter `50` for a 50 cm reference."
        case .meters: return "Example: enter `0.5` for a 0.5 m reference."
        case .inches: return "Example: enter `20` for a 20 inch reference."
        }
    }

    func meters(from value: Double) -> Double {
        value * metersPerUnit
    }

    func displayValue(fromMeters meters: Double) -> Double {
        meters / metersPerUnit
    }
}

enum CalibrationMethod: String, CaseIterable, Identifiable {
    case pointToPoint = "Tap-to-Tap Points"
    case diagonal = "Bounding Box Diagonal"
    case xAxis = "X-Axis (Width)"
    case yAxis = "Y-Axis (Height)"
    case zAxis = "Z-Axis (Depth)"
    case longestAxis = "Longest Axis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pointToPoint: return "hand.tap"
        case .diagonal: return "cube.transparent"
        case .xAxis: return "arrow.left.and.right"
        case .yAxis: return "arrow.up.and.down"
        case .zAxis: return "arrow.forward"
        case .longestAxis: return "ruler"
        }
    }

    var shortLabel: String {
        switch self {
        case .pointToPoint: return "Tap-to-Tap"
        case .diagonal: return "Diagonal"
        case .xAxis: return "Width"
        case .yAxis: return "Height"
        case .zAxis: return "Depth"
        case .longestAxis: return "Longest"
        }
    }

    var description: String {
        switch self {
        case .pointToPoint: return "Tap two visible points on the mesh"
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
    @State private var selectedDistanceUnit: CalibrationDistanceUnit = .millimeters
    @State private var selectedMethod: CalibrationMethod = .pointToPoint
    @State private var computedMeshDistance: Float = 0.0
    @State private var selectedReferencePoints: [SIMD3<Float>] = []
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
                    if selectedMethod == .pointToPoint {
                        pointPickerCard(mesh)
                    }
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
                    selectedMethod = .pointToPoint
                    selectedReferencePoints = []
                    computedMeshDistance = 0
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
                realWorldDistanceText = formattedDistance(
                    selectedDistanceUnit.displayValue(fromMeters: calibrationData.realWorldDistance)
                )
            }
            if let firstPoint = calibrationData.firstPoint,
               let secondPoint = calibrationData.secondPoint {
                selectedReferencePoints = [firstPoint, secondPoint]
                selectedMethod = .pointToPoint
            }
            updateComputedDistance()
        }
        .onChange(of: selectedMethod) { _, _ in
            updateComputedDistance()
        }
        .onChange(of: selectedDistanceUnit) { oldUnit, newUnit in
            guard let meters = parsedRealWorldDistance(in: oldUnit) else { return }
            realWorldDistanceText = formattedDistance(newUnit.displayValue(fromMeters: meters))
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

                    Text("Calibrate the scan with one visible reference before generating the pattern.")
                        .font(.title3.weight(.semibold))

                    Text("Tap two visible points for the best scale reference, or fall back to bounding-box extents when point picking is not practical.")
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
                subtitle: "These are bounding-box extents. They help you choose a reference, but they are not a substitute for a visual point-to-point pick.",
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
                        title: "Max length",
                        value: String(format: "%.3f", max(size.x, max(size.y, size.z))),
                        subtitle: "Longest extent",
                        systemImage: "ruler",
                        tone: .accent
                    )
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

            Text("Axis extents are approximate. Tap-to-tap points are preferred when the target has a visible edge, seam, or measured reference mark.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            } else if selectedMethod == .pointToPoint {
                CoverCraftStatusChip(
                    "Tap two mesh points before applying scale",
                    systemImage: "hand.tap",
                    tone: .warning
                )
            }
        }
    }

    private func pointPickerCard(_ mesh: MeshDTO) -> some View {
        CoverCraftCard(tone: selectedReferencePoints.count == 2 ? .success : .accent) {
            CoverCraftSectionHeading(
                step: "Step 1A",
                title: "Mark Reference Points",
                subtitle: "Tap the two ends of a distance you can measure on the physical object.",
                statusTitle: selectedReferencePoints.count == 2 ? "Ready" : "Needs 2 points",
                statusImage: selectedReferencePoints.count == 2 ? "checkmark.circle.fill" : "hand.tap",
                tone: selectedReferencePoints.count == 2 ? .success : .accent
            )

            MeshPointPickerView(
                mesh: mesh,
                selectedPoints: selectedReferencePointsBinding
            )
        }
    }

    private var distanceEntryCard: some View {
        CoverCraftCard(tone: .accent) {
            CoverCraftSectionHeading(
                step: "Step 2",
                title: "Enter Real Distance",
                subtitle: "Enter the physical measurement for the selected reference line.",
                tone: .accent
            )

            Picker("Distance Unit", selection: $selectedDistanceUnit) {
                ForEach(CalibrationDistanceUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)

                TextField("Distance", text: $realWorldDistanceText)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                Text(selectedDistanceUnit.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }

            Text(selectedDistanceUnit.exampleText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !realWorldDistanceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               parsedRealWorldDistance == nil {
                CoverCraftStatusChip(
                    "Enter a positive distance in \(selectedDistanceUnit.rawValue)",
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
                    value: "\(formattedDistance(selectedDistanceUnit.displayValue(fromMeters: calibrationData.realWorldDistance))) \(selectedDistanceUnit.rawValue)",
                    subtitle: "Stored as \(String(format: "%.3f m", calibrationData.realWorldDistance))",
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
        case .pointToPoint:
            guard selectedReferencePoints.count == 2 else {
                computedMeshDistance = 0
                return
            }
            computedMeshDistance = simd_distance(selectedReferencePoints[0], selectedReferencePoints[1])
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
        parsedRealWorldDistance(in: selectedDistanceUnit)
    }

    private func parsedRealWorldDistance(in unit: CalibrationDistanceUnit) -> Double? {
        let trimmedValue = realWorldDistanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let distance = Double(trimmedValue), distance > 0 else {
            return nil
        }

        return unit.meters(from: distance)
    }

    private func formattedDistance(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.2f", value)
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
        case .pointToPoint:
            guard selectedReferencePoints.count == 2 else { return }
            point1 = selectedReferencePoints[0]
            point2 = selectedReferencePoints[1]
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

    private var selectedReferencePointsBinding: Binding<[SIMD3<Float>]> {
        Binding(
            get: { selectedReferencePoints },
            set: { newValue in
                selectedReferencePoints = Array(newValue.suffix(2))
                updateComputedDistance()
            }
        )
    }
}
