import SwiftUI
import CoverCraftDTO
import CoverCraftCore
import CoverCraftAR

#if canImport(UIKit)
import UIKit

/// SwiftUI wrapper for AR scanning view controller
/// Uses dependency injection to obtain the view controller provider
@available(iOS 18.0, macOS 15.0, *)
public struct ARScanView: UIViewControllerRepresentable {
    @Binding public var scannedMesh: MeshDTO?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var container

    public init(scannedMesh: Binding<MeshDTO?>) {
        self._scannedMesh = scannedMesh
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        guard let provider = container.resolve(ARScanViewControllerProvider.self) else {
            #if DEBUG
            assertionFailure("ARScanViewControllerProvider not registered in DI container")
            #endif
            // Return placeholder in production to avoid crash
            return UIHostingController(rootView:
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("AR Scanner not configured")
                }
            )
        }
        return provider.makeViewController { meshDTO in
            scannedMesh = meshDTO
            dismiss()
        }
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
#endif
