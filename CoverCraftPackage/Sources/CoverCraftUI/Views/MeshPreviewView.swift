// Version: 1.0.0

import SwiftUI
import CoverCraftDTO

#if os(iOS) && canImport(UIKit) && canImport(SceneKit)
import SceneKit
import UIKit
#endif

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct MeshPreviewView: View {
    private let mesh: MeshDTO
    private let title: String
    private let subtitle: String

    public init(
        mesh: MeshDTO,
        title: String = "Mesh Preview",
        subtitle: String = "SceneKit preview when available, metrics fallback elsewhere."
    ) {
        self.mesh = mesh
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 18) {
            CoverCraftCard(tone: mesh.isValid ? .accent : .warning) {
                CoverCraftSectionHeading(
                    step: "Preview",
                    title: title,
                    subtitle: subtitle,
                    statusTitle: previewStatus.title,
                    statusImage: previewStatus.systemImage,
                    tone: previewStatus.tone
                )

                previewContent
                    .frame(minHeight: 280)
            }

            MeshMeasurementSummaryView(mesh: mesh)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if mesh.isValid {
            scenePreviewOrFallback
        } else {
            fallbackPanel(
                title: "Preview unavailable",
                message: "The mesh is invalid, so SceneKit rendering is skipped to avoid malformed index access.",
                systemImage: "exclamationmark.triangle.fill",
                tone: .warning
            )
        }
    }

    @ViewBuilder
    private var scenePreviewOrFallback: some View {
        #if os(iOS) && canImport(UIKit) && canImport(SceneKit)
        SceneKitMeshPreview(mesh: mesh)
            .clipShape(.rect(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
        #else
        fallbackPanel(
            title: "Scene preview unavailable",
            message: "This platform does not expose UIKit and SceneKit together. Mesh metrics are shown below.",
            systemImage: "cube.transparent",
            tone: .neutral
        )
        #endif
    }

    private var previewStatus: PreviewStatus {
        guard mesh.isValid else {
            return PreviewStatus(title: "Invalid", systemImage: "exclamationmark.triangle.fill", tone: .warning)
        }

        #if os(iOS) && canImport(UIKit) && canImport(SceneKit)
        return PreviewStatus(title: "SceneKit", systemImage: "cube.transparent", tone: .accent)
        #else
        return PreviewStatus(title: "Metrics", systemImage: "chart.bar", tone: .neutral)
        #endif
    }

    private func fallbackPanel(
        title: String,
        message: String,
        systemImage: String,
        tone: CoverCraftTone
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(toneColor(tone))

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(toneColor(tone).opacity(0.16), lineWidth: 1)
        )
    }

    private func toneColor(_ tone: CoverCraftTone) -> Color {
        switch tone {
        case .neutral:
            return Color(red: 0.31, green: 0.37, blue: 0.46)
        case .accent:
            return Color(red: 0.06, green: 0.44, blue: 0.79)
        case .success:
            return Color(red: 0.16, green: 0.60, blue: 0.35)
        case .warning:
            return Color(red: 0.82, green: 0.47, blue: 0.08)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct PreviewStatus {
    let title: String
    let systemImage: String
    let tone: CoverCraftTone
}

#if os(iOS) && canImport(UIKit) && canImport(SceneKit)
@available(iOS 18.0, *)
@MainActor
private struct SceneKitMeshPreview: UIViewRepresentable {
    let mesh: MeshDTO

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear
        view.scene = makeScene()
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = makeScene()
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        let meshNode = SCNNode(geometry: makeGeometry())
        scene.rootNode.addChildNode(meshNode)

        let bounds = mesh.boundingBox()
        let center = bounds.map { ($0.min + $0.max) / 2 } ?? .zero
        meshNode.position = SCNVector3(-center.x, -center.y, -center.z)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.001
        cameraNode.camera?.zFar = 1_000
        cameraNode.position = cameraPosition(for: bounds)
        cameraNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(cameraNode)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.intensity = 650
        fillLight.position = SCNVector3(2.5, 3.0, 3.5)
        scene.rootNode.addChildNode(fillLight)

        return scene
    }

    private func makeGeometry() -> SCNGeometry {
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
        material.diffuse.contents = UIColor.systemTeal
        material.specular.contents = UIColor.white.withAlphaComponent(0.35)
        material.isDoubleSided = true
        geometry.materials = [material]
        return geometry
    }

    private func cameraPosition(for bounds: (min: SIMD3<Float>, max: SIMD3<Float>)?) -> SCNVector3 {
        guard let bounds else {
            return SCNVector3(0, 0, 2)
        }

        let size = bounds.max - bounds.min
        let longestSide = max(size.x, size.y, size.z)
        let distance = max(longestSide * 2.2, 0.5)
        return SCNVector3(distance, distance * 0.75, distance)
    }
}
#endif
