# NetworkContextProvider

A context provider that fetches context data from network endpoints with caching, retry logic, and offline support.

## Overview

`NetworkContextProvider` enables specifications to work with remote context data by fetching evaluation contexts from network endpoints. It provides robust networking capabilities including automatic retries, exponential backoff, caching for offline scenarios, and periodic refresh mechanisms.

This provider is essential for applications that need to evaluate specifications against dynamic, server-side context data while maintaining resilience to network failures and performance optimization through caching.

## Basic Usage

### Simple Network Provider

Create a basic network context provider:

```swift
import SpecificationKit

let configuration = NetworkContextProvider.Configuration(
    endpoint: URL(string: "https://api.example.com/context")!,
    refreshInterval: 300, // 5 minutes
    cacheEnabled: true
)

let networkProvider = NetworkContextProvider(configuration: configuration)

// Use with async specifications
let context = try await networkProvider.currentContextAsync()
```

### With Specifications

Integrate with specification property wrappers:

```swift
@AsyncSatisfies(using: someSpec, provider: networkProvider)
var featureEnabled: Bool

// Async evaluation
if try await featureEnabled.evaluateAsync() {
    enablePremiumFeature()
}
```

### Fallback Configuration

Configure fallback values for offline scenarios:

```swift
let configuration = NetworkContextProvider.Configuration(
    endpoint: URL(string: "https://api.example.com/context")!,
    fallbackValues: [
        "featureEnabled": true,
        "userTier": "basic",
        "maxRequests": 100
    ]
)
```

## Configuration Options

### Basic Configuration

Essential settings for network context fetching:

```swift
let configuration = NetworkContextProvider.Configuration(
    endpoint: URL(string: "https://api.example.com/context")!,
    refreshInterval: 600,        // 10 minutes
    requestTimeout: 30,          // 30 seconds
    cacheEnabled: true
)
```

### Retry Policies

Configure retry behavior for failed requests:

```swift
// Exponential backoff (default)
let exponentialConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    retryPolicy: .exponentialBackoff(maxAttempts: 3)
)

// Fixed delay retries
let fixedDelayConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    retryPolicy: .fixedDelay(2.0, maxAttempts: 3)
)

// No retries
let noRetryConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    retryPolicy: .none
)

// Custom retry logic
let customRetryConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    retryPolicy: .custom { attempt, error in
        // Custom delay calculation
        return attempt < 5 ? Double(attempt) * 1.5 : nil
    }
)
```

### Complete Configuration

Full configuration with all options:

```swift
let completeConfig = NetworkContextProvider.Configuration(
    endpoint: URL(string: "https://api.example.com/context")!,
    refreshInterval: 300,
    requestTimeout: 30,
    retryPolicy: .exponentialBackoff(maxAttempts: 3),
    fallbackValues: [
        "defaultTier": "free",
        "maxConnections": 10,
        "maintenanceMode": false
    ],
    cacheEnabled: true
)
```

## Retry Policies

### Exponential Backoff

Progressively increase delay between retries:

```swift
let policy = NetworkContextProvider.RetryPolicy.exponentialBackoff(maxAttempts: 4)

// Retry delays: 1s, 2s, 4s, then give up
// Policy calculates: 2^(attempt-1) seconds
```

### Fixed Delay

Consistent delay between retries:

```swift
let policy = NetworkContextProvider.RetryPolicy.fixedDelay(1.5, maxAttempts: 3)

// Retry delays: 1.5s, 1.5s, 1.5s, then give up
```

### Custom Retry Logic

Implement sophisticated retry strategies:

