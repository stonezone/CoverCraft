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
        guard !collectedMeshAnchors.isEmpty else {
            // Return test cube for simulator/testing
            let vertices: [SIMD3<Float>] = [
                SIMD3<Float>(-0.5, -0.5, -0.5), SIMD3<Float>( 0.5, -0.5, -0.5),
                SIMD3<Float>( 0.5,  0.5, -0.5), SIMD3<Float>(-0.5,  0.5, -0.5),
                SIMD3<Float>(-0.5, -0.5,  0.5), SIMD3<Float>( 0.5, -0.5,  0.5),
                SIMD3<Float>( 0.5,  0.5,  0.5), SIMD3<Float>(-0.5,  0.5,  0.5)
            ]
            
            let triangles: [Int] = [
                0, 1, 2,  0, 2, 3,  4, 6, 5,  4, 7, 6,  0, 3, 7,  0, 7, 4,
                1, 5, 6,  1, 6, 2,  3, 2, 6,  3, 6, 7,  0, 4, 5,  0, 5, 1
            ]
            
            return Mesh(vertices: vertices, triangleIndices: triangles)
        }
        
        let vertexWelder = VertexWelder(quantization: 0.001) // 1mm precision
        var globalTriangles: [Int] = []
        
        // Process each ARMeshAnchor
        for meshAnchor in collectedMeshAnchors.values {
            let transform = meshAnchor.transform
            let geometry = meshAnchor.geometry
            
            // Extract vertices and convert to global coordinates
            let vertexBuffer = geometry.vertices
            let vertexCount = vertexBuffer.count
            
            guard vertexCount > 0 else { continue }
            
            let vertexPointer = vertexBuffer.buffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: vertexCount)
            let vertexBufferPointer = UnsafeBufferPointer(start: vertexPointer, count: vertexCount)
            
            var localVertices: [SIMD3<Float>] = []
            for i in 0..<vertexCount {
                let localVertex = vertexBufferPointer[i]
                let globalVertex = (transform * SIMD4<Float>(localVertex.x, localVertex.y, localVertex.z, 1.0)).xyz
                localVertices.append(globalVertex)
            }
            
            // Extract face indices
            let faceBuffer = geometry.faces
            let faceCount = faceBuffer.count
            
            guard faceCount > 0 else { continue }
            
            let facePointer = faceBuffer.buffer.contents().bindMemory(to: UInt32.self, capacity: faceCount * 3)
            let faceBufferPointer = UnsafeBufferPointer(start: facePointer, count: faceCount * 3)
            
            // Add vertices to welder and build triangle indices
            var localToGlobalMap: [Int] = []
            for vertex in localVertices {
                let globalIndex = vertexWelder.addVertex(vertex)
                localToGlobalMap.append(globalIndex)
            }
            
            // Build triangles with proper winding order
            for faceIndex in 0..<faceCount {
                let baseIdx = faceIndex * 3
                let i0 = Int(faceBufferPointer[baseIdx])
                let i1 = Int(faceBufferPointer[baseIdx + 1])
                let i2 = Int(faceBufferPointer[baseIdx + 2])
                
                guard i0 < localToGlobalMap.count,
                      i1 < localToGlobalMap.count,
                      i2 < localToGlobalMap.count else { continue }
                
                // Convert to global indices
                let globalI0 = localToGlobalMap[i0]
                let globalI1 = localToGlobalMap[i1]
                let globalI2 = localToGlobalMap[i2]
                
                // Add triangle with consistent winding (counter-clockwise when viewed from outside)
                globalTriangles.append(globalI0)
                globalTriangles.append(globalI1)
                globalTriangles.append(globalI2)
            }
        }
        
        return Mesh(vertices: vertexWelder.getVertices(), triangleIndices: globalTriangles)
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

// MARK: - Vertex Welding and Quantization Helpers

/// Helper class for vertex welding with quantization grid
private class VertexWelder {
    private var quantizedVertices: [QuantizedKey: Int] = [:]
    private var uniqueVertices: [SIMD3<Float>] = []
    private let quantization: Float
    
    init(quantization: Float) {
        self.quantization = quantization
    }
    
    /// Add vertex and return its global index (welds duplicates)
    func addVertex(_ vertex: SIMD3<Float>) -> Int {
        let key = QuantizedKey(vertex: vertex, quantization: quantization)
        
        if let existingIndex = quantizedVertices[key] {
            return existingIndex
        } else {
            let newIndex = uniqueVertices.count
            uniqueVertices.append(vertex)
            quantizedVertices[key] = newIndex
            return newIndex
        }
    }
    
    func getVertices() -> [SIMD3<Float>] {
        return uniqueVertices
    }
}

/// Quantized vertex key for welding duplicates
private struct QuantizedKey: Hashable {
    let x, y, z: Int
    
    init(vertex: SIMD3<Float>, quantization: Float) {
        // Convert to quantized integer coordinates
        x = Int(round(vertex.x / quantization))
        y = Int(round(vertex.y / quantization))
        z = Int(round(vertex.z / quantization))
    }
}

/// Extension to extract xyz from homogeneous coordinates
private extension SIMD4<Float> {
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

#endif