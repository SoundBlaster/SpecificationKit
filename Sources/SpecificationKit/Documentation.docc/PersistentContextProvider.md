# PersistentContextProvider

A context provider that persists data using Core Data with async/await support and automatic cleanup of expired values.

## Overview

`PersistentContextProvider` enables specifications to work with persistent context data that survives app restarts. It provides robust data persistence using Core Data with features including automatic expiration, encryption support, migration handling, and async/await compatibility.

This provider is essential for applications that need to maintain specification context across app launches while ensuring data integrity and performance through automatic cleanup and caching mechanisms.

## Basic Usage

### Simple Persistent Provider

Create a basic persistent context provider with default settings:

```swift
import SpecificationKit

let persistentProvider = PersistentContextProvider()

// Use with async specifications
let context = try await persistentProvider.currentContextAsync()

// Set persistent data
await persistentProvider.setValue("premium", for: "userTier")
await persistentProvider.setCounter(5, for: "loginCount")
await persistentProvider.setFlag(true, for: "featureEnabled")
```

### With Specifications

Integrate with specification property wrappers:

```swift
@AsyncSatisfies(using: MaxCountSpec(counterKey: "dailyUsage", maxCount: 100), 
                provider: persistentProvider)
var withinDailyLimit: Bool

// Async evaluation
if try await withinDailyLimit.evaluateAsync() {
    processRequest()
}
```

### With Expiration

Set data with automatic expiration:

```swift
let oneDayFromNow = Date().addingTimeInterval(24 * 3600)

await persistentProvider.setValue("trial_feature", for: "specialAccess", 
                                 expirationDate: oneDayFromNow)
await persistentProvider.setCounter(0, for: "dailyAttempts", 
                                   expirationDate: Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)))
```

## Configuration Options

### Default Configuration

Use recommended settings for most applications:

```swift
let provider = PersistentContextProvider() // Uses Configuration.default

// Equivalent to:
let config = PersistentContextProvider.Configuration.default
let provider = PersistentContextProvider(configuration: config)
```

### Custom Configuration

Configure all aspects of the persistent provider:

```swift
let customConfig = PersistentContextProvider.Configuration(
    modelName: "MyAppContext",
    storeType: .sqliteStoreType,
    migrationPolicy: .automatic,
    encryptionEnabled: true
)

let provider = PersistentContextProvider(configuration: customConfig)
```

### In-Memory Configuration

Create an in-memory provider for testing:

```swift
let testConfig = PersistentContextProvider.Configuration(
    modelName: "TestContext",
    storeType: .inMemoryStoreType,
    migrationPolicy: .none,
    encryptionEnabled: false
)

let testProvider = PersistentContextProvider(configuration: testConfig)
```

## Store Types

### SQLite Store (Default)

Provides persistent storage to disk:

```swift
let sqliteConfig = PersistentContextProvider.Configuration(
    modelName: "AppContext",
    storeType: .sqliteStoreType // Default
)
```

### In-Memory Store

For testing or temporary data:

```swift
let memoryConfig = PersistentContextProvider.Configuration(
    modelName: "TempContext",
    storeType: .inMemoryStoreType
)
```

### Binary Store

For specialized use cases:

```swift
let binaryConfig = PersistentContextProvider.Configuration(
    modelName: "BinaryContext",
    storeType: .binaryStoreType
)
```

## Migration Policies

### Automatic Migration (Default)

Handles schema changes automatically:

```swift
let autoConfig = PersistentContextProvider.Configuration(
    modelName: "AppContext",
    migrationPolicy: .automatic // Default
)
```

### Custom Migration

Implement custom migration logic:

```swift
class CustomMigrator: PersistentContextProvider.MigrationManager {
    func performMigration(
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel,
        at storeURL: URL
    ) throws {
        // Custom migration implementation
        print("Performing custom migration from \(sourceModel) to \(destinationModel)")
    }
}

let customConfig = PersistentContextProvider.Configuration(
    modelName: "AppContext",
    migrationPolicy: .manual(CustomMigrator())
)
```

### No Migration

Disable migration (may cause crashes on schema changes):

```swift
let noMigrationConfig = PersistentContextProvider.Configuration(
    modelName: "AppContext",
    migrationPolicy: .none
)
```

## Data Management

### Setting Values

