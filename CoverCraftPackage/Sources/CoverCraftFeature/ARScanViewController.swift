#if canImport(UIKit) && canImport(ARKit)
import UIKit
import ARKit
import SceneKit

/// View controller handling AR scanning with LiDAR
public final class ARScanViewController: UIViewController {
    
    // MARK: - Properties
    
    private var sceneView: ARSCNView!
    private var coachingOverlay: ARCoachingOverlayView!
    private var finishButton: UIButton!
    
    private var collectedMeshAnchors: [UUID: ARMeshAnchor] = [:]
    public var onScanComplete: ((Mesh) -> Void)?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupCoachingOverlay()
        setupFinishButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Setup
    
    private func setupARView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        view.addSubview(sceneView)
    }
    
    private func setupCoachingOverlay() {
        coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = sceneView.session
        coachingOverlay.goal = .tracking
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFinishButton() {
        finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish Scan", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.backgroundColor = .systemBlue
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        
        view.addSubview(finishButton)
        
        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            finishButton.widthAnchor.constraint(equalToConstant: 200),
            finishButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - AR Session
    
    private func startARSession() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            showError("This device doesn't support LiDAR scanning")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .mesh
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Actions
    
    @objc private func finishButtonTapped() {
        let mesh = buildMeshFromAnchors()
        onScanComplete?(mesh)
        dismiss(animated: true)
    }
    
    private func buildMeshFromAnchors() -> Mesh {
        // For now, create a simple test cube mesh
        // In a real implementation, this would process the actual ARMeshAnchor data
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-0.5, -0.5, -0.5), // 0
            SIMD3<Float>( 0.5, -0.5, -0.5), // 1
            SIMD3<Float>( 0.5,  0.5, -0.5), // 2
            SIMD3<Float>(-0.5,  0.5, -0.5), // 3
            SIMD3<Float>(-0.5, -0.5,  0.5), // 4
            SIMD3<Float>( 0.5, -0.5,  0.5), // 5
            SIMD3<Float>( 0.5,  0.5,  0.5), // 6
            SIMD3<Float>(-0.5,  0.5,  0.5)  // 7
        ]
        
        let triangles: [Int] = [
            // Front face
            0, 1, 2,  0, 2, 3,
            // Back face
            4, 6, 5,  4, 7, 6,
            // Left face
            0, 3, 7,  0, 7, 4,
            // Right face
            1, 5, 6,  1, 6, 2,
            // Top face
            3, 2, 6,  3, 6, 7,
            // Bottom face
            0, 4, 5,  0, 5, 1
        ]
        
        return Mesh(vertices: vertices, triangleIndices: triangles)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ARSCNViewDelegate

extension ARScanViewController: ARSCNViewDelegate {
    nonisolated public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Simplified implementation - just return nil for now
        return nil
    }
    
    nonisolated public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // No updates needed for simplified implementation
    }
    
    private func createGeometry(from meshAnchor: ARMeshAnchor) -> SCNGeometry {
        let vertices = meshAnchor.geometry.vertices
        let faces = meshAnchor.geometry.faces
        
        let vertexSource = SCNGeometrySource(
            buffer: vertices.buffer,
            vertexFormat: vertices.format,
            semantic: .vertex,
            vertexCount: vertices.count,
            dataOffset: vertices.offset,
            dataStride: vertices.stride
        )
        
        let faceData = Data(
            bytesNoCopy: faces.buffer.contents(),
            count: faces.count * faces.indexCountPerPrimitive * MemoryLayout<UInt32>.size,
            deallocator: .none
        )
        
        let element = SCNGeometryElement(
            data: faceData,
            primitiveType: .triangles,
            primitiveCount: faces.count,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        
        // Apply semi-transparent material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.3)
        material.isDoubleSided = true
        geometry.materials = [material]
        
        return geometry
    }
}

// MARK: - ARSessionDelegate

extension ARScanViewController: ARSessionDelegate {
    nonisolated public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    collectedMeshAnchors[meshAnchor.identifier] = meshAnchor
                }
            }
        }
    }
    
    nonisolated public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    collectedMeshAnchors[meshAnchor.identifier] = meshAnchor
                }
            }
        }
    }
    
    nonisolated public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    collectedMeshAnchors.removeValue(forKey: meshAnchor.identifier)
                }
            }
        }
    }
}
#endif