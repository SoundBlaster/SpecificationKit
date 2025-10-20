//
//  NetworkContextProvider.swift
//  SpecificationKit
//
//  Network-based context provider with caching, retry logic, and offline support.
//

import Foundation

#if canImport(Combine)
    @preconcurrency import Combine
#endif

/// A context provider that fetches context data from a network endpoint with caching and retry support.
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public final class NetworkContextProvider: ContextProviding {
    public typealias Context = EvaluationContext

    /// Configuration for the network context provider
    public struct Configuration: Sendable {
        public let endpoint: URL
        public let refreshInterval: TimeInterval
        public let requestTimeout: TimeInterval
        public let retryPolicy: RetryPolicy
        public let fallbackValues: [String: Sendable]
        public let cacheEnabled: Bool

        public init(
            endpoint: URL,
            refreshInterval: TimeInterval = 300,
            requestTimeout: TimeInterval = 30,
            retryPolicy: RetryPolicy = .exponentialBackoff(maxAttempts: 3),
            fallbackValues: [String: Sendable] = [:],
            cacheEnabled: Bool = true
        ) {
            self.endpoint = endpoint
            self.refreshInterval = refreshInterval
            self.requestTimeout = requestTimeout
            self.retryPolicy = retryPolicy
            self.fallbackValues = fallbackValues
            self.cacheEnabled = cacheEnabled
        }

        public static let `default` = Configuration(
            endpoint: URL(string: "https://api.example.com/context")!
        )
    }

    /// Retry policy for failed network requests
    public enum RetryPolicy: Sendable {
        case none
        case fixedDelay(TimeInterval, maxAttempts: Int)
        case exponentialBackoff(maxAttempts: Int)
        case custom(@Sendable (_ attempt: Int, _ error: Error) -> TimeInterval?)

        func getDelay(for attempt: Int, error: Error) -> TimeInterval? {
            switch self {
            case .none:
                return nil
            case .fixedDelay(let delay, let maxAttempts):
                return attempt <= maxAttempts ? delay : nil
            case .exponentialBackoff(let maxAttempts):
                return attempt <= maxAttempts ? pow(2.0, Double(attempt - 1)) : nil
            case .custom(let delayCalculator):
                return delayCalculator(attempt, error)
            }
        }

        var maxAttempts: Int {
            switch self {
            case .none:
                return 1
            case .fixedDelay(_, let attempts):
                return attempts
            case .exponentialBackoff(let attempts):
                return attempts
            case .custom:
                return 5  // Default for custom
            }
        }
    }

    /// Network-related errors
    public enum NetworkError: Error, LocalizedError, Sendable {
        case invalidResponse
        case httpError(Int)
        case maxRetriesExceeded
        case networkUnavailable
        case parseError(String)
        case configurationError(String)

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid network response"
            case .httpError(let code):
                return "HTTP error \(code)"
            case .maxRetriesExceeded:
                return "Maximum retry attempts exceeded"
            case .networkUnavailable:
                return "Network is unavailable"
            case .parseError(let message):
                return "Parse error: \(message)"
            case .configurationError(let message):
                return "Configuration error: \(message)"
            }
        }
    }

    private let configuration: Configuration
    private let session: URLSession
    private let cache: NetworkCache

    #if canImport(Combine)
        private let contextUpdatesSubject = PassthroughSubject<Void, Never>()
    #endif

    private var refreshTimer: Timer?

    /// Creates a NetworkContextProvider with the given configuration
    /// - Parameters:
    ///   - configuration: The network configuration
    ///   - session: The URLSession to use (defaults to .shared)
    public init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.cache = NetworkCache()

        if configuration.refreshInterval > 0 {
            setupPeriodicRefresh()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    public func currentContext() -> EvaluationContext {
        // For synchronous access, return fallback context only
        // NetworkContextProvider is designed primarily for async usage
        return createFallbackContext()
    }

    /// Asynchronously fetches the current context from the network
    /// - Returns: An EvaluationContext with the latest data
    public func currentContextAsync() async throws -> EvaluationContext {
        do {
            let data = try await fetchContextData()
            let context = try parseContextData(data)

            if configuration.cacheEnabled {
                await cache.cacheContext(context, ttl: configuration.refreshInterval)
            }

            #if canImport(Combine)
                contextUpdatesSubject.send()
            #endif

            return context
        } catch {
            // Return cached context if network fails
            if let cachedContext = await cache.getCachedContext() {
                return cachedContext
            }

            // Otherwise return fallback context
            return createFallbackContext()
        }
    }

    // MARK: - Private Implementation

    private func fetchContextData() async throws -> Data {
        var lastError: Error?
        let maxAttempts = configuration.retryPolicy.maxAttempts

        for attempt in 1...maxAttempts {
            do {
                return try await performNetworkRequest()
            } catch {
                lastError = error

                if attempt < maxAttempts,
                    let delay = configuration.retryPolicy.getDelay(for: attempt, error: error)
                {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    break
                }
            }
        }

        throw lastError ?? NetworkError.maxRetriesExceeded
    }

    private func performNetworkRequest() async throws -> Data {
        var request = URLRequest(url: configuration.endpoint)
        request.timeoutInterval = configuration.requestTimeout
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SpecificationKit/3.0.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        return data
    }

    private func parseContextData(_ data: Data) throws -> EvaluationContext {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NetworkError.parseError("Invalid JSON structure")
            }

            return EvaluationContext(
                currentDate: Date(),
                launchDate: parseDate(from: json["launchDate"]) ?? Date(),
                userData: json["userData"] as? [String: Any] ?? [:],
                counters: parseCounters(from: json["counters"]),
                events: parseEvents(from: json["events"]),
                flags: json["flags"] as? [String: Bool] ?? [:],
                segments: parseSegments(from: json["segments"])
            )
        } catch {
            throw NetworkError.parseError(error.localizedDescription)
        }
    }

    private func parseDate(from value: Any?) -> Date? {
        if let timestamp = value as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        } else if let dateString = value as? String {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString)
        }
        return nil
    }

    private func parseCounters(from value: Any?) -> [String: Int] {
        guard let counters = value as? [String: Any] else { return [:] }
        var result: [String: Int] = [:]

        for (key, val) in counters {
            if let intVal = val as? Int {
                result[key] = intVal
            } else if let doubleVal = val as? Double {
                result[key] = Int(doubleVal)
            }
        }

        return result
    }

    private func parseEvents(from value: Any?) -> [String: Date] {
        guard let events = value as? [String: Any] else { return [:] }
        var result: [String: Date] = [:]

        for (key, val) in events {
            if let date = parseDate(from: val) {
                result[key] = date
            }
        }

        return result
    }

    private func parseSegments(from value: Any?) -> Set<String> {
        guard let segments = value as? [String] else { return [] }
        return Set(segments)
    }

    private func createFallbackContext() -> EvaluationContext {
        return EvaluationContext(
            currentDate: Date(),
            launchDate: Date(),
            userData: configuration.fallbackValues,
            counters: [:],
            events: [:],
            flags: [:],
            segments: []
        )
    }

    private func setupPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.refreshInterval, repeats: true
        ) { [weak self] _ in
            Task {
                try? await self?.refreshContext()
            }
        }
    }

    @discardableResult
    private func refreshContext() async throws -> EvaluationContext {
        return try await currentContextAsync()
    }
}

// MARK: - Context Updates Providing

#if canImport(Combine)
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    extension NetworkContextProvider: ContextUpdatesProviding {
        public var contextUpdates: AnyPublisher<Void, Never> {
            contextUpdatesSubject.eraseToAnyPublisher()
        }

        public var contextStream: AsyncStream<Void> {
            AsyncStream { continuation in
                let cancellable = contextUpdates.sink { _ in
                    continuation.yield()
                }

                continuation.onTermination = { _ in
                    cancellable.cancel()
                }
            }
        }
    }
#endif

// MARK: - Network Cache

private actor NetworkCache {
    private struct CachedContext {
        let context: EvaluationContext
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    private var cachedContext: CachedContext?

    func getCachedContext() -> EvaluationContext? {
        guard let cached = cachedContext, !cached.isExpired else {
            cachedContext = nil
            return nil
        }
        return cached.context
    }

    func cacheContext(_ context: EvaluationContext, ttl: TimeInterval) {
        cachedContext = CachedContext(
            context: context,
            timestamp: Date(),
            ttl: ttl
        )
    }

    func clearCache() {
        cachedContext = nil
    }
}
