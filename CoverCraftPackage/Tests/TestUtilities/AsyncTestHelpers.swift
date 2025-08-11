// Version: 1.0.0
// CoverCraft Test Utilities - Async Test Helpers
// 
// TDD-compliant helpers for testing async operations and concurrent behavior
// Provides deterministic async testing utilities following modern Swift concurrency patterns

import Foundation
import Testing
import XCTest

/// Collection of utilities for testing async/await operations
/// 
/// Provides helpers for timeout handling, concurrent testing, task management,
/// and async expectation verification. All utilities are designed for Swift Testing framework.
@available(iOS 18.0, *)
public final class AsyncTestHelpers {
    
    // MARK: - Timeout Configuration
    
    /// Default timeout for async operations in tests (5 seconds)
    public static let defaultTimeout: TimeInterval = 5.0
    
    /// Short timeout for fast operations (1 second) 
    public static let shortTimeout: TimeInterval = 1.0
    
    /// Long timeout for complex operations (10 seconds)
    public static let longTimeout: TimeInterval = 10.0
    
    // MARK: - Async Task Testing
    
    /// Execute async operation with timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait (default: 5 seconds)
    ///   - operation: Async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: TimeoutError if operation exceeds timeout, or operation's error
    public static func withTimeout<T>(
        _ timeout: TimeInterval = defaultTimeout,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation task
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(duration: timeout)
            }
            
            // Return first completed result and cancel others
            defer { group.cancelAll() }
            
            guard let result = try await group.next() else {
                throw AsyncTestError.unexpectedNil
            }
            
