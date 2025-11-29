// ARScanViewController.swift
// CoverCraft AR Module - Polycam-Style Real-time LiDAR Scanning
// Based on proven GitHub implementations from cedanmisquith/SwiftUI-LiDAR and ximhear/ios-lidar-mesh

#if canImport(UIKit) && canImport(ARKit)
import UIKit
import ARKit
import SceneKit
import simd

/// Mesh data structure for AR scanned geometry
public struct Mesh {
    public let vertices: [SIMD3<Float>]
    public let triangleIndices: [Int]
    
    public init(vertices: [SIMD3<Float>], triangleIndices: [Int]) {
        self.vertices = vertices
        self.triangleIndices = triangleIndices
    }
}

/// View controller handling AR scanning with LiDAR - Polycam style
public final class ARScanViewController: UIViewController {
    
    // MARK: - Properties
    
    private var sceneView: ARSCNView!
    private var coachingOverlay: ARCoachingOverlayView!
    private var finishButton: UIButton!
    private var vertexCountLabel: UILabel!
    
    // Mesh data storage
    private var collectedMeshAnchors: [UUID: ARMeshAnchor] = [:]
    
    public var onScanComplete: ((Mesh) -> Void)?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupCoachingOverlay()
        setupFinishButton()
        setupVertexCountLabel()
        
        print("POLYCAM: ARScanViewController loaded")
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
        
        // CRITICAL: Set delegates for mesh visualization
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Lighting for visibility
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // Debug options - can help see if AR is working
        sceneView.showsStatistics = true
        
        view.addSubview(sceneView)
        
        print("POLYCAM: ARSCNView setup complete with delegates")
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
        finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(finishButton)
        
        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            finishButton.widthAnchor.constraint(equalToConstant: 200),
            finishButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupVertexCountLabel() {
        vertexCountLabel = UILabel()
        vertexCountLabel.text = "0 vertices"
        vertexCountLabel.font = .systemFont(ofSize: 16, weight: .medium)
        vertexCountLabel.textColor = .white
        vertexCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        vertexCountLabel.layer.cornerRadius = 8
        vertexCountLabel.clipsToBounds = true
        vertexCountLabel.textAlignment = .center
        vertexCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vertexCountLabel)
        
        NSLayoutConstraint.activate([
            vertexCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            vertexCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vertexCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            vertexCountLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - AR Session
    
    private func startARSession() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            print("ERROR: This device doesn't support LiDAR scanning")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        
        // CRITICAL: Enable mesh reconstruction for LiDAR
        configuration.sceneReconstruction = .meshWithClassification
        
        // CRITICAL: Enable scene depth for direct LiDAR access
        configuration.frameSemantics = .sceneDepth
        
        // Additional settings
        configuration.environmentTexturing = .automatic
        configuration.worldAlignment = .gravity
        
        // Start fresh
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        print("POLYCAM: AR session started with mesh reconstruction and scene depth")
    }
    
    // MARK: - Actions
    
    @objc private func finishButtonTapped() {
        sceneView.session.pause()
        
        // Build final mesh from all collected anchors
        let finalMesh = buildFinalMesh()
        onScanComplete?(finalMesh)
        dismiss(animated: true, completion: nil)
    }
    
    private func buildFinalMesh() -> Mesh {
        var allVertices: [SIMD3<Float>] = []
        var allIndices: [Int] = []
        var vertexOffset = 0
        
        for anchor in collectedMeshAnchors.values {
            let geometry = anchor.geometry
            
            // Extract vertices with proper buffer access
            for i in 0..<geometry.vertices.count {
                let stride = geometry.vertices.stride
                let offset = geometry.vertices.offset + (stride * i)
                let vertexPointer = geometry.vertices.buffer.contents().advanced(by: offset)
                let localVertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                
                // Transform to world space
                let worldPos = anchor.transform * SIMD4<Float>(localVertex, 1.0)
                allVertices.append(SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z))
            }
            
            // Extract face indices
            let faceCount = geometry.faces.count
            let indexCount = faceCount * 3
            
            if geometry.faces.bytesPerIndex == 2 {
                let pointer = geometry.faces.buffer.contents().bindMemory(to: UInt16.self, capacity: indexCount)
                for i in 0..<indexCount {
                    allIndices.append(Int(pointer[i]) + vertexOffset)
                }
            } else {
                let pointer = geometry.faces.buffer.contents().bindMemory(to: UInt32.self, capacity: indexCount)
                for i in 0..<indexCount {
                    allIndices.append(Int(pointer[i]) + vertexOffset)
                }
            }
            
            vertexOffset += geometry.vertices.count
        }
        
        return Mesh(vertices: allVertices, triangleIndices: allIndices)
    }
}

