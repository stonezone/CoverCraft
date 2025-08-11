// Version: 1.0.0
// CoverCraft Core Module - Dependency Injection Container

import Foundation
import SwiftUI
import Logging

/// Protocol for dependency injection containers
public protocol DependencyContainer: Sendable {
    func register<T>(_ service: T, for type: T.Type)
    func registerFactory<T>(_ factory: @escaping () -> T, for type: T.Type)
    func registerSingleton<T>(_ factory: @escaping () -> T, for type: T.Type)
    func resolve<T>(_ type: T.Type) -> T?
    func requireService<T>(_ type: T.Type) throws -> T
    func isRegistered<T>(_ type: T.Type) -> Bool
}

/// Service container errors
public enum ServiceContainerError: Error, LocalizedError {
    case serviceNotFound(String)
    case circularDependency(String)
    case registrationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotFound(let service):
            return "Service not found: \(service)"
        case .circularDependency(let service):
            return "Circular dependency detected: \(service)"
        case .registrationFailed(let service):
            return "Failed to register service: \(service)"
        }
    }
}

/// Default implementation of dependency injection container
@MainActor
public final class DefaultDependencyContainer: DependencyContainer, @unchecked Sendable {
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private var resolutionStack: Set<String> = []
    private let logger = Logger(label: "com.covercraft.dependency-container")
    
    /// Shared instance for global access
    public static let shared = DefaultDependencyContainer()
    
    public init() {}
    
    /// Register a service instance
    public func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
        logger.info("Registered service: \(key)")
    }
    
    /// Register a service factory for lazy instantiation
    public func registerFactory<T>(_ factory: @escaping () -> T, for type: T.Type) {
        let key = String(describing: type)
        factories[key] = factory
        logger.info("Registered factory: \(key)")
    }
    
    /// Register a singleton factory
    public func registerSingleton<T>(_ factory: @escaping () -> T, for type: T.Type) {
        let key = String(describing: type)
        factories[key] = {
            let instance = factory()
            self.services[key] = instance
            self.logger.info("Created singleton: \(key)")
            return instance
        }
        logger.info("Registered singleton factory: \(key)")
    }
    
    /// Resolve a service instance
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check for circular dependencies
        guard !resolutionStack.contains(key) else {
            logger.error("Circular dependency detected for: \(key)")
            return nil
        }
        
        // Check if instance already exists
        if let service = services[key] as? T {
            return service
        }
        
        // Try to create from factory
        if let factory = factories[key] {
            resolutionStack.insert(key)
            defer { resolutionStack.remove(key) }
            
            let instance = factory() as? T
            logger.debug("Created instance: \(key)")
            return instance
        }
        
        logger.warning("Service not found: \(key)")
        return nil
    }
    
    /// Resolve a service instance or throw error
    public func requireService<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw ServiceContainerError.serviceNotFound(String(describing: type))
        }
        return service
    }
    
    /// Remove a service registration
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
        logger.info("Unregistered service: \(key)")
    }
    
    /// Clear all registered services
    public func clear() {
        let count = services.count + factories.count
        services.removeAll()
        factories.removeAll()
        logger.info("Cleared \(count) service registrations")
    }
    
    /// Check if a service is registered
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return services[key] != nil || factories[key] != nil
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI Environment key for dependency container
public struct DependencyContainerKey: EnvironmentKey {
    public static let defaultValue: DependencyContainer = DefaultDependencyContainer.shared
}

/// SwiftUI Environment extension for easy access
public extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - Service Registration Helpers

public extension DefaultDependencyContainer {
    
    /// Register core CoverCraft services
    func registerCoreServices() {
        logger.info("Registering core CoverCraft services")
        
        // Register logging service
        register(logger, for: Logger.self)
        
        // Services will be registered by their respective modules
        logger.info("Core services registration completed")
    }
}