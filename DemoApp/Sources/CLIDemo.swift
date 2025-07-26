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
