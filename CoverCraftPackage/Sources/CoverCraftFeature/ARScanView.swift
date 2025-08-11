import SwiftUI

#if canImport(UIKit)
import UIKit

/// SwiftUI wrapper for AR scanning view controller
public struct ARScanView: UIViewControllerRepresentable {
    @Binding public var scannedMesh: Mesh?
    @Environment(\.dismiss) private var dismiss
    
    public init(scannedMesh: Binding<Mesh?>) {
        self._scannedMesh = scannedMesh
    }
    
    public func makeUIViewController(context: Context) -> ARScanViewController {
        let controller = ARScanViewController()
        controller.onScanComplete = { mesh in
            scannedMesh = mesh
            dismiss()
        }
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: ARScanViewController, context: Context) {
        // No updates needed
    }
}
#endif