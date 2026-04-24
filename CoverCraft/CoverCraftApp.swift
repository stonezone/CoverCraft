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
        Self.resetUITestExportsIfRequested()

        #if DEBUG
        DebugFileLogging.prepareSession()
        #endif

        LoggingSystem.bootstrap { label in
            #if DEBUG
            return MultiplexLogHandler([
                StreamLogHandler.standardOutput(label: label),
                DebugFileLogHandler(label: label)
            ])
            #else
            return StreamLogHandler.standardOutput(label: label)
            #endif
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

    private static func resetUITestExportsIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("UITEST_RESET_EXPORTS") else {
            return
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let patternsFolder = documentsURL.appendingPathComponent("CoverCraft Patterns", isDirectory: true)
        try? FileManager.default.removeItem(at: patternsFolder)
    }
}