// MARK: - ARSCNViewDelegate
// CRITICAL: This is how the mesh visualization actually happens!

extension ARScanViewController: ARSCNViewDelegate {
    
    // Called when a new anchor is added - create visualization node
    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else { 
            return nil 
        }
        
        print("POLYCAM: Creating node for mesh anchor \(meshAnchor.identifier)")
        
        // Create geometry from the mesh anchor
        let geometry = createGeometryFromMeshAnchor(meshAnchor)
        
        // Create node with the geometry
        let node = SCNNode(geometry: geometry)
        node.name = "MeshNode_\(meshAnchor.identifier)"
        
        return node
    }
    
    // Called when an anchor is updated - update its visualization
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { 
            return 
        }
        
        // Update the node's geometry with the updated mesh
        let geometry = createGeometryFromMeshAnchor(meshAnchor)
        node.geometry = geometry
    }
    
    // Create SCNGeometry from ARMeshAnchor
    private func createGeometryFromMeshAnchor(_ anchor: ARMeshAnchor) -> SCNGeometry {
        let meshGeometry = anchor.geometry
        
        // Create vertex source directly from ARMeshGeometry buffers
        let vertices = meshGeometry.vertices
        let vertexSource = SCNGeometrySource(
            buffer: vertices.buffer,
            vertexFormat: vertices.format,
            semantic: .vertex,
            vertexCount: vertices.count,
            dataOffset: vertices.offset,
            dataStride: vertices.stride
        )
        
        // Create face element from face buffer
        let faces = meshGeometry.faces
        let faceElement = SCNGeometryElement(
            buffer: faces.buffer,
            primitiveType: .triangles,
            primitiveCount: faces.count,
            bytesPerIndex: faces.bytesPerIndex
        )
        
        // Create geometry
        let geometry = SCNGeometry(sources: [vertexSource], elements: [faceElement])
        
        // POLYCAM-STYLE MATERIAL: Semi-transparent cyan wireframe
        let material = SCNMaterial()
        
        // Cyan color with transparency
        material.diffuse.contents = UIColor.cyan
        material.transparency = 0.6
        
        // CRITICAL: Wireframe mode for mesh visualization
        material.fillMode = .lines
        
        // Double-sided rendering
        material.isDoubleSided = true
        
        // Constant lighting so it's always visible
        material.lightingModel = .constant
        
        // Don't write to depth buffer so we can see through it
        material.writesToDepthBuffer = false
        
        geometry.materials = [material]
        
        return geometry
    }
}

// MARK: - ARSessionDelegate

extension ARScanViewController: ARSessionDelegate {
    
    // Process every frame for UI updates
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Get all mesh anchors
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
        
        // Store for final mesh building
        for anchor in meshAnchors {
            collectedMeshAnchors[anchor.identifier] = anchor
        }
        
        // Update UI with statistics
        DispatchQueue.main.async { [weak self] in
            let totalVertices = meshAnchors.reduce(0) { $0 + $1.geometry.vertices.count }
            let totalTriangles = meshAnchors.reduce(0) { $0 + $1.geometry.faces.count }
            
            self?.vertexCountLabel.text = "\(totalVertices) verts | \(totalTriangles) tris"
            
            // Log periodically
            if frame.timestamp.truncatingRemainder(dividingBy: 1.0) < 0.05 {
                print("POLYCAM: \(meshAnchors.count) anchors, \(totalVertices) vertices")
            }
        }
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                print("POLYCAM: Added mesh anchor with \(meshAnchor.geometry.vertices.count) vertices")
            }
        }
    }
}

#endif