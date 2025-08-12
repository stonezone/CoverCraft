import SwiftUI

import SwiftUI
import CoverCraftDTO
import CoverCraftCore
import CoverCraftAR

#if canImport(UIKit)
import UIKit

/// SwiftUI wrapper for AR scanning view controller
@available(iOS 18.0, macOS 15.0, *)
public struct ARScanView: UIViewControllerRepresentable {
    @Binding public var scannedMesh: MeshDTO?
    @Environment(\.dismiss) private var dismiss
    
    public init(scannedMesh: Binding<MeshDTO?>) {
        self._scannedMesh = scannedMesh
    }
    
    public func makeUIViewController(context: Context) -> ARScanViewController {
        let controller = ARScanViewController()
        controller.onScanComplete = { mesh in
            // Convert AR Mesh to MeshDTO
            let meshDTO = MeshDTO(
                vertices: mesh.vertices,
                triangleIndices: mesh.triangleIndices,
                id: UUID(),
                createdAt: Date()
            )
            scannedMesh = meshDTO
            dismiss()
        }
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: ARScanViewController, context: Context) {
        // No updates needed
    }
}
#endif