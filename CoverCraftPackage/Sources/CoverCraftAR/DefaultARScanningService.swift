// Version: 1.0.0
// CoverCraft AR Module - Default AR Scanning Service Implementation

#if !os(macOS) && canImport(ARKit)
import Foundation
import ARKit
import RealityKit
import AVFoundation
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Default implementation of AR scanning service
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public final class DefaultARScanningService: ARScanningService {
    
    // MARK: - Properties
    
    private let logger = Logger(label: "com.covercraft.ar.scanning")
    private var arSession: ARSession?
    private var meshAnchor: ARMeshAnchor?
    private var isScanning = false
    
    // MARK: - Initialization
    
    public init() {
        logger.info("AR Scanning Service initialized")
    }
    
    // MARK: - ARScanningService Implementation
    
    public func startScanning() async throws {
        logger.info("Starting AR scanning session")

        guard #available(iOS 18.0, macOS 15.0, *) else {
            throw ARScanningError.deviceNotSupported
        }

        guard isARAvailable() else {
            throw ARScanningError.deviceNotSupported
        }
        
        // Check camera permissions
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus != .authorized {
            if cameraStatus == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard granted else {
                    throw ARScanningError.cameraPermissionDenied
                }
            } else {
                throw ARScanningError.cameraPermissionDenied
            }
        }
        
        do {
            let session = ARSession()
            let config = ARWorldTrackingConfiguration()
            
            // Enable scene reconstruction for LiDAR
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                config.sceneReconstruction = .mesh
            } else {
                throw ARScanningError.deviceNotSupported
            }
            
            // Configure plane detection
            config.planeDetection = [.horizontal, .vertical]
            
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
            
            arSession = session
            isScanning = true
            
            logger.info("AR scanning session started successfully")
            
        } catch {
            logger.error("Failed to start AR session: \(error)")
            throw ARScanningError.sessionFailed(error)
        }
    }
    
    public func stopScanning() async {
        logger.info("Stopping AR scanning session")
        
        arSession?.pause()
        arSession = nil
        isScanning = false
        
        logger.info("AR scanning session stopped")
    }
    
    public func getCurrentMesh() async -> MeshDTO? {
        guard isScanning,
              let session = arSession else {
            logger.warning("Attempted to get mesh without active session")
            return nil
        }
        
        // Find mesh anchors in current frame
        let meshAnchors = session.currentFrame?.anchors.compactMap { $0 as? ARMeshAnchor } ?? []
        
        guard !meshAnchors.isEmpty else {
            logger.debug("No mesh anchors found in current frame")
            return nil
        }
        
        // Combine all mesh anchors into single mesh
        do {
            let combinedMesh = try await combineMeshAnchors(meshAnchors)
            logger.debug("Successfully created mesh with \(combinedMesh.vertices.count) vertices")
            return combinedMesh
        } catch {
            logger.error("Failed to create mesh from anchors: \(error)")
            return nil
        }
    }
    
    nonisolated public func isARAvailable() -> Bool {
        // Check for LiDAR support
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            return false
        }
        
        // Check camera availability
        guard AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// Immutable snapshot of an ARMeshAnchor's geometry buffers, safe to read off the ARKit thread.
    private struct AnchorSnapshot: Sendable {
        let transform: simd_float4x4
        let vertexData: Data
        let vertexStride: Int
        let vertexOffset: Int
        let vertexCount: Int
        let faceData: Data
        let faceCount: Int
        let bytesPerIndex: Int
        let indicesPerFace: Int
    }

    private func combineMeshAnchors(_ anchors: [ARMeshAnchor]) async throws -> MeshDTO {
        // Snapshot ARKit-owned buffers on the caller thread before dispatching; reading
        // `anchor.geometry.*.buffer.contents()` concurrently with ARKit's writer is a data race.
        let snapshots: [AnchorSnapshot] = anchors.map { anchor in
            let g = anchor.geometry
            let v = g.vertices
            let f = g.faces
            let vData = Data(bytes: v.buffer.contents(), count: v.buffer.length)
            let fData = Data(bytes: f.buffer.contents(), count: f.buffer.length)
            return AnchorSnapshot(
                transform: anchor.transform,
                vertexData: vData,
                vertexStride: v.stride,
                vertexOffset: v.offset,
                vertexCount: v.count,
                faceData: fData,
                faceCount: f.count,
                bytesPerIndex: f.bytesPerIndex,
                indicesPerFace: f.indexCountPerPrimitive
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var allVertices: [SIMD3<Float>] = []
                var allTriangleIndices: [Int] = []
                var vertexOffset = 0

                for snap in snapshots {
                    guard snap.indicesPerFace == 3 else {
                        continuation.resume(throwing: ARScanningError.meshGenerationFailed("Unsupported face primitive size: \(snap.indicesPerFace)"))
                        return
                    }
                    guard snap.bytesPerIndex == 2 || snap.bytesPerIndex == 4 else {
                        continuation.resume(throwing: ARScanningError.meshGenerationFailed("Unsupported index size: \(snap.bytesPerIndex) bytes"))
                        return
                    }

                    snap.vertexData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                        guard let base = raw.baseAddress else { return }
                        for i in 0..<snap.vertexCount {
                            let offset = snap.vertexOffset + (i * snap.vertexStride)
                            let vertex = base.advanced(by: offset)
                                .assumingMemoryBound(to: SIMD3<Float>.self)
                                .pointee
                            let worldVertex4 = snap.transform * SIMD4<Float>(vertex, 1.0)
                            allVertices.append(SIMD3<Float>(worldVertex4.x, worldVertex4.y, worldVertex4.z))
                        }
                    }

                    snap.faceData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                        guard let base = raw.baseAddress else { return }
                        for i in 0..<snap.faceCount {
                            let offset = i * snap.indicesPerFace * snap.bytesPerIndex
                            if snap.bytesPerIndex == 2 {
                                let indexPtr = base.advanced(by: offset)
                                    .assumingMemoryBound(to: UInt16.self)
                                allTriangleIndices.append(Int(indexPtr[0]) + vertexOffset)
                                allTriangleIndices.append(Int(indexPtr[1]) + vertexOffset)
                                allTriangleIndices.append(Int(indexPtr[2]) + vertexOffset)
                            } else {
                                let indexPtr = base.advanced(by: offset)
                                    .assumingMemoryBound(to: UInt32.self)
                                allTriangleIndices.append(Int(indexPtr[0]) + vertexOffset)
                                allTriangleIndices.append(Int(indexPtr[1]) + vertexOffset)
                                allTriangleIndices.append(Int(indexPtr[2]) + vertexOffset)
                            }
                        }
                    }

                    vertexOffset += snap.vertexCount
                }
                
                guard !allVertices.isEmpty && !allTriangleIndices.isEmpty else {
                    continuation.resume(throwing: ARScanningError.insufficientData)
                    return
                }
                
                let mesh = MeshDTO(
                    vertices: allVertices,
                    triangleIndices: allTriangleIndices
                )
                continuation.resume(returning: mesh)
            }
        }
    }
}

