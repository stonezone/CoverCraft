import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Service for providing haptic feedback on supported devices
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public protocol HapticService: Sendable {
    /// Trigger haptic feedback for successful actions
    func success()
    /// Trigger haptic feedback for warnings
    func warning()
    /// Trigger haptic feedback for errors
    func error()
    /// Trigger light haptic feedback for selections/taps
    func selection()
    /// Trigger medium haptic feedback for notable actions
    func impact()
    /// Trigger heavy haptic feedback for significant completions
    func heavyImpact()
}

/// Default implementation of HapticService
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public final class DefaultHapticService: HapticService {

    #if canImport(UIKit) && !os(watchOS)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    #endif

    public init() {
        #if canImport(UIKit) && !os(watchOS)
        // Prepare generators for faster response
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        #endif
    }

    public func success() {
        #if canImport(UIKit) && !os(watchOS)
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        #endif
    }

    public func warning() {
        #if canImport(UIKit) && !os(watchOS)
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
        #endif
    }

    public func error() {
        #if canImport(UIKit) && !os(watchOS)
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
        #endif
    }

    public func selection() {
        #if canImport(UIKit) && !os(watchOS)
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
        #endif
    }

    public func impact() {
        #if canImport(UIKit) && !os(watchOS)
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
        #endif
    }

    public func heavyImpact() {
        #if canImport(UIKit) && !os(watchOS)
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
        #endif
    }
}

// MARK: - Service Registration

@available(iOS 18.0, *)
public extension DefaultDependencyContainer {
    /// Register the haptic feedback service
    @MainActor
    func registerHapticService() {
        register(DefaultHapticService(), for: HapticService.self)
    }
}