Store different types of data with optional expiration:

```swift
// User data
await persistentProvider.setValue("John Doe", for: "userName")
await persistentProvider.setValue(["theme": "dark", "language": "en"], for: "preferences")

// Counters
await persistentProvider.setCounter(10, for: "loginCount")
await persistentProvider.incrementCounter(for: "sessionCount", by: 1)

// Flags
await persistentProvider.setFlag(true, for: "hasSeenOnboarding")
await persistentProvider.setFlag(false, for: "betaFeaturesEnabled")

// Events
await persistentProvider.setEvent(Date(), for: "lastLogin")
await persistentProvider.setEvent(Date().addingTimeInterval(-3600), for: "lastPurchase")

// User segments
await persistentProvider.addSegment("premium")
await persistentProvider.addSegment("early_adopter")
```

### Data Cleanup

Remove expired data and manage storage:

```swift
// Remove expired data
await persistentProvider.removeExpiredData()

// Clear all data
await persistentProvider.clearAllData()

// Remove specific segments
await persistentProvider.removeSegment("trial_user")
```

## Integration Examples

### User Onboarding

Track onboarding progress persistently:

```swift
import SwiftUI

class OnboardingManager: ObservableObject {
    private let persistentProvider = PersistentContextProvider()
    
    @Published var currentStep: Int = 0
    @Published var isCompleted: Bool = false
    
    init() {
        Task { await loadOnboardingState() }
    }
    
    private func loadOnboardingState() async {
        do {
            let context = try await persistentProvider.currentContextAsync()
            
            DispatchQueue.main.async {
                self.currentStep = context.counter(for: "onboardingStep")
                self.isCompleted = context.flag(for: "onboardingCompleted")
            }
        } catch {
            print("Failed to load onboarding state: \(error)")
        }
    }
    
    func completeStep(_ step: Int) async {
        await persistentProvider.setCounter(step + 1, for: "onboardingStep")
        
        if step >= 4 { // Assuming 5 total steps
            await persistentProvider.setFlag(true, for: "onboardingCompleted")
            await persistentProvider.setEvent(Date(), for: "onboardingCompletedDate")
            
            DispatchQueue.main.async {
                self.isCompleted = true
            }
        }
        
        DispatchQueue.main.async {
            self.currentStep = step + 1
        }
    }
    
    func resetOnboarding() async {
        await persistentProvider.setCounter(0, for: "onboardingStep")
        await persistentProvider.setFlag(false, for: "onboardingCompleted")
        
        DispatchQueue.main.async {
            self.currentStep = 0
            self.isCompleted = false
        }
    }
}

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    
    var body: some View {
        VStack {
            if onboardingManager.isCompleted {
                Text("Welcome back!")
                Button("Restart Onboarding") {
                    Task { await onboardingManager.resetOnboarding() }
                }
            } else {
                Text("Step \(onboardingManager.currentStep + 1) of 5")
                Button("Complete Step") {
                    Task { await onboardingManager.completeStep(onboardingManager.currentStep) }
                }
            }
        }
    }
}
```

### Feature Usage Tracking

Track feature usage with automatic expiration:

```swift
class FeatureUsageTracker {
    private let persistentProvider = PersistentContextProvider()
    
    func trackFeatureUsage(_ feature: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = today.addingTimeInterval(24 * 3600)
        
        // Track daily usage with automatic expiration
        await persistentProvider.incrementCounter(for: "daily_\(feature)", by: 1)
        await persistentProvider.setCounter(
            (try? await getCurrentDailyUsage(feature)) ?? 0 + 1,
            for: "daily_\(feature)",
            expirationDate: tomorrow
        )
        
        // Track overall usage
        await persistentProvider.incrementCounter(for: "total_\(feature)", by: 1)
        
        // Mark feature as used
        await persistentProvider.setEvent(Date(), for: "last_used_\(feature)")
    }
    
    private func getCurrentDailyUsage(_ feature: String) async throws -> Int {
        let context = try await persistentProvider.currentContextAsync()
        return context.counter(for: "daily_\(feature)")
    }
    
    func getDailyUsage(_ feature: String) async -> Int {
        do {
            return try await getCurrentDailyUsage(feature)
        } catch {
            return 0
        }
    }
    
    func getTotalUsage(_ feature: String) async -> Int {
        do {
            let context = try await persistentProvider.currentContextAsync()
            return context.counter(for: "total_\(feature)")
        } catch {
            return 0
        }
    }
    
    func getLastUsedDate(_ feature: String) async -> Date? {
        do {
            let context = try await persistentProvider.currentContextAsync()
            return context.event(for: "last_used_\(feature)")
        } catch {
            return nil
        }
    }
}

// Usage example
let tracker = FeatureUsageTracker()

// Track feature usage
await tracker.trackFeatureUsage("premium_export")
await tracker.trackFeatureUsage("advanced_search")

// Check usage
let exportUsage = await tracker.getDailyUsage("premium_export")
let lastSearch = await tracker.getLastUsedDate("advanced_search")
```

### Subscription Management

Manage subscription state with persistence:

```swift
class SubscriptionManager: ObservableObject {
    private let persistentProvider = PersistentContextProvider()
    
    @Published var subscriptionTier: String = "free"
    @Published var subscriptionExpiry: Date?
    @Published var trialDaysRemaining: Int = 0
    
    init() {
        Task { await loadSubscriptionState() }
    }
    
    private func loadSubscriptionState() async {
        do {
            let context = try await persistentProvider.currentContextAsync()
            
            DispatchQueue.main.async {
                self.subscriptionTier = context.userData["subscriptionTier"] as? String ?? "free"
                self.subscriptionExpiry = context.event(for: "subscriptionExpiry")
                self.trialDaysRemaining = context.counter(for: "trialDaysRemaining")
            }
        } catch {
            print("Failed to load subscription state: \(error)")
        }
    }
    
    func startTrial(days: Int) async {
        let expiryDate = Date().addingTimeInterval(TimeInterval(days * 24 * 3600))
        
        await persistentProvider.setValue("trial", for: "subscriptionTier")
        await persistentProvider.setEvent(expiryDate, for: "subscriptionExpiry")
        await persistentProvider.setCounter(days, for: "trialDaysRemaining", expirationDate: expiryDate)
        await persistentProvider.setEvent(Date(), for: "trialStarted")
        await persistentProvider.addSegment("trial_user")
        
        DispatchQueue.main.async {
            self.subscriptionTier = "trial"
            self.subscriptionExpiry = expiryDate
            self.trialDaysRemaining = days
        }
    }
    
    func upgradeToPremium() async {
        await persistentProvider.setValue("premium", for: "subscriptionTier")
        await persistentProvider.setEvent(Date(), for: "premiumUpgradeDate")
        await persistentProvider.removeSegment("trial_user")
        await persistentProvider.addSegment("premium_user")
        
        // Remove trial expiration
        await persistentProvider.setCounter(0, for: "trialDaysRemaining")
        
        DispatchQueue.main.async {
            self.subscriptionTier = "premium"
            self.subscriptionExpiry = nil
            self.trialDaysRemaining = 0
        }
    }
    
    func expireSubscription() async {
        await persistentProvider.setValue("free", for: "subscriptionTier")
        await persistentProvider.setEvent(Date(), for: "subscriptionExpired")
        await persistentProvider.removeSegment("premium_user")
        await persistentProvider.removeSegment("trial_user")
        
        DispatchQueue.main.async {
            self.subscriptionTier = "free"
            self.subscriptionExpiry = nil
            self.trialDaysRemaining = 0
        }
    }
}
```

## Reactive Updates

### Combine Integration

If Combine is available, the provider supports reactive updates:

```swift
#if canImport(Combine)
import Combine

class ReactiveContextService: ObservableObject {
    private let persistentProvider = PersistentContextProvider()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentContext: EvaluationContext?
    
    init() {
        // Subscribe to context changes
        persistentProvider.contextUpdates
            .sink { [weak self] in
                Task { await self?.refreshContext() }
            }
            .store(in: &cancellables)
        
        // Subscribe to context stream
        Task {
            for await _ in persistentProvider.contextStream {
                await refreshContext()
            }
        }
    }
    
    @MainActor
    private func refreshContext() async {
        do {
            currentContext = try await persistentProvider.currentContextAsync()
        } catch {
            print("Failed to refresh context: \(error)")
        }
    }
}
#endif
```

## Error Handling

### Persistence Errors

Handle different types of persistence errors:

```swift
func handlePersistenceOperations() async {
    do {
        await persistentProvider.setValue("test", for: "key")
        let context = try await persistentProvider.currentContextAsync()
        print("Context loaded successfully")
    } catch let error as PersistentContextProvider.PersistenceError {
        switch error {
        case .modelNotFound(let name):
            print("Core Data model '\(name)' not found")
        case .storeLoadFailed(let underlyingError):
            print("Failed to load persistent store: \(underlyingError)")
        case .saveContextFailed(let underlyingError):
            print("Failed to save context: \(underlyingError)")
        case .migrationFailed(let underlyingError):
            print("Migration failed: \(underlyingError)")
        case .serializationFailed(let message):
            print("Serialization failed: \(message)")
        case .deserializationFailed(let message):
            print("Deserialization failed: \(message)")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

### Graceful Degradation

Implement fallback strategies for persistence failures:

```swift
class ResilientContextService {
    private let persistentProvider = PersistentContextProvider()
    private let fallbackProvider = DefaultContextProvider.shared
    
    func getContext() async -> EvaluationContext {
        do {
            // Try persistent provider first
            return try await persistentProvider.currentContextAsync()
        } catch {
            print("Persistent provider failed, using fallback: \(error)")
            // Fall back to in-memory provider
            return fallbackProvider.currentContext()
        }
    }
    
    func setValue(_ value: Any, for key: String) async {
        // Try to persist, but don't fail if persistence is unavailable
        await persistentProvider.setValue(value, for: key)
        
        // Also update fallback provider
        fallbackProvider.setUserData(key, value: value)
    }
}
```

## Data Cleanup and Maintenance

### Automatic Cleanup

Set up periodic cleanup of expired data:

```swift
class DataMaintenanceService {
    private let persistentProvider = PersistentContextProvider()
    private var cleanupTimer: Timer?
    
    func startPeriodicCleanup(interval: TimeInterval = 3600) { // Default: 1 hour
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { await self.performCleanup() }
        }
    }
    
    func stopPeriodicCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    private func performCleanup() async {
        await persistentProvider.removeExpiredData()
        print("Periodic cleanup completed at \(Date())")
    }
    
    deinit {
        stopPeriodicCleanup()
    }
}

// Usage
let maintenanceService = DataMaintenanceService()
maintenanceService.startPeriodicCleanup()
```

### Manual Data Management

Provide manual control over data lifecycle:

```swift
class DataManager {
    private let persistentProvider = PersistentContextProvider()
    
    func exportData() async -> [String: Any] {
        do {
            let context = try await persistentProvider.currentContextAsync()
            return [
                "userData": context.userData,
                "counters": context.counters,
                "flags": context.flags,
                "events": context.events.mapValues { $0.timeIntervalSince1970 },
                "segments": Array(context.segments)
            ]
        } catch {
            print("Failed to export data: \(error)")
            return [:]
        }
    }
    
    func importData(_ data: [String: Any]) async {
        // Clear existing data
        await persistentProvider.clearAllData()
        
        // Import user data
        if let userData = data["userData"] as? [String: Any] {
            for (key, value) in userData {
                await persistentProvider.setValue(value, for: key)
            }
        }
        
        // Import counters
        if let counters = data["counters"] as? [String: Int] {
            for (key, value) in counters {
                await persistentProvider.setCounter(value, for: key)
            }
        }
        
        // Import flags
        if let flags = data["flags"] as? [String: Bool] {
            for (key, value) in flags {
                await persistentProvider.setFlag(value, for: key)
            }
        }
        
        // Import events
        if let events = data["events"] as? [String: Double] {
            for (key, timestamp) in events {
                await persistentProvider.setEvent(Date(timeIntervalSince1970: timestamp), for: key)
            }
        }
        
        // Import segments
        if let segments = data["segments"] as? [String] {
            for segment in segments {
                await persistentProvider.addSegment(segment)
            }
        }
    }
    
    func resetToDefaults() async {
        await persistentProvider.clearAllData()
        
        // Set default values
        await persistentProvider.setValue("standard", for: "userTier")
        await persistentProvider.setFlag(true, for: "hasSeenWelcome")
        await persistentProvider.setCounter(0, for: "appLaunches")
        await persistentProvider.setEvent(Date(), for: "firstLaunch")
    }
}
```

## Best Practices

### 1. Use Appropriate Expiration

Set reasonable expiration dates for time-sensitive data:

```swift
// Session data - expires end of day
let endOfDay = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
await persistentProvider.setCounter(0, for: "dailyUsage", expirationDate: endOfDay)

// Feature flags - expires in 1 week
let oneWeekFromNow = Date().addingTimeInterval(7 * 24 * 3600)
await persistentProvider.setFlag(true, for: "betaFeature", expirationDate: oneWeekFromNow)

// Trial access - expires at specific date
let trialEnd = DateComponents(year: 2024, month: 12, day: 31).date
await persistentProvider.setValue("trial", for: "accessLevel", expirationDate: trialEnd)
```

### 2. Handle Migration Gracefully

Plan for data model changes:

```swift
class AppContextProvider {
    private let persistentProvider: PersistentContextProvider
    
    init() {
        let config = PersistentContextProvider.Configuration(
            modelName: "AppContext_v2", // Versioned model name
            migrationPolicy: .automatic
        )
        
        self.persistentProvider = PersistentContextProvider(configuration: config)
    }
    
    // Helper methods that abstract persistence details
    func getUserPreferences() async -> UserPreferences {
        do {
            let context = try await persistentProvider.currentContextAsync()
            return UserPreferences(
                theme: context.userData["theme"] as? String ?? "light",
                language: context.userData["language"] as? String ?? "en",
                notifications: context.flag(for: "notificationsEnabled")
            )
        } catch {
            // Return defaults on error
            return UserPreferences()
        }
    }
}
```

### 3. Use Structured Keys

Organize keys with consistent naming patterns:

```swift
struct ContextKeys {
    // User data keys
    static let userTier = "user.tier"
    static let userPreferences = "user.preferences"
    static let userName = "user.name"
    
    // Feature usage counters
    static let dailyExports = "usage.daily.exports"
    static let monthlyUploads = "usage.monthly.uploads"
    static let totalSessions = "usage.total.sessions"
    
    // Feature flags
    static let betaFeatures = "flags.beta.enabled"
    static let newUI = "flags.ui.new_design"
    static let experimentalAPI = "flags.api.experimental"
    
    // Event timestamps
    static let lastLogin = "events.auth.last_login"
    static let lastBackup = "events.data.last_backup"
    static let subscriptionExpiry = "events.subscription.expiry"
}

// Usage
await persistentProvider.setValue("premium", for: ContextKeys.userTier)
await persistentProvider.setFlag(true, for: ContextKeys.betaFeatures)
```

### 4. Monitor Performance

Track persistence performance for optimization:

```swift
class PerformanceMonitoringProvider {
    private let persistentProvider = PersistentContextProvider()
    
    func timedOperation<T>(_ operation: () async throws -> T, name: String) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("[\(name)] completed in \(timeElapsed * 1000)ms")
        return result
    }
    
    func monitoredSetValue(_ value: Any, for key: String) async {
        await timedOperation({
            await persistentProvider.setValue(value, for: key)
        }, name: "setValue(\(key))")
    }
    
    func monitoredGetContext() async throws -> EvaluationContext {
        return try await timedOperation({
            try await persistentProvider.currentContextAsync()
        }, name: "currentContextAsync")
    }
}
```

## Platform Availability

`PersistentContextProvider` requires:
- macOS 13.0+
- iOS 16.0+
- watchOS 9.0+
- tvOS 16.0+

This is due to its use of async/await and modern Core Data APIs.

## Performance Characteristics

- **Initial Load Time**: O(n) where n is the number of stored values
- **Set Operation Time**: O(1) for individual values
- **Memory Usage**: O(1) base overhead plus cached context size
- **Disk Usage**: Varies based on stored data size and Core Data overhead
- **Thread Safety**: All operations are thread-safe and async/await compatible

## See Also

- ``ContextProviding`` - The base protocol for context providers
- ``DefaultContextProvider`` - In-memory context provider for comparison
- ``NetworkContextProvider`` - Network-based context provider
- ``EnvironmentContextProvider`` - SwiftUI environment integration
- ``EvaluationContext`` - The context data structure
- ``AsyncSpecification`` - For async specification evaluation