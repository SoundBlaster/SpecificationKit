//
//  CLIDemo.swift
//  SpecificationKitDemo
//
//  Created by SpecificationKit on 2024.
//

import Foundation
import SpecificationKit

/// Command-line demo showcasing SpecificationKit functionality
class CLIDemo {
    private let contextProvider = DefaultContextProvider()

    func run() {
        print("🚀 SpecificationKit Demo")
        print("========================\n")

        // Initialize some demo data
        setupDemoData()

        // Demo 1: Basic Specifications
        print("📋 Demo 1: Basic Specifications")
        print("--------------------------------")
        demoBasicSpecifications()

        // Demo 2: Property Wrapper Usage
        print("\n🎯 Demo 2: Property Wrapper Usage")
        print("----------------------------------")
        demoPropertyWrappers()

        // Demo 3: Composite Specifications
        print("\n🧩 Demo 3: Composite Specifications")
        print("------------------------------------")
        demoCompositeSpecifications()

        // Demo 4: Real-world Banner Logic
        print("\n📱 Demo 4: Banner Display Logic")
        print("--------------------------------")
        demoBannerLogic()

        // Demo 5: Context Provider Management
        print("\n⚙️ Demo 5: Context Provider Management")
        print("---------------------------------------")
        demoContextProviders()

        // Demo 6: SpecificationTracer
        print("\n🔍 Demo 6: SpecificationTracer")
        print("-------------------------------")
        demoSpecificationTracer()

        print("\n✅ Demo completed successfully!")
    }

    private func setupDemoData() {
        // Set up initial state
        contextProvider.setCounter("app_opens", to: 25)
        contextProvider.setCounter("banner_shown", to: 1)
        contextProvider.setCounter("feature_usage", to: 8)

        contextProvider.recordEvent("app_launch", at: Date().addingTimeInterval(-300))  // 5 minutes ago
        contextProvider.recordEvent("last_banner", at: Date().addingTimeInterval(-3600))  // 1 hour ago
        contextProvider.recordEvent("user_signup", at: Date().addingTimeInterval(-86400))  // 1 day ago

        contextProvider.setFlag("premium_user", to: false)
        contextProvider.setFlag("notifications_enabled", to: true)
        contextProvider.setFlag("onboarding_completed", to: true)
    }

    private func demoBasicSpecifications() {
        let context = contextProvider.currentContext()

        // Time-based specification
        let timeSinceLaunch = TimeSinceEventSpec.sinceAppLaunch(minutes: 2)
        print("⏰ Time since launch (>2min): \(checkMark(timeSinceLaunch.isSatisfiedBy(context)))")

        // Counter-based specification
        let usageCount = MaxCountSpec(counterKey: "feature_usage", limit: 10)
        print("📊 Feature usage count (<10): \(checkMark(usageCount.isSatisfiedBy(context)))")

        // Cooldown specification
        let bannerCooldown = CooldownIntervalSpec(eventKey: "last_banner", minutes: 30)
        print("⏳ Banner cooldown (30min): \(checkMark(bannerCooldown.isSatisfiedBy(context)))")

        // Predicate specification
        let isPremium = PredicateSpec<EvaluationContext>.flag("premium_user", equals: true)
        print("💎 Is premium user: \(checkMark(isPremium.isSatisfiedBy(context)))")
    }

    private func demoPropertyWrappers() {
        let demo = PropertyWrapperDemo()

        print("⚡ Using @Satisfies property wrapper:")
        print("   • Can show after delay: \(checkMark(demo.canShowAfterDelay))")
        print("   • User is engaged: \(checkMark(demo.userIsEngaged))")
        print("   • Notifications allowed: \(checkMark(demo.notificationsAllowed))")
        print("   • Should show promo: \(checkMark(demo.shouldShowPromo))")
    }

    private func demoCompositeSpecifications() {
        let context = contextProvider.currentContext()

        // Create a composite specification manually
        let engagementSpec = PredicateSpec<EvaluationContext>.counter(
            "app_opens", .greaterThanOrEqual, 20
        )
        let recentUserSpec = TimeSinceEventSpec(eventKey: "user_signup", days: 30).not()
        let onboardingComplete = PredicateSpec<EvaluationContext>.flag(
            "onboarding_completed", equals: true
        )

        let compositeSpec = engagementSpec.and(recentUserSpec).and(onboardingComplete)

        print("🎯 Composite Specification (Engaged Recent User):")
        print(
            "   • High engagement (≥20 opens): \(checkMark(engagementSpec.isSatisfiedBy(context)))")
        print("   • Recent user (<30 days): \(checkMark(recentUserSpec.isSatisfiedBy(context)))")
        print("   • Onboarding complete: \(checkMark(onboardingComplete.isSatisfiedBy(context)))")
        print("   • 📋 Combined result: \(checkMark(compositeSpec.isSatisfiedBy(context)))")

        // Using built-in composite
        let promoBanner = CompositeSpec.promoBanner
        print("\n🎪 Built-in Promo Banner Spec: \(checkMark(promoBanner.isSatisfiedBy(context)))")
    }

    private func demoBannerLogic() {
        print("🎯 Simulating banner display logic over time...")

        // Reset banner state
        contextProvider.setCounter("banner_shown", to: 0)
        contextProvider.removeEvent("last_banner")

        let bannerSpec = CompositeSpec(
            minimumLaunchDelay: 5,  // 5 seconds
            maxShowCount: 3,
            cooldownDays: 30.0 / 86400.0,  // 30 seconds
            counterKey: "banner_shown",
            eventKey: "last_banner"
        )

        // Simulate 10 attempts over time
        for attempt in 1...10 {
            let context = contextProvider.currentContext()
            let canShow = bannerSpec.isSatisfiedBy(context)

            print(
                "   Attempt \(attempt): \(canShow ? "✅ SHOW" : "❌ SKIP") "
                    + "(count: \(context.counter(for: "banner_shown")), "
                    + "time: \(Int(context.timeSinceLaunch))s)")

            if canShow {
                // Simulate showing the banner
                contextProvider.incrementCounter("banner_shown")
                contextProvider.recordEvent("last_banner")
                print("      📱 Banner displayed!")
            }

            // Wait a bit between attempts (simulated)
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func demoContextProviders() {
        print("🔧 Context Provider Features:")

        // Demonstrate counter operations
        let initialCount = contextProvider.getCounter("demo_counter")
        print("   • Initial counter: \(initialCount)")

        contextProvider.setCounter("demo_counter", to: 5)
        print("   • Set to 5: \(contextProvider.getCounter("demo_counter"))")

        let incremented = contextProvider.incrementCounter("demo_counter", by: 3)
        print("   • Increment by 3: \(incremented)")

        let decremented = contextProvider.decrementCounter("demo_counter", by: 2)
        print("   • Decrement by 2: \(decremented)")

        // Demonstrate flag operations
        contextProvider.setFlag("demo_flag", to: true)
        print("   • Set flag to true: \(contextProvider.getFlag("demo_flag"))")

        let toggled = contextProvider.toggleFlag("demo_flag")
        print("   • Toggle flag: \(toggled)")

        // Demonstrate event operations
        contextProvider.recordEvent("demo_event")
        let eventExists = contextProvider.getEvent("demo_event") != nil
        print("   • Record event: \(checkMark(eventExists))")

        // Mock provider comparison
        print("\n🧪 Mock Provider for Testing:")
        let mockProvider = MockContextProvider()
            .withCounter("test_counter", value: 10)
            .withFlag("test_flag", value: true)
            .withEvent("test_event", date: Date())

        let mockContext = mockProvider.currentContext()
        print("   • Mock counter: \(mockContext.counter(for: "test_counter"))")
        print("   • Mock flag: \(mockContext.flag(for: "test_flag"))")
        print("   • Context requests: \(mockProvider.contextRequestCount)")
    }

    private func demoSpecificationTracer() {
        let tracer = SpecificationTracer.shared

        print("🔍 Demonstrating SpecificationTracer capabilities...")
        print("   This tool captures detailed execution data for debugging complex specifications.")

        // Start tracing session
        let sessionId = tracer.startTracing()
        print("   📝 Started tracing session: \(sessionId.uuidString.prefix(8))...")

        let context = contextProvider.currentContext()

        // Demo 1: Simple specification tracing
        print("\n   🎯 Simple Specification Trace:")
        print(
            "      Testing: Is app_opens counter ≤ 50? (Current: \(context.counter(for: "app_opens")))"
        )
        let maxCountSpec = MaxCountSpec(counterKey: "app_opens", limit: 50)
        let result1 = tracer.trace(specification: maxCountSpec, context: context)
        print("      • MaxCountSpec → \(result1 ? "✅ PASS" : "❌ FAIL")")

        // Demo 2: Complex composite specification tracing
        print("\n   🧩 Complex Composite Specification Trace:")
        print("      Testing: (Time since launch > 10s) AND (Notifications enabled)")
        let timeSpec = TimeSinceEventSpec.sinceAppLaunch(seconds: 10)
        let flagSpec = FeatureFlagSpec(flagKey: "notifications_enabled")

        let compositeSpec = timeSpec.and(flagSpec)
        let result2 = tracer.trace(specification: compositeSpec, context: context)
        print("      • CompositeSpec → \(result2 ? "✅ PASS" : "❌ FAIL")")

        // Demo 3: Performance analysis
        print("\n   ⚡ Performance Analysis:")

        // Run multiple evaluations for performance data
        for i in 1...5 {
            let perfSpec = PredicateSpec<EvaluationContext> { ctx in
                // Simulate some work
                Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.005))
                return ctx.counter(for: "app_opens") > i * 5
            }
            _ = tracer.trace(specification: perfSpec, context: context)
        }

        // Stop tracing and analyze results
        if let session = tracer.stopTracing() {
            print("      • Total evaluations: \(session.entries.count)")
            print(
                "      • Total execution time: \(String(format: "%.3f", session.totalExecutionTime * 1000))ms"
            )

            // Find slowest execution
            if let slowest = session.entries.max(by: { $0.executionTime < $1.executionTime }) {
                print(
                    "      • Slowest evaluation: \(slowest.specification) (\(String(format: "%.3f", slowest.executionTime * 1000))ms)"
                )
            }

            // Show execution tree
            print("\n   🌳 Execution Tree:")
            for tree in session.traceTree {
                printTraceTree(tree, indent: "      ")
            }

            // Performance statistics
            print("\n   📊 Performance Statistics:")
            let times = session.entries.map { $0.executionTime * 1000 }  // Convert to ms
            let avgTime = times.reduce(0, +) / Double(times.count)
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 0

            print("      • Average time: \(String(format: "%.3f", avgTime))ms")
            print("      • Min time: \(String(format: "%.3f", minTime))ms")
            print("      • Max time: \(String(format: "%.3f", maxTime))ms")

            // Show specifications by type
            print("\n   📋 Specifications by Type:")
            let groupedSpecs = Dictionary(grouping: session.entries) { $0.specification }
            for (specType, entries) in groupedSpecs.sorted(by: { $0.key < $1.key }) {
                let count = entries.count
                let avgTimeForType =
                    entries.map(\.executionTime).reduce(0, +) / Double(count) * 1000
                print(
                    "      • \(specType): \(count) calls, \(String(format: "%.3f", avgTimeForType))ms avg"
                )
            }
        }

        print("\n   ✅ SpecificationTracer demo completed!")
    }

    private func printTraceTree(_ node: SpecificationTracer.TraceNode, indent: String) {
        let duration = String(format: "%.3f", node.entry.executionTime * 1000)
        print("\(indent)├─ \(node.entry.specification) → \(node.entry.result) (\(duration)ms)")

        for (index, child) in node.children.enumerated() {
            let isLast = index == node.children.count - 1
            let childIndent = indent + (isLast ? "   " : "│  ")
            printTraceTree(child, indent: childIndent)
        }
    }

    private func checkMark(_ condition: Bool) -> String {
        return condition ? "✅" : "❌"
    }
}

// Demo class using property wrappers
private class PropertyWrapperDemo {

    @Satisfies(using: TimeSinceEventSpec.sinceAppLaunch(seconds: 60))
    var canShowAfterDelay: Bool

    @Satisfies(using: MaxCountSpec(counterKey: "app_opens", limit: 50))
    var userIsEngaged: Bool

    @Satisfies(using: PredicateSpec<EvaluationContext>.flag("notifications_enabled"))
    var notificationsAllowed: Bool

    @Satisfies(
        using: CompositeSpec(
            minimumLaunchDelay: 30,
            maxShowCount: 5,
            cooldownDays: 1,
            counterKey: "promo_shown",
            eventKey: "last_promo"
        )
    )
    var shouldShowPromo: Bool
}

// Entry point for CLI demo
func runCLIDemo() {
    let demo = CLIDemo()
    demo.run()
}
