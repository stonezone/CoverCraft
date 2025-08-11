import SwiftUI
import CoverCraftFeature
import CoverCraftCore
import CoverCraftAR
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport

@main
struct CoverCraftApp: App {
    init() {
        let container = DefaultDependencyContainer.shared
        container.registerCoreServices()
        container.registerARServices()
        container.registerCalibrationServices()
        container.registerSegmentationServices()
        container.registerFlatteningServices()
        container.registerExportServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencyContainer, DefaultDependencyContainer.shared)
        }
    }
}