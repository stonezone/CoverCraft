import SwiftUI
import Logging
import CoverCraftFeature
import CoverCraftCore
import CoverCraftAR
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport

@main
@MainActor
struct CoverCraftApp: App {
    init() {
        LoggingSystem.bootstrap { label in
            StreamLogHandler.standardOutput(label: label)
        }

        let container = DefaultDependencyContainer.shared
        container.registerCoreServices()
        container.registerARServices()
        container.registerARViewControllerProvider()  // NEW: Register AR view controller provider for DI
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
