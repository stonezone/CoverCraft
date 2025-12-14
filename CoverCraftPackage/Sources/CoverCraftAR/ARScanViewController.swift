// ARScanViewController.swift
// CoverCraft AR Module - Polycam-Style Real-time LiDAR Scanning
// Based on proven GitHub implementations from cedanmisquith/SwiftUI-LiDAR and ximhear/ios-lidar-mesh

#if canImport(UIKit) && canImport(ARKit)
import UIKit
import ARKit
import SceneKit
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// View controller handling AR scanning with LiDAR - Polycam style
public final class ARScanViewController: UIViewController {

    // MARK: - Properties

    private var sceneView: ARSCNView!
    private var coachingOverlay: ARCoachingOverlayView!
    private var finishButton: UIButton!
    private var vertexCountLabel: UILabel!
    private var qualityContainerView: UIView!
    private var qualityProgressView: UIProgressView!
    private var qualityLabel: UILabel!
    private var depthSlider: UISlider!
    private var depthLabel: UILabel!
    private var depthLimitIndicator: SCNNode?

    // Mesh data storage
    private var collectedMeshAnchors: [UUID: ARMeshAnchor] = [:]
    private var anchorInsertionOrder: [UUID] = []  // Track insertion order for FIFO pruning

    // Memory management - limit anchor count to prevent unbounded growth
    private var maxAnchorCount: Int { Configuration.current.maxAnchorCount }

    // Depth limiting - default 2 meters, range 0.3m to 5m
    private var maxDepth: Float = 2.0
    private var lastCameraTransform: simd_float4x4?

    public var onScanComplete: ((MeshDTO) -> Void)?

    // Logger for AR scanning events
    private let logger = Logger(label: "com.covercraft.ar.scan")
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupCoachingOverlay()
        setupFinishButton()
        setupVertexCountLabel()
        setupQualityIndicator()
        setupDepthSlider()

        logger.info("ARScanViewController loaded")
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

        logger.debug("ARSCNView setup complete with delegates")
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

    private func setupQualityIndicator() {
        // Container
        qualityContainerView = UIView()
        qualityContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        qualityContainerView.layer.cornerRadius = 8
        qualityContainerView.clipsToBounds = true
        qualityContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qualityContainerView)

        // Quality label
        qualityLabel = UILabel()
        qualityLabel.text = "Scan Quality: Poor"
        qualityLabel.font = .systemFont(ofSize: 12, weight: .medium)
        qualityLabel.textColor = .white
        qualityLabel.textAlignment = .center
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        qualityContainerView.addSubview(qualityLabel)

        // Progress bar
        qualityProgressView = UIProgressView(progressViewStyle: .default)
        qualityProgressView.progress = 0.0
        qualityProgressView.trackTintColor = .darkGray
        qualityProgressView.progressTintColor = .systemRed
        qualityProgressView.translatesAutoresizingMaskIntoConstraints = false
        qualityContainerView.addSubview(qualityProgressView)

