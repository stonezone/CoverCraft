// Version: 1.0.0
// Simple dependency injection container for CoverCraft

import Foundation
import SwiftUI

/// Simple service container for dependency injection
@MainActor
public final class ServiceContainer: @unchecked Sendable {
    private var services: [String: Any] = [:]
    
    /// Shared instance for global access
    public static let shared = ServiceContainer()
    
    private init() {}
    
    /// Register a service instance
    public func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }
    
    /// Resolve a service instance
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
    
    /// Remove a service registration
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        services.removeValue(forKey: key)
    }
    
    /// Clear all registered services
    public func clear() {
        services.removeAll()
    }
    
    /// Check if a service is registered
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return services[key] != nil
    }
}

/// SwiftUI Environment key for service container  
public struct ServiceContainerKey: EnvironmentKey {
    nonisolated(unsafe) public static let defaultValue: ServiceContainer = ServiceContainer.shared
}

/// SwiftUI Environment extension for easy access
public extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

/// Service registration extensions
public extension ServiceContainer {
    /// Register default CoverCraft services
    func registerCoverCraftServices() {
        // Services will be registered here when implementations are created
        // Example:
        // register(MeshSegmentationService(), for: MeshSegmentationContract.self)
    }
}