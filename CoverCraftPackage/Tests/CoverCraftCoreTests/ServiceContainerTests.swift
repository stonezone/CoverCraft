// Version: 1.0.0
// CoverCraft Core Tests - Service Container Tests

import Foundation
import Testing
@testable import CoverCraftCore

@MainActor
@Suite("ServiceContainer Tests")
struct ServiceContainerTests {
    
    @Test("Service registration and resolution")
    func serviceRegistrationAndResolution() {
        let container = DefaultDependencyContainer()
        let testService = TestService()
        
        container.register(testService, for: TestService.self)
        
        let resolved = container.resolve(TestService.self)
        #expect(resolved === testService)
        #expect(container.isRegistered(TestService.self))
    }
    
    @Test("Factory registration")
    func factoryRegistration() {
        let container = DefaultDependencyContainer()
        
        container.registerFactory({
            TestService()
        }, for: TestService.self)
        
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        
        #expect(instance1 != nil)
        #expect(instance2 != nil)
        #expect(instance1 !== instance2) // Different instances each time
    }
    
    @Test("Singleton registration")
    func singletonRegistration() {
        let container = DefaultDependencyContainer()
        
        container.registerSingleton({
            TestService()
        }, for: TestService.self)
        
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        
        #expect(instance1 != nil)
        #expect(instance2 != nil)
        #expect(instance1 === instance2) // Same instance both times
    }
    
    @Test("Service not found")
    func serviceNotFound() {
        let container = DefaultDependencyContainer()
        
        let resolved = container.resolve(TestService.self)
        #expect(resolved == nil)
        #expect(!container.isRegistered(TestService.self))
    }
    
    @Test("Service requirement with error")
    func serviceRequirementWithError() {
        let container = DefaultDependencyContainer()
        
        #expect(throws: ServiceContainerError.self) {
            try container.requireService(TestService.self)
        }
    }
    
    @Test("Service unregistration")
    func serviceUnregistration() {
        let container = DefaultDependencyContainer()
        let testService = TestService()
        
        container.register(testService, for: TestService.self)
        #expect(container.isRegistered(TestService.self))
        
        container.unregister(TestService.self)
        #expect(!container.isRegistered(TestService.self))
        
        let resolved = container.resolve(TestService.self)
        #expect(resolved == nil)
    }
    
    @Test("Container clear")
    func containerClear() {
        let container = DefaultDependencyContainer()
        
        container.register(TestService(), for: TestService.self)
        container.registerFactory({ AnotherTestService() }, for: AnotherTestService.self)
        
        #expect(container.isRegistered(TestService.self))
        #expect(container.isRegistered(AnotherTestService.self))
        
        container.clear()
        
        #expect(!container.isRegistered(TestService.self))
        #expect(!container.isRegistered(AnotherTestService.self))
    }

    @Test("Nested resolution inside factory")
    func nestedResolutionInsideFactory() {
        let container = DefaultDependencyContainer()

        container.register(Dependency(), for: Dependency.self)
        container.registerFactory({
            // This would deadlock with a non-recursive lock.
            let dep = container.resolve(Dependency.self)
            return FactoryProduct(dependency: dep)
        }, for: FactoryProduct.self)

        let resolved = container.resolve(FactoryProduct.self)
        #expect(resolved != nil)
        #expect(resolved?.dependency != nil)
    }
}

// MARK: - Test Services

private final class TestService {
    let id = UUID()
}

private final class AnotherTestService {
    let id = UUID()
}

private final class Dependency {}

private final class FactoryProduct {
    let dependency: Dependency?
    init(dependency: Dependency?) {
        self.dependency = dependency
    }
}