        NSLayoutConstraint.activate([
            qualityContainerView.topAnchor.constraint(equalTo: vertexCountLabel.bottomAnchor, constant: 8),
            qualityContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qualityContainerView.widthAnchor.constraint(equalToConstant: 200),
            qualityContainerView.heightAnchor.constraint(equalToConstant: 50),

            qualityLabel.topAnchor.constraint(equalTo: qualityContainerView.topAnchor, constant: 6),
            qualityLabel.leadingAnchor.constraint(equalTo: qualityContainerView.leadingAnchor, constant: 8),
            qualityLabel.trailingAnchor.constraint(equalTo: qualityContainerView.trailingAnchor, constant: -8),

            qualityProgressView.topAnchor.constraint(equalTo: qualityLabel.bottomAnchor, constant: 6),
            qualityProgressView.leadingAnchor.constraint(equalTo: qualityContainerView.leadingAnchor, constant: 16),
            qualityProgressView.trailingAnchor.constraint(equalTo: qualityContainerView.trailingAnchor, constant: -16)
        ])
    }

    /// Calculate and update the scan quality indicator based on mesh metrics
    private func updateQualityIndicator(vertices: Int, triangles: Int, anchors: Int) {
        // Quality thresholds from configuration
        let config = Configuration.current.scanQuality
        let poor = config.poorVertexThreshold
        let fair = config.fairVertexThreshold
        let good = config.goodVertexThreshold

        let vertexScore: Float
        switch vertices {
        case 0..<poor: vertexScore = Float(vertices) / Float(poor) * 0.25
        case poor..<fair: vertexScore = 0.25 + Float(vertices - poor) / Float(fair - poor) * 0.25
        case fair..<good: vertexScore = 0.5 + Float(vertices - fair) / Float(good - fair) * 0.25
        default: vertexScore = 0.75 + min(Float(vertices - good) / Float(good), 1.0) * 0.25
        }

        // Also factor in triangle count and anchor coverage
        let triangleScore: Float = min(Float(triangles) / Float(config.maxTrianglesForScore), 1.0)
        let anchorScore: Float = min(Float(anchors) / Float(config.maxAnchorsForScore), 1.0)

        // Weighted average from configuration
        let quality = vertexScore * config.vertexWeight + triangleScore * config.triangleWeight + anchorScore * config.anchorWeight

        // Update UI
        qualityProgressView.setProgress(quality, animated: true)

        // Update label and color based on quality level
        let qualityText: String
        let qualityColor: UIColor

        switch quality {
        case 0..<0.25:
            qualityText = "Poor"
            qualityColor = .systemRed
        case 0.25..<0.5:
            qualityText = "Fair"
            qualityColor = .systemOrange
        case 0.5..<0.75:
            qualityText = "Good"
            qualityColor = .systemYellow
        default:
            qualityText = "Excellent"
            qualityColor = .systemGreen
        }

        qualityLabel.text = "Scan Quality: \(qualityText)"
        qualityProgressView.progressTintColor = qualityColor
    }

    private func setupDepthSlider() {
        // Depth label
        depthLabel = UILabel()
        depthLabel.text = "Max Depth: 2.0m"
        depthLabel.font = .systemFont(ofSize: 14, weight: .medium)
        depthLabel.textColor = .white
        depthLabel.textAlignment = .center
        depthLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(depthLabel)

        // Depth slider
        depthSlider = UISlider()
        depthSlider.minimumValue = 0.3
        depthSlider.maximumValue = 5.0
        depthSlider.value = maxDepth
        depthSlider.minimumTrackTintColor = .systemBlue
        depthSlider.maximumTrackTintColor = .gray
        depthSlider.addTarget(self, action: #selector(depthSliderChanged), for: .valueChanged)
        depthSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(depthSlider)

        // Min/Max labels
        let minLabel = UILabel()
        minLabel.text = "0.3m"
        minLabel.font = .systemFont(ofSize: 12)
        minLabel.textColor = .lightGray
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(minLabel)

        let maxLabel = UILabel()
        maxLabel.text = "5m"
        maxLabel.font = .systemFont(ofSize: 12)
        maxLabel.textColor = .lightGray
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(maxLabel)

        NSLayoutConstraint.activate([
            depthLabel.bottomAnchor.constraint(equalTo: finishButton.topAnchor, constant: -60),
            depthLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            depthSlider.topAnchor.constraint(equalTo: depthLabel.bottomAnchor, constant: 8),
            depthSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            depthSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),

            minLabel.topAnchor.constraint(equalTo: depthSlider.bottomAnchor, constant: 4),
            minLabel.leadingAnchor.constraint(equalTo: depthSlider.leadingAnchor),

            maxLabel.topAnchor.constraint(equalTo: depthSlider.bottomAnchor, constant: 4),
            maxLabel.trailingAnchor.constraint(equalTo: depthSlider.trailingAnchor)
        ])
    }

    @objc private func depthSliderChanged(_ sender: UISlider) {
        maxDepth = sender.value
        depthLabel.text = String(format: "Max Depth: %.1fm", maxDepth)
        updateDepthIndicator()
    }

    private func updateDepthIndicator() {
        // Remove existing indicator
        depthLimitIndicator?.removeFromParentNode()

        guard let cameraTransform = lastCameraTransform else { return }

        // Create a semi-transparent sphere showing the depth limit boundary
        let sphere = SCNSphere(radius: CGFloat(maxDepth))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red.withAlphaComponent(0.1)
        material.isDoubleSided = true
        material.fillMode = .lines
        material.lightingModel = .constant
        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)
        // Position at camera location
        let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        node.position = SCNVector3(cameraPosition.x, cameraPosition.y, cameraPosition.z)
        node.name = "DepthIndicator"

        sceneView.scene.rootNode.addChildNode(node)
        depthLimitIndicator = node
    }

    // MARK: - AR Session
    
    private func startARSession() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            logger.error("This device doesn't support LiDAR scanning")
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

        logger.info("AR session started with mesh reconstruction and scene depth")
    }
    
    // MARK: - Actions
    
    @objc private func finishButtonTapped() {
        sceneView.session.pause()
        
        // Build final mesh from all collected anchors
        let finalMesh = buildFinalMesh()
        onScanComplete?(finalMesh)
        dismiss(animated: true, completion: nil)
    }
    
    private func buildFinalMesh() -> MeshDTO {
        // Get camera position for depth filtering
        let cameraPosition: SIMD3<Float>
        if let transform = lastCameraTransform {
            cameraPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        } else {
            // Fallback to origin if no camera position available
            cameraPosition = SIMD3<Float>(0, 0, 0)
        }

        var allVertices: [SIMD3<Float>] = []
        var allIndices: [Int] = []
        var vertexOffset = 0
        let maxDepthSquared = maxDepth * maxDepth  // Avoid sqrt in distance checks

        for anchor in collectedMeshAnchors.values {
            let geometry = anchor.geometry

            // Map from original vertex index to filtered vertex index
            var vertexIndexMap: [Int: Int] = [:]
            var anchorVertices: [SIMD3<Float>] = []

            // Extract vertices with proper buffer access and depth filtering
            for i in 0..<geometry.vertices.count {
                let stride = geometry.vertices.stride
                let offset = geometry.vertices.offset + (stride * i)
                let vertexPointer = geometry.vertices.buffer.contents().advanced(by: offset)
                let localVertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee

                // Transform to world space
                let worldPos4 = anchor.transform * SIMD4<Float>(localVertex, 1.0)
                let worldPos = SIMD3<Float>(worldPos4.x, worldPos4.y, worldPos4.z)

                // Check distance from camera (squared to avoid sqrt)
                let delta = worldPos - cameraPosition
                let distanceSquared = delta.x * delta.x + delta.y * delta.y + delta.z * delta.z

                // Only include vertices within max depth
                if distanceSquared <= maxDepthSquared {
                    vertexIndexMap[i] = anchorVertices.count
                    anchorVertices.append(worldPos)
                }
            }

            // Extract face indices, only including triangles where ALL vertices are within depth
            let faceCount = geometry.faces.count
            let indexCount = faceCount * 3

            if geometry.faces.bytesPerIndex == 2 {
                let pointer = geometry.faces.buffer.contents().bindMemory(to: UInt16.self, capacity: indexCount)
                for faceIdx in 0..<faceCount {
                    let i0 = Int(pointer[faceIdx * 3])
                    let i1 = Int(pointer[faceIdx * 3 + 1])
                    let i2 = Int(pointer[faceIdx * 3 + 2])

                    // Only include triangle if all three vertices passed depth filter
                    if let newI0 = vertexIndexMap[i0],
                       let newI1 = vertexIndexMap[i1],
                       let newI2 = vertexIndexMap[i2] {
                        allIndices.append(newI0 + vertexOffset)
                        allIndices.append(newI1 + vertexOffset)
                        allIndices.append(newI2 + vertexOffset)
                    }
                }
            } else {
                let pointer = geometry.faces.buffer.contents().bindMemory(to: UInt32.self, capacity: indexCount)
                for faceIdx in 0..<faceCount {
                    let i0 = Int(pointer[faceIdx * 3])
                    let i1 = Int(pointer[faceIdx * 3 + 1])
                    let i2 = Int(pointer[faceIdx * 3 + 2])

                    // Only include triangle if all three vertices passed depth filter
                    if let newI0 = vertexIndexMap[i0],
                       let newI1 = vertexIndexMap[i1],
                       let newI2 = vertexIndexMap[i2] {
                        allIndices.append(newI0 + vertexOffset)
                        allIndices.append(newI1 + vertexOffset)
                        allIndices.append(newI2 + vertexOffset)
                    }
                }
            }

            // Add filtered vertices to final array
            allVertices.append(contentsOf: anchorVertices)
            vertexOffset += anchorVertices.count
        }

        logger.info("Depth filter: \(allVertices.count) vertices, \(allIndices.count / 3) triangles (max depth: \(maxDepth)m)")
        return MeshDTO(vertices: allVertices, triangleIndices: allIndices)
    }
}

// MARK: - ARSCNViewDelegate
// CRITICAL: This is how the mesh visualization actually happens!

extension ARScanViewController: ARSCNViewDelegate {

    // Called when a new anchor is added - create visualization node
    nonisolated public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }

        #if DEBUG
        print("Creating node for mesh anchor \(meshAnchor.identifier)")
        #endif

        // Create geometry from the mesh anchor (thread-safe operation)
        let geometry = createGeometryFromMeshAnchor(meshAnchor)

        // Create node with the geometry
        let node = SCNNode(geometry: geometry)
        node.name = "MeshNode_\(meshAnchor.identifier)"

        return node
    }

    // Called when an anchor is updated - update its visualization
    nonisolated public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return
        }

        // Update the node's geometry with the updated mesh
        let geometry = createGeometryFromMeshAnchor(meshAnchor)
        node.geometry = geometry
    }
    
    // Create SCNGeometry from ARMeshAnchor
    nonisolated private func createGeometryFromMeshAnchor(_ anchor: ARMeshAnchor) -> SCNGeometry {
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
//
// SWIFT 6 CONCURRENCY NOTES:
// --------------------------
// ARSessionDelegate methods are called from ARKit on a non-main thread.
// Since ARScanViewController is a UIViewController (implicitly @MainActor),
// these delegate methods must be marked `nonisolated` to satisfy the protocol.
//
// IMPORTANT: Avoid capturing ARMeshAnchor or ARFrame objects in Task closures.
// These retain ARFrame references and cause the warning:
// "The delegate is retaining N ARFrames"
//
// Pattern: Extract primitive data BEFORE dispatching to MainActor.

extension ARScanViewController: ARSessionDelegate {

    /// Called every frame (~60Hz). Updates UI and stores anchors for final mesh.
    ///
    /// - Note: This is `nonisolated` because ARSessionDelegate requires it.
    ///   We use DispatchQueue.main.async instead of Task { @MainActor } to
    ///   avoid ARFrame retention issues with Swift structured concurrency.
    nonisolated public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // STEP 1: Extract ALL data from ARKit objects synchronously
        // This prevents ARFrame retention by not capturing ARMeshAnchor in closures
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
        let totalVertices = meshAnchors.reduce(0) { $0 + $1.geometry.vertices.count }
        let totalTriangles = meshAnchors.reduce(0) { $0 + $1.geometry.faces.count }
        let anchorCount = meshAnchors.count
        let timestamp = frame.timestamp
        let cameraTransform = frame.camera.transform

        // STEP 2: Extract anchor data before dispatching to avoid capturing session
        // This prevents Swift 6 concurrency errors about sending 'session' across actor boundaries
        var anchorData: [(UUID, ARMeshAnchor)] = []
        for anchor in meshAnchors {
            anchorData.append((anchor.identifier, anchor))
        }

        // STEP 3: Dispatch to main thread for UI updates
        // Using DispatchQueue instead of Task to avoid structured concurrency
        // capturing ARMeshAnchor references
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Store camera position for depth filtering
            self.lastCameraTransform = cameraTransform

            // Store anchors for final mesh building using pre-extracted data
            for (identifier, meshAnchor) in anchorData {
                // Track insertion order for new anchors
                if self.collectedMeshAnchors[identifier] == nil {
                    self.anchorInsertionOrder.append(identifier)
                }
                self.collectedMeshAnchors[identifier] = meshAnchor
            }

            // Prune oldest anchors if count exceeds limit (FIFO eviction)
            while self.collectedMeshAnchors.count > self.maxAnchorCount,
                  !self.anchorInsertionOrder.isEmpty {
                let oldestId = self.anchorInsertionOrder.removeFirst()
                self.collectedMeshAnchors.removeValue(forKey: oldestId)
            }

            // Update UI with pre-computed statistics
            self.vertexCountLabel.text = "\(totalVertices) verts | \(totalTriangles) tris"
            self.updateQualityIndicator(vertices: totalVertices, triangles: totalTriangles, anchors: anchorCount)

            // Log periodically (every ~1 second)
            if timestamp.truncatingRemainder(dividingBy: 1.0) < 0.05 {
                self.logger.debug("AR update: \(anchorCount) anchors, \(totalVertices) vertices")
            }
        }
    }

    /// Called when new anchors are added to the session.
    nonisolated public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        #if DEBUG
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                print("Added mesh anchor with \(meshAnchor.geometry.vertices.count) vertices")
            }
        }
        #endif
    }
}

// MARK: - ARScanViewControllerProvider Implementation

/// Default provider for AR scan view controllers
/// This enables proper dependency injection for the AR scanning UI
@available(iOS 18.0, *)
public final class DefaultARScanViewControllerProvider: ARScanViewControllerProvider, @unchecked Sendable {

    public init() {}

    @MainActor
    public func makeViewController(onScanComplete: @escaping @Sendable (MeshDTO) -> Void) -> UIViewController {
        let controller = ARScanViewController()
        controller.onScanComplete = { meshDTO in onScanComplete(meshDTO) }
        return controller
    }
}

// MARK: - Service Registration

@available(iOS 18.0, *)
public extension DefaultDependencyContainer {

    /// Register AR view controller provider
    func registerARViewControllerProvider() {
        register(DefaultARScanViewControllerProvider(), for: ARScanViewControllerProvider.self)
    }
}

#endif
