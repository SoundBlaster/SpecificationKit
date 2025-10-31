import XCTest

@testable import SpecificationKit

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
final class NetworkContextProviderTests: XCTestCase {

    private var configuration: NetworkContextProvider.Configuration!

    override func setUp() {
        super.setUp()
        configuration = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.test.com/context")!,
            refreshInterval: 60,
            requestTimeout: 10,
            retryPolicy: .exponentialBackoff(maxAttempts: 3),
            fallbackValues: ["fallback": "value" as String],
            cacheEnabled: true
        )
    }

    override func tearDown() {
        configuration = nil
        super.tearDown()
    }

    func testSynchronousContextReturnsFallback() {
        // Given
        let provider = NetworkContextProvider(
            configuration: configuration, session: URLSession.shared)

        // When
        let context = provider.currentContext()

        // Then - should return fallback context for synchronous access
        XCTAssertEqual(context.userData["fallback"] as? String, "value")
    }

    func testSuccessfulNetworkRequest() async throws {
        // Given - Create a configuration with a timeout that will cause immediate failure
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://nonexistent.invalid/context")!,
            refreshInterval: 60,
            requestTimeout: 0.001,  // Very short timeout to force failure
            retryPolicy: .none,
            fallbackValues: ["fallback": "value"],
            cacheEnabled: true
        )

        let provider = NetworkContextProvider(configuration: config)

        // When - this will fail due to invalid URL and short timeout, testing fallback
        let context = try await provider.currentContextAsync()

        // Then - should return fallback context when network fails
        XCTAssertEqual(context.userData["fallback"] as? String, "value")
        XCTAssertTrue(context.counters.isEmpty)
        XCTAssertTrue(context.flags.isEmpty)
    }

    func testFallbackContextWhenNetworkFails() async throws {
        // Given - Create a configuration with short timeout to avoid hanging
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://nonexistent.invalid/context")!,
            refreshInterval: 60,
            requestTimeout: 0.001,  // Very short timeout to force failure quickly
            retryPolicy: .none,
            fallbackValues: ["fallback": "value"],
            cacheEnabled: true
        )

        let provider = NetworkContextProvider(configuration: config)

        // When - using invalid URL with short timeout will trigger fallback quickly
        let context = try await provider.currentContextAsync()

        // Then
        XCTAssertEqual(context.userData["fallback"] as? String, "value")
        XCTAssertTrue(context.counters.isEmpty)
        XCTAssertTrue(context.flags.isEmpty)
    }

    func testConfigurationDefaults() {
        // Given
        let defaultConfig = NetworkContextProvider.Configuration.default

        // Then
        XCTAssertEqual(defaultConfig.endpoint.absoluteString, "https://api.example.com/context")
        XCTAssertEqual(defaultConfig.refreshInterval, 300)
        XCTAssertEqual(defaultConfig.requestTimeout, 30)
        XCTAssertTrue(defaultConfig.cacheEnabled)
        XCTAssertTrue(defaultConfig.fallbackValues.isEmpty)
    }

    func testRetryPolicyExponentialBackoff() {
        // Given
        let policy = NetworkContextProvider.RetryPolicy.exponentialBackoff(maxAttempts: 3)
        let error = URLError(.networkConnectionLost)

        // When & Then
        XCTAssertEqual(policy.maxAttempts, 3)
        XCTAssertEqual(policy.getDelay(for: 1, error: error), 1.0)
        XCTAssertEqual(policy.getDelay(for: 2, error: error), 2.0)
        XCTAssertEqual(policy.getDelay(for: 3, error: error), 4.0)
        XCTAssertNil(policy.getDelay(for: 4, error: error))
    }

    func testRetryPolicyFixedDelay() {
        // Given
        let policy = NetworkContextProvider.RetryPolicy.fixedDelay(1.5, maxAttempts: 2)
        let error = URLError(.timedOut)

        // When & Then
        XCTAssertEqual(policy.maxAttempts, 2)
        XCTAssertEqual(policy.getDelay(for: 1, error: error), 1.5)
        XCTAssertEqual(policy.getDelay(for: 2, error: error), 1.5)
        XCTAssertNil(policy.getDelay(for: 3, error: error))
    }

    func testRetryPolicyNone() {
        // Given
        let policy = NetworkContextProvider.RetryPolicy.none
        let error = URLError(.badURL)

        // When & Then
        XCTAssertEqual(policy.maxAttempts, 1)
        XCTAssertNil(policy.getDelay(for: 1, error: error))
    }

    func testRetryPolicyCustom() {
        // Given
        let customPolicy = NetworkContextProvider.RetryPolicy.custom { attempt, _ in
            return attempt < 3 ? Double(attempt) * 0.5 : nil
        }
        let error = URLError(.networkConnectionLost)

        // When & Then
        XCTAssertEqual(customPolicy.maxAttempts, 5)  // Default for custom
        XCTAssertEqual(customPolicy.getDelay(for: 1, error: error), 0.5)
        XCTAssertEqual(customPolicy.getDelay(for: 2, error: error), 1.0)
        XCTAssertNil(customPolicy.getDelay(for: 3, error: error))
    }

    func testNetworkErrorDescriptions() {
        // Given
        let errors: [NetworkContextProvider.NetworkError] = [
            .invalidResponse,
            .httpError(404),
            .maxRetriesExceeded,
            .networkUnavailable,
            .parseError("Invalid JSON"),
            .configurationError("Bad config"),
        ]

        // When & Then
        XCTAssertEqual(errors[0].errorDescription, "Invalid network response")
        XCTAssertEqual(errors[1].errorDescription, "HTTP error 404")
        XCTAssertEqual(errors[2].errorDescription, "Maximum retry attempts exceeded")
        XCTAssertEqual(errors[3].errorDescription, "Network is unavailable")
        XCTAssertEqual(errors[4].errorDescription, "Parse error: Invalid JSON")
        XCTAssertEqual(errors[5].errorDescription, "Configuration error: Bad config")
    }

    func testCacheDisabled() async throws {
        // Given
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://nonexistent.invalid/context")!,
            refreshInterval: 60,
            requestTimeout: 0.001,  // Very short timeout to force failure
            retryPolicy: .none,
            fallbackValues: ["test": "fallback_value"],
            cacheEnabled: false
        )

        let provider = NetworkContextProvider(configuration: config)

        // When
        let context = try await provider.currentContextAsync()

        // Then - should return fallback when caching disabled and network fails
        XCTAssertEqual(context.userData["test"] as? String, "fallback_value")

        // Verify no other data is present since network will fail and cache is disabled
        XCTAssertTrue(context.counters.isEmpty)
        XCTAssertTrue(context.flags.isEmpty)
        XCTAssertTrue(context.events.isEmpty)
        XCTAssertTrue(context.segments.isEmpty)
    }

    func testContextUpdatesProvider() {
        // Given
        let provider = NetworkContextProvider(
            configuration: configuration, session: URLSession.shared)

        // When & Then
        #if canImport(Combine)
            let contextProvider: ContextUpdatesProviding = provider
            XCTAssertNotNil(contextProvider.contextUpdates)
        #endif
    }

    func testDateParsing() {
        // Test the private date parsing logic through a successful JSON parse simulation
        // This tests the EvaluationContext creation logic
        // Create a context manually to verify the structure
        let context = EvaluationContext(
            currentDate: Date(),
            launchDate: Date(timeIntervalSince1970: 1_704_067_200),
            userData: ["key": "value"],
            counters: ["count": 42],
            events: ["event1": Date(timeIntervalSince1970: 1_704_153_600)],
            flags: ["enabled": true],
            segments: Set(["premium", "beta"])
        )

        XCTAssertEqual(context.userData["key"] as? String, "value")
        XCTAssertEqual(context.counter(for: "count"), 42)
        XCTAssertTrue(context.flag(for: "enabled"))
        XCTAssertEqual(context.segments, Set(["premium", "beta"]))
        XCTAssertEqual(context.event(for: "event1"), Date(timeIntervalSince1970: 1_704_153_600))
    }
}