            return result
        }
    }
    
    /// Execute async operation and measure execution time
    /// - Parameter operation: Async operation to execute
    /// - Returns: Tuple of (result, executionTime)
    /// - Throws: Operation's error
    public static func measureAsync<T>(
        operation: @escaping () async throws -> T
    ) async throws -> (result: T, executionTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return (result: result, executionTime: executionTime)
    }
    
    /// Verify async operation completes within expected time
    /// - Parameters:
    ///   - maxDuration: Maximum expected duration
    ///   - operation: Async operation to test
    /// - Throws: TimingError if operation takes too long, or operation's error
    public static func expectTimingWithin<T>(
        _ maxDuration: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let (result, executionTime) = try await measureAsync(operation: operation)
        
        if executionTime > maxDuration {
            throw AsyncTestError.tooSlow(
                expected: maxDuration,
                actual: executionTime
            )
        }
        
        return result
    }
    
    // MARK: - Concurrent Testing
    
    /// Execute multiple async operations concurrently
    /// - Parameters:
    ///   - operations: Array of async operations
    ///   - timeout: Maximum time to wait for all operations
    /// - Returns: Array of results in same order as operations
    /// - Throws: TimeoutError or first operation error
    public static func executeConcurrently<T>(
        operations: [@escaping () async throws -> T],
        timeout: TimeInterval = defaultTimeout
    ) async throws -> [T] {
        return try await withTimeout(timeout) {
            try await withThrowingTaskGroup(of: (Int, T).self) { group in
                // Start all operations
                for (index, operation) in operations.enumerated() {
                    group.addTask {
                        let result = try await operation()
                        return (index, result)
                    }
                }
                
                // Collect results in order
                var results: [(Int, T)] = []
                results.reserveCapacity(operations.count)
                
                for try await indexedResult in group {
                    results.append(indexedResult)
                }
                
                // Sort by original index and extract values
                results.sort { $0.0 < $1.0 }
                return results.map { $0.1 }
            }
        }
    }
    
    /// Execute operations sequentially and verify order
    /// - Parameters:
    ///   - operations: Array of async operations with identifiers
    ///   - timeout: Maximum time for all operations
    /// - Returns: Array of results in execution order
    /// - Throws: TimeoutError or operation error
    public static func executeSequentially<T>(
        operations: [(id: String, operation: () async throws -> T)],
        timeout: TimeInterval = longTimeout
    ) async throws -> [(id: String, result: T)] {
        return try await withTimeout(timeout) {
            var results: [(id: String, result: T)] = []
            
            for (id, operation) in operations {
                let result = try await operation()
                results.append((id: id, result: result))
            }
            
            return results
        }
    }
    
    // MARK: - Task Management Testing
    
    /// Test task cancellation behavior
    /// - Parameters:
    ///   - operation: Operation that should respond to cancellation
    ///   - cancelAfter: Time after which to cancel (default: 0.1 seconds)
    /// - Returns: Whether task was properly cancelled
    public static func testCancellation<T>(
        operation: @escaping () async throws -> T,
        cancelAfter: TimeInterval = 0.1
    ) async -> Bool {
        let task = Task {
            try await operation()
        }
        
        // Wait a bit then cancel
        try? await Task.sleep(nanoseconds: UInt64(cancelAfter * 1_000_000_000))
        task.cancel()
        
        do {
            _ = try await task.value
            return false // Task completed instead of cancelling
        } catch is CancellationError {
            return true // Task properly cancelled
        } catch {
            return false // Task threw different error
        }
    }
    
    /// Verify task group cancellation behavior
    /// - Parameter groupOperation: Operation using TaskGroup
    /// - Returns: Whether group properly handles cancellation
    public static func testGroupCancellation<T>(
        groupOperation: @escaping () async throws -> T
    ) async -> Bool {
        let task = Task {
            try await groupOperation()
        }
        
        // Cancel immediately
        task.cancel()
        
        do {
            _ = try await task.value
            return false // Should have been cancelled
        } catch is CancellationError {
            return true // Properly cancelled
        } catch {
            return false // Wrong error type
        }
    }
    
    // MARK: - Actor Testing Helpers
    
    /// Test actor isolation by attempting concurrent access
    /// - Parameters:
    ///   - actor: Actor to test
    ///   - accessOperations: Operations to perform concurrently on actor
    /// - Returns: Whether all operations completed successfully
    public static func testActorIsolation<A: Actor, T>(
        actor: A,
        accessOperations: [@escaping (A) async throws -> T]
    ) async -> Bool {
        do {
            _ = try await executeConcurrently(
                operations: accessOperations.map { operation in
                    { try await operation(actor) }
                }
            )
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Assertion Helpers for Async
    
    /// Assert that async operation throws expected error type
    /// - Parameters:
    ///   - expectedErrorType: Type of error expected
    ///   - operation: Async operation that should throw
    /// - Throws: AssertionError if wrong error type or no error
    public static func expectAsyncThrows<E: Error, T>(
        _ expectedErrorType: E.Type,
        operation: @escaping () async throws -> T
    ) async throws {
        do {
            _ = try await operation()
            throw AsyncTestError.expectedError(type: String(describing: expectedErrorType))
        } catch let error as E {
            // Expected error type - test passes
            return
        } catch {
            throw AsyncTestError.wrongErrorType(
                expected: String(describing: expectedErrorType),
                actual: String(describing: type(of: error))
            )
        }
    }
    
    /// Assert that async operation completes without throwing
    /// - Parameter operation: Async operation that should succeed
    /// - Returns: Result of the operation
    /// - Throws: AssertionError if operation throws
    public static func expectAsyncNoThrow<T>(
        operation: @escaping () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw AsyncTestError.unexpectedError(error: error)
        }
    }
    
    /// Assert async operation result matches expectation
    /// - Parameters:
    ///   - expected: Expected result
    ///   - operation: Async operation to test
    /// - Throws: AssertionError if results don't match
    public static func expectAsyncEqual<T: Equatable>(
        _ expected: T,
        operation: @escaping () async throws -> T
    ) async throws {
        let result = try await operation()
        
        if result != expected {
            throw AsyncTestError.valuesMismatch(
                expected: String(describing: expected),
                actual: String(describing: result)
            )
        }
    }
    
    // MARK: - State Change Testing
    
    /// Wait for async state change with polling
    /// - Parameters:
    ///   - condition: Condition to check
    ///   - timeout: Maximum time to wait
    ///   - pollInterval: How often to check condition (default: 0.01 seconds)
    /// - Throws: TimeoutError if condition not met within timeout
    public static func waitForCondition(
        condition: @escaping () async -> Bool,
        timeout: TimeInterval = defaultTimeout,
        pollInterval: TimeInterval = 0.01
    ) async throws {
        let endTime = Date().addingTimeInterval(timeout)
        
        while Date() < endTime {
            if await condition() {
                return // Condition met
            }
            
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        
        throw AsyncTestError.conditionNotMet(timeout: timeout)
    }
    
    /// Wait for multiple conditions to be met
    /// - Parameters:
    ///   - conditions: Array of conditions that must all be true
    ///   - timeout: Maximum time to wait
    /// - Throws: TimeoutError if not all conditions met
    public static func waitForAllConditions(
        conditions: [@escaping () async -> Bool],
        timeout: TimeInterval = defaultTimeout
    ) async throws {
        try await waitForCondition(
            condition: {
                for condition in conditions {
                    if await !condition() {
                        return false
                    }
                }
                return true
            },
            timeout: timeout
        )
    }
    
    // MARK: - Performance Testing Helpers
    
    /// Benchmark async operation over multiple iterations
    /// - Parameters:
    ///   - iterations: Number of times to run operation
    ///   - operation: Async operation to benchmark
    /// - Returns: Performance statistics
    public static func benchmark<T>(
        iterations: Int,
        operation: @escaping () async throws -> T
    ) async throws -> PerformanceStats {
        guard iterations > 0 else {
            throw AsyncTestError.invalidIterationCount(iterations)
        }
        
        var executionTimes: [TimeInterval] = []
        executionTimes.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let (_, executionTime) = try await measureAsync(operation: operation)
            executionTimes.append(executionTime)
        }
        
        return PerformanceStats(executionTimes: executionTimes)
    }
    
    // MARK: - Mock Async Behavior
    
    /// Create async operation that completes after delay
    /// - Parameters:
    ///   - delay: Delay in seconds
    ///   - result: Result to return
    /// - Returns: Async operation that returns result after delay
    public static func delayedResult<T>(
        delay: TimeInterval,
        result: T
    ) -> () async throws -> T {
        return {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return result
        }
    }
    
    /// Create async operation that throws after delay
    /// - Parameters:
    ///   - delay: Delay in seconds
    ///   - error: Error to throw
    /// - Returns: Async operation that throws after delay
    public static func delayedError<T>(
        delay: TimeInterval,
        error: Error
    ) -> () async throws -> T {
        return {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            throw error
        }
    }
    
    /// Create async operation that randomly succeeds or fails
    /// - Parameters:
    ///   - successProbability: Probability of success (0.0-1.0)
    ///   - result: Result to return on success
    ///   - error: Error to throw on failure
    /// - Returns: Async operation with random outcome
    public static func randomOutcome<T>(
        successProbability: Double,
        result: T,
        error: Error
    ) -> () async throws -> T {
        return {
            let random = Double.random(in: 0...1)
            if random < successProbability {
                return result
            } else {
                throw error
            }
        }
    }
}

// MARK: - Error Types

@available(iOS 18.0, *)
public enum AsyncTestError: Error, Equatable, LocalizedError {
    case timeout(duration: TimeInterval)
    case tooSlow(expected: TimeInterval, actual: TimeInterval)
    case unexpectedNil
    case expectedError(type: String)
    case wrongErrorType(expected: String, actual: String)
    case unexpectedError(error: Error)
    case valuesMismatch(expected: String, actual: String)
    case conditionNotMet(timeout: TimeInterval)
    case invalidIterationCount(Int)
    
    public var errorDescription: String? {
        switch self {
        case .timeout(let duration):
            return "Operation timed out after \(duration) seconds"
        case .tooSlow(let expected, let actual):
            return "Operation too slow: expected ≤\(expected)s, actual: \(actual)s"
        case .unexpectedNil:
            return "Unexpected nil result from async operation"
        case .expectedError(let type):
            return "Expected error of type \(type) but operation succeeded"
        case .wrongErrorType(let expected, let actual):
            return "Expected error type \(expected) but got \(actual)"
        case .unexpectedError(let error):
            return "Unexpected error: \(error.localizedDescription)"
        case .valuesMismatch(let expected, let actual):
            return "Values mismatch: expected \(expected), actual \(actual)"
        case .conditionNotMet(let timeout):
            return "Condition not met within \(timeout) seconds"
        case .invalidIterationCount(let count):
            return "Invalid iteration count: \(count)"
        }
    }
    
    public static func == (lhs: AsyncTestError, rhs: AsyncTestError) -> Bool {
        switch (lhs, rhs) {
        case (.timeout(let a), .timeout(let b)):
            return a == b
        case (.tooSlow(let a1, let a2), .tooSlow(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.unexpectedNil, .unexpectedNil):
            return true
        case (.expectedError(let a), .expectedError(let b)):
            return a == b
        case (.wrongErrorType(let a1, let a2), .wrongErrorType(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.valuesMismatch(let a1, let a2), .valuesMismatch(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.conditionNotMet(let a), .conditionNotMet(let b)):
            return a == b
        case (.invalidIterationCount(let a), .invalidIterationCount(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Performance Statistics

@available(iOS 18.0, *)
public struct PerformanceStats: Sendable {
    public let executionTimes: [TimeInterval]
    
    public var averageTime: TimeInterval {
        executionTimes.isEmpty ? 0 : executionTimes.reduce(0, +) / Double(executionTimes.count)
    }
    
    public var minTime: TimeInterval {
        executionTimes.min() ?? 0
    }
    
    public var maxTime: TimeInterval {
        executionTimes.max() ?? 0
    }
    
    public var medianTime: TimeInterval {
        let sorted = executionTimes.sorted()
        let count = sorted.count
        
        if count == 0 { return 0 }
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
    
    public var standardDeviation: TimeInterval {
        guard executionTimes.count > 1 else { return 0 }
        
        let avg = averageTime
        let variance = executionTimes.reduce(0) { sum, time in
            sum + pow(time - avg, 2)
        } / Double(executionTimes.count - 1)
        
        return sqrt(variance)
    }
    
    internal init(executionTimes: [TimeInterval]) {
        self.executionTimes = executionTimes
    }
}

// MARK: - Swift Testing Integration

@available(iOS 18.0, *)
public extension AsyncTestHelpers {
    
    /// Convenience method for Swift Testing #expect with async operations
    /// - Parameters:
    ///   - condition: Async condition to check
    ///   - timeout: Maximum time to wait
    /// - Throws: TimeoutError if condition not met
    static func expectAsync(
        _ condition: @escaping () async throws -> Bool,
        timeout: TimeInterval = defaultTimeout
    ) async throws {
        let result = try await withTimeout(timeout) {
            return try await condition()
        }
        
        if !result {
            throw AsyncTestError.conditionNotMet(timeout: timeout)
        }
    }
    
    /// Verify async operation throws specific error for Swift Testing
    /// - Parameters:
    ///   - expectedError: Expected error
    ///   - operation: Async operation
    static func requireAsyncThrows<E: Error & Equatable, T>(
        _ expectedError: E,
        operation: @escaping () async throws -> T
    ) async throws {
        do {
            _ = try await operation()
            throw AsyncTestError.expectedError(type: String(describing: type(of: expectedError)))
        } catch let error as E where error == expectedError {
            // Expected error - test passes
            return
        } catch {
            throw AsyncTestError.wrongErrorType(
                expected: String(describing: type(of: expectedError)),
                actual: String(describing: type(of: error))
            )
        }
    }
}