// Version: 1.0.0

import SwiftUI
import simd
import CoverCraftDTO

#if os(iOS) && canImport(UIKit) && canImport(SceneKit)
import SceneKit
import UIKit
#endif

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct MeshPointPickerView: View {
    private let mesh: MeshDTO
    @Binding private var selectedPoints: [SIMD3<Float>]

    public init(
        mesh: MeshDTO,
        selectedPoints: Binding<[SIMD3<Float>]>
    ) {
        self.mesh = mesh
        self._selectedPoints = selectedPoints
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            pickerContent
                .frame(minHeight: 300)

            selectionSummary
        }
    }

    @ViewBuilder
    private var pickerContent: some View {
        if mesh.isValid {
            #if os(iOS) && canImport(UIKit) && canImport(SceneKit)
            SceneKitPointPicker(mesh: mesh, selectedPoints: $selectedPoints)
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                )
            #else
            pointPickerFallback
            #endif
        } else {
            pointPickerFallback
        }
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CoverCraftStatusChip(
                    "\(selectedPoints.count)/2 points selected",
                    systemImage: selectedPoints.count == 2 ? "checkmark.circle.fill" : "hand.tap",
                    tone: selectedPoints.count == 2 ? .success : .warning
                )

                Spacer()

                Button("Clear Points") {
                    selectedPoints = []
                }
                .buttonStyle(.bordered)
                .disabled(selectedPoints.isEmpty)
            }

            if selectedPoints.count == 2 {
                Text("Selected mesh distance: \(String(format: "%.4f", simd_distance(selectedPoints[0], selectedPoints[1]))) units")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("Rotate the mesh, tap one end of a known real-world measurement, then tap the other end.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var pointPickerFallback: some View {
        VStack(spacing: 14) {
            Image(systemName: "hand.tap")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Point picker unavailable")
                .font(.headline)

            Text("Use one of the axis presets. Tap-to-tap picking requires iOS SceneKit and a valid mesh.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.16), lineWidth: 1)
        )
    }
}

#if os(iOS) && canImport(UIKit) && canImport(SceneKit)
@available(iOS 18.0, *)
@MainActor
private struct SceneKitPointPicker: UIViewRepresentable {
    let mesh: MeshDTO
    @Binding var selectedPoints: [SIMD3<Float>]

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear
        view.scene = makeScene()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Mesh point picker"
        view.accessibilityHint = "Tap two visible points on the mesh to define the scale reference."
        view.accessibilityValue = accessibilityValue

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.parent = self
        let previousCameraTransform = uiView.pointOfView?.transform
        uiView.scene = makeScene()
        uiView.accessibilityValue = accessibilityValue

        if let previousCameraTransform,
           let cameraNode = uiView.scene?.rootNode.childNode(withName: "camera", recursively: true) {
            cameraNode.transform = previousCameraTransform
            uiView.pointOfView = cameraNode
        }
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        let bounds = mesh.boundingBox()
        let center = bounds.map { ($0.min + $0.max) / 2 } ?? .zero
        let centerOffset = SCNVector3(-center.x, -center.y, -center.z)

        let meshNode = SCNNode(geometry: makeMeshGeometry())
        meshNode.name = "pickableMesh"
        meshNode.position = centerOffset
        scene.rootNode.addChildNode(meshNode)

        let selectionNode = SCNNode()
        selectionNode.name = "selectionOverlay"
        selectionNode.position = centerOffset
        addSelectionMarkers(to: selectionNode)
        scene.rootNode.addChildNode(selectionNode)

        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.001
        cameraNode.camera?.zFar = 1_000
        cameraNode.position = cameraPosition(for: bounds)
        cameraNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(cameraNode)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.intensity = 700
        fillLight.position = SCNVector3(2.5, 3.0, 3.5)
        scene.rootNode.addChildNode(fillLight)

        return scene
    }

    private func makeMeshGeometry() -> SCNGeometry {
        let vertices = mesh.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
        let source = SCNGeometrySource(vertices: vertices)
        let indexData = Data(bytes: mesh.triangleIndices.map(Int32.init), count: mesh.triangleIndices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: mesh.triangleCount,
            bytesPerIndex: MemoryLayout<Int32>.size
        )

        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.76)
        material.specular.contents = UIColor.white.withAlphaComponent(0.35)
        material.isDoubleSided = true
        geometry.materials = [material]
        return geometry
    }

    private func addSelectionMarkers(to node: SCNNode) {
        for (index, point) in selectedPoints.enumerated() {
            let sphere = SCNSphere(radius: markerRadius())
            let material = SCNMaterial()
            material.diffuse.contents = index == 0 ? UIColor.systemYellow : UIColor.systemRed
            material.emission.contents = index == 0 ? UIColor.systemYellow.withAlphaComponent(0.35) : UIColor.systemRed.withAlphaComponent(0.35)
            sphere.materials = [material]

            let markerNode = SCNNode(geometry: sphere)
            markerNode.name = "selectionMarker"
            markerNode.position = SCNVector3(point.x, point.y, point.z)
            node.addChildNode(markerNode)
        }

        if selectedPoints.count == 2 {
            let lineNode = SCNNode(geometry: makeLineGeometry(from: selectedPoints[0], to: selectedPoints[1]))
            lineNode.name = "selectionLine"
            node.addChildNode(lineNode)
        }
    }

    private func makeLineGeometry(from first: SIMD3<Float>, to second: SIMD3<Float>) -> SCNGeometry {
        let source = SCNGeometrySource(vertices: [
            SCNVector3(first.x, first.y, first.z),
            SCNVector3(second.x, second.y, second.z)
        ])
        let indices: [Int32] = [0, 1]
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .line,
            primitiveCount: 1,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemYellow
        material.emission.contents = UIColor.systemYellow.withAlphaComponent(0.45)
        geometry.materials = [material]
        return geometry
    }

    private func markerRadius() -> CGFloat {
        guard let bounds = mesh.boundingBox() else { return 0.01 }
        let size = bounds.max - bounds.min
        let longestSide = max(size.x, size.y, size.z)
        return CGFloat(max(longestSide * 0.018, 0.006))
    }

    private func cameraPosition(for bounds: (min: SIMD3<Float>, max: SIMD3<Float>)?) -> SCNVector3 {
        guard let bounds else {
            return SCNVector3(0, 0, 2)
        }

        let size = bounds.max - bounds.min
        let longestSide = max(size.x, size.y, size.z)
        let distance = max(longestSide * 2.35, 0.5)
        return SCNVector3(distance, distance * 0.75, distance)
    }

    private var accessibilityValue: String {
        switch selectedPoints.count {
        case 0:
            return "No points selected"
        case 1:
            return "One point selected"
        default:
            return "Two points selected"
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: SceneKitPointPicker

        init(parent: SceneKitPointPicker) {
            self.parent = parent
        }

        @objc
        func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView,
                  let meshNode = view.scene?.rootNode.childNode(withName: "pickableMesh", recursively: true)
            else { return }

            let location = gesture.location(in: view)
            let results = view.hitTest(
                location,
                options: [
                    .rootNode: meshNode,
                    .ignoreHiddenNodes: true,
                    .boundingBoxOnly: false
                ]
            )

            guard let hit = results.first else { return }
            let localPoint = hit.localCoordinates
            let meshPoint = SIMD3<Float>(localPoint.x, localPoint.y, localPoint.z)
            var points = parent.selectedPoints
            points.append(meshPoint)
            parent.selectedPoints = Array(points.suffix(2))
        }
    }
}
#endif