// MARK: - Service Registration

@available(iOS 18.0, macOS 15.0, *)
public extension DefaultDependencyContainer {
    
    /// Register AR services
    @MainActor
    func registerARServices() {
        let logger = Logger(label: "com.covercraft.ar.registration")
        logger.info("Registering AR services")
        
        // Eagerly construct and register on MainActor to avoid `assumeIsolated` traps
        // and to prevent background-thread factory invocation from crashing.
        register(DefaultARScanningService(), for: ARScanningService.self)
        
        logger.info("AR services registration completed")
    }
}

#else
// MARK: - macOS Stub Implementation

import Foundation
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Stub implementation for macOS where ARKit is not available
@available(macOS 15.0, *)
public final class DefaultARScanningService: ARScanningService {
    
    private let logger = Logger(label: "com.covercraft.ar.scanning.stub")
    
    public init() {
        logger.info("AR Scanning Service stub initialized (macOS)")
    }
    
    public func startScanning() async throws {
        logger.warning("AR scanning not available on macOS")
        throw ARScanningError.deviceNotSupported
    }
    
    public func stopScanning() async {
        logger.debug("AR scanning stub: stop called")
    }
    
    public func getCurrentMesh() async -> MeshDTO? {
        logger.debug("AR scanning stub: getCurrentMesh called")
        return nil
    }
    
    nonisolated public func isARAvailable() -> Bool {
        return false
    }
}

// MARK: - Service Registration (macOS)

@available(macOS 15.0, *)
public extension DefaultDependencyContainer {
    
    /// Register AR services (macOS stub)
    func registerARServices() {
        let logger = Logger(label: "com.covercraft.ar.registration.stub")
        logger.info("Registering AR services (macOS stub)")
        
        registerSingleton({
            DefaultARScanningService()
        }, for: ARScanningService.self)
        
        logger.info("AR services registration completed (macOS stub)")
    }
}

#endif