```swift
let customPolicy = NetworkContextProvider.RetryPolicy.custom { attempt, error in
    // Different strategies based on error type
    if error is URLError {
        switch (error as! URLError).code {
        case .timedOut:
            return attempt < 5 ? Double(attempt) * 2.0 : nil
        case .networkConnectionLost:
            return attempt < 3 ? 1.0 : nil
        default:
            return nil // Don't retry other URL errors
        }
    }
    
    // HTTP errors
    if let httpError = error as? NetworkContextProvider.NetworkError,
       case .httpError(let code) = httpError {
        return code >= 500 && attempt < 3 ? 2.0 : nil
    }
    
    return nil
}
```

## Data Format

### Expected JSON Structure

The network endpoint should return JSON in this format:

```json
{
    "userData": {
        "userId": "user123",
        "tier": "premium",
        "preferences": {...}
    },
    "counters": {
        "loginCount": 42,
        "apiCalls": 150,
        "sessionsToday": 3
    },
    "events": {
        "lastLogin": 1704067200,
        "lastPurchase": "2024-01-01T12:00:00Z",
        "trialStarted": 1703980800
    },
    "flags": {
        "featureEnabled": true,
        "betaAccess": false,
        "maintenanceMode": false
    },
    "segments": ["premium", "beta", "early-adopter"],
    "launchDate": 1703894400
}
```

### Date Formats

Dates can be provided in multiple formats:

```json
{
    "events": {
        "timestamp": 1704067200,                    // Unix timestamp
        "isoDate": "2024-01-01T12:00:00Z",         // ISO 8601 string
        "customDate": "2024-01-01T12:00:00.000Z"   // ISO 8601 with milliseconds
    }
}
```

## Integration Examples

### Feature Flag System

Implement remote feature flags:

```swift
import SwiftUI

class FeatureFlagService: ObservableObject {
    private let networkProvider: NetworkContextProvider
    
    init(endpoint: URL) {
        let config = NetworkContextProvider.Configuration(
            endpoint: endpoint,
            refreshInterval: 300,
            fallbackValues: [
                "newUIEnabled": false,
                "experimentalFeatures": false
            ]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
    }
    
    @AsyncSatisfies(using: FeatureFlagSpec(flag: "newUIEnabled"))
    var newUIEnabled: Bool
    
    @AsyncSatisfies(using: FeatureFlagSpec(flag: "experimentalFeatures"))
    var experimentalFeaturesEnabled: Bool
    
    func refreshFeatureFlags() async {
        do {
            _ = try await networkProvider.currentContextAsync()
            // Flags will be updated automatically
        } catch {
            print("Failed to refresh feature flags: \(error)")
        }
    }
}

struct ContentView: View {
    @StateObject private var featureFlags = FeatureFlagService(
        endpoint: URL(string: "https://api.example.com/feature-flags")!
    )
    
    var body: some View {
        VStack {
            if featureFlags.newUIEnabled {
                NewUIComponent()
            } else {
                LegacyUIComponent()
            }
        }
        .task {
            await featureFlags.refreshFeatureFlags()
        }
    }
}
```

### User Segmentation

Implement dynamic user segmentation:

```swift
class UserSegmentationService {
    private let networkProvider: NetworkContextProvider
    
    private let premiumUserSpec = UserSegmentSpec(segment: "premium")
    private let betaUserSpec = UserSegmentSpec(segment: "beta")
    private let highValueSpec = MaxCountSpec(
        counterKey: "totalPurchases",
        maxCount: 10,
        comparison: .greaterThanOrEqual
    )
    
    init(endpoint: URL, userId: String) {
        let config = NetworkContextProvider.Configuration(
            endpoint: endpoint.appendingPathComponent("users/\(userId)/context"),
            refreshInterval: 600,
            fallbackValues: [
                "userTier": "free",
                "totalPurchases": 0
            ]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
    }
    
    func getUserSegment() async throws -> UserSegment {
        let context = try await networkProvider.currentContextAsync()
        
        if premiumUserSpec.isSatisfiedBy(context) {
            return .premium
        } else if betaUserSpec.isSatisfiedBy(context) {
            return .beta
        } else if highValueSpec.isSatisfiedBy(context) {
            return .highValue
        } else {
            return .standard
        }
    }
}

enum UserSegment {
    case premium, beta, highValue, standard
}
```

### Real-time Configuration

Implement dynamic application configuration:

```swift
class ConfigurationManager: ObservableObject {
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private let networkProvider: NetworkContextProvider
    
    init() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.example.com/config")!,
            refreshInterval: 120, // 2 minutes for frequent updates
            retryPolicy: .exponentialBackoff(maxAttempts: 5),
            fallbackValues: [
                "maxConnections": 100,
                "rateLimitPerMinute": 1000,
                "maintenanceMode": false
            ]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
        
        // Set up automatic refresh
        Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            Task { await self.refreshConfiguration() }
        }
    }
    
    @MainActor
    func refreshConfiguration() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await networkProvider.currentContextAsync()
            lastUpdateTime = Date()
        } catch {
            print("Configuration update failed: \(error)")
        }
    }
    
    func getMaxConnections() async -> Int {
        do {
            let context = try await networkProvider.currentContextAsync()
            return context.userData["maxConnections"] as? Int ?? 100
        } catch {
            return 100 // Fallback value
        }
    }
    
    func isMaintenanceMode() async -> Bool {
        do {
            let context = try await networkProvider.currentContextAsync()
            return context.flag(for: "maintenanceMode")
        } catch {
            return false
        }
    }
}
```

## Caching and Offline Support

### Cache Behavior

The provider includes automatic caching:

```swift
// Cache is enabled by default
let config = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    cacheEnabled: true // Default
)

// When network fails, cached context is returned
let context = try await networkProvider.currentContextAsync()
```

### Offline Scenarios

Handle offline situations gracefully:

```swift
class OfflineAwareService {
    private let networkProvider: NetworkContextProvider
    
    init() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.example.com/context")!,
            fallbackValues: [
                "offlineMode": true,
                "limitedFeatures": true,
                "cacheOnly": true
            ]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
    }
    
    func evaluateFeature() async -> Bool {
        do {
            let context = try await networkProvider.currentContextAsync()
            
            // Check if we're using cached/fallback data
            let isOffline = context.flag(for: "offlineMode")
            
            if isOffline {
                // Limited functionality in offline mode
                return context.flag(for: "limitedFeatures")
            } else {
                // Full functionality with fresh data
                return context.flag(for: "fullFeatureAccess")
            }
        } catch {
            // Complete fallback
            return false
        }
    }
}
```

## Error Handling

### Network Error Types

Handle different types of network errors:

```swift
func handleNetworkErrors() async {
    do {
        let context = try await networkProvider.currentContextAsync()
        // Use context
    } catch let error as NetworkContextProvider.NetworkError {
        switch error {
        case .invalidResponse:
            // Handle malformed response
            print("Server returned invalid response")
        case .httpError(let code):
            // Handle HTTP errors
            print("HTTP error: \(code)")
        case .maxRetriesExceeded:
            // All retry attempts failed
            print("Network request failed after all retries")
        case .networkUnavailable:
            // No network connection
            print("Network unavailable - using cached data")
        case .parseError(let message):
            // JSON parsing failed
            print("Failed to parse response: \(message)")
        case .configurationError(let message):
            // Configuration issue
            print("Configuration error: \(message)")
        }
    } catch {
        // Other errors
        print("Unexpected error: \(error)")
    }
}
```

### Graceful Degradation

Implement graceful degradation strategies:

```swift
class ResilientService {
    private let networkProvider: NetworkContextProvider
    private let fallbackProvider: DefaultContextProvider
    
    init() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.example.com/context")!,
            retryPolicy: .exponentialBackoff(maxAttempts: 2), // Quick failure
            fallbackValues: ["fallbackMode": true]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
        self.fallbackProvider = DefaultContextProvider.shared
    }
    
    func getContext() async -> EvaluationContext {
        do {
            // Try network first
            return try await networkProvider.currentContextAsync()
        } catch {
            // Fall back to local provider
            print("Using fallback provider due to network error: \(error)")
            return fallbackProvider.currentContext()
        }
    }
}
```

## Performance Considerations

### Request Optimization

Optimize network requests:

```swift
// Configure appropriate timeouts
let config = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    requestTimeout: 15,      // Shorter timeout for better UX
    refreshInterval: 600,    // Less frequent updates to reduce load
    retryPolicy: .exponentialBackoff(maxAttempts: 2) // Quick failure
)
```

### Background Refresh

Implement smart background refresh:

```swift
class SmartRefreshService {
    private let networkProvider: NetworkContextProvider
    private var isAppActive = true
    
    init() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.example.com/context")!,
            refreshInterval: 0 // Disable automatic refresh
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isAppActive = true
            Task { await self.refreshIfNeeded() }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isAppActive = false
        }
    }
    
    private func refreshIfNeeded() async {
        guard isAppActive else { return }
        
        do {
            _ = try await networkProvider.currentContextAsync()
        } catch {
            print("Background refresh failed: \(error)")
        }
    }
}
```

## Best Practices

### 1. Configure Appropriate Timeouts

Set reasonable timeouts based on your use case:

```swift
// For user-facing features - quick timeout
let userConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    requestTimeout: 10,
    retryPolicy: .exponentialBackoff(maxAttempts: 2)
)

// For background updates - longer timeout
let backgroundConfig = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    requestTimeout: 60,
    retryPolicy: .exponentialBackoff(maxAttempts: 5)
)
```

### 2. Provide Meaningful Fallback Values

Always provide sensible fallback values:

```swift
let config = NetworkContextProvider.Configuration(
    endpoint: endpoint,
    fallbackValues: [
        "featureEnabled": false,      // Safe default
        "maxConnections": 10,         // Conservative limit
        "debugMode": false,           // Secure default
        "userTier": "basic"          // Basic access level
    ]
)
```

### 3. Handle Network State Changes

Monitor network availability:

```swift
import Network

class NetworkAwareProvider: ObservableObject {
    private let networkProvider: NetworkContextProvider
    private let monitor = NWPathMonitor()
    
    @Published var isNetworkAvailable = true
    
    init() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: "https://api.example.com/context")!,
            fallbackValues: ["networkMode": "offline"]
        )
        
        self.networkProvider = NetworkContextProvider(configuration: config)
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
```

### 4. Use Structured Logging

Implement comprehensive logging:

```swift
extension NetworkContextProvider {
    private func logRequest(_ request: URLRequest) {
        print("""
            [NetworkContextProvider] Request:
            - URL: \(request.url?.absoluteString ?? "unknown")
            - Method: \(request.httpMethod ?? "GET")
            - Timeout: \(request.timeoutInterval)s
            """)
    }
    
    private func logResponse(_ data: Data, _ response: URLResponse) {
        print("""
            [NetworkContextProvider] Response:
            - Size: \(data.count) bytes
            - Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)
            """)
    }
    
    private func logError(_ error: Error, attempt: Int) {
        print("""
            [NetworkContextProvider] Error (attempt \(attempt)):
            - Type: \(type(of: error))
            - Description: \(error.localizedDescription)
            """)
    }
}
```

## Performance Characteristics

- **Network Request Time**: Depends on network latency and server response time
- **Retry Overhead**: Exponential backoff can add significant delay for failing requests
- **Cache Hit Time**: O(1) for cached context retrieval
- **Memory Usage**: O(1) for cached context, minimal overhead
- **Thread Safety**: All operations are thread-safe and async/await compatible

## See Also

- ``ContextProviding`` - The base protocol for context providers
- ``DefaultContextProvider`` - Local context provider for comparison
- ``EnvironmentContextProvider`` - SwiftUI environment integration
- ``EvaluationContext`` - The context data structure
- ``AsyncSpecification`` - For async specification evaluation