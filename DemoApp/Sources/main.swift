//
//  main.swift
//  SpecificationKitDemo
//
//  Created by SpecificationKit on 2024.
//

import Foundation
import SpecificationKit
import SwiftUI

// Check if we should run CLI demo
if CommandLine.arguments.contains("--cli") {
    runCLIDemo()
} else {
    // Run SwiftUI app by default
    struct SpecificationKitDemoApp: App {
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
    }

    SpecificationKitDemoApp.main()
}

struct ContentView: View {
    @StateObject private var demoManager = DemoManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SpecificationKit Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                VStack(alignment: .leading, spacing: 10) {
                    Text("App State")
                        .font(.headline)

                    Text("Time since launch: \(demoManager.timeSinceLaunch, specifier: "%.1f")s")
                    Text("Banner shown count: \(demoManager.bannerCount)")
                    Text("Last banner shown: \(demoManager.lastBannerTime)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Specifications")
                        .font(.headline)

                    HStack {
                        Circle()
                            .fill(demoManager.timeSinceAppLaunch ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(
                            "Time since launch (>10s): \(demoManager.timeSinceAppLaunch ? "✓" : "✗")"
                        )
                    }

                    HStack {
                        Circle()
                            .fill(demoManager.bannerCountOk ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Banner count (<3): \(demoManager.bannerCountOk ? "✓" : "✗")")
                    }

                    HStack {
                        Circle()
                            .fill(demoManager.cooldownComplete ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Cooldown (30s): \(demoManager.cooldownComplete ? "✓" : "✗")")
                    }

                    HStack {
                        Circle()
                            .fill(demoManager.shouldShowBanner ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Should show banner: \(demoManager.shouldShowBanner ? "YES" : "NO")")
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

                Spacer()

                VStack(spacing: 15) {
                    Button("Show Banner") {
                        demoManager.showBanner()
                    }
                    .disabled(!demoManager.shouldShowBanner)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(demoManager.shouldShowBanner ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Reset Demo") {
                        demoManager.reset()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .alert("Banner Shown!", isPresented: $demoManager.showingAlert) {
            Button("OK") {}
        } message: {
            Text("The promotional banner was displayed successfully!")
        }
    }
}

class DemoManager: ObservableObject {
    @Published var timeSinceLaunch: TimeInterval = 0
    @Published var bannerCount: Int = 0
    @Published var lastBannerTime: String = "Never"
    @Published var showingAlert = false

    private let contextProvider = DefaultContextProvider.shared
    private var timer: Timer?

    // Specifications using @Satisfies property wrapper
    @Satisfies(using: TimeSinceEventSpec.sinceAppLaunch(seconds: 10))
    var timeSinceAppLaunch: Bool

    @Satisfies(using: MaxCountSpec(counterKey: "banner_count", limit: 3))
    var bannerCountOk: Bool

    @Satisfies(using: CooldownIntervalSpec(eventKey: "last_banner", seconds: 30))
    var cooldownComplete: Bool

    @Satisfies(
        using: CompositeSpec(
            minimumLaunchDelay: 10,
            maxShowCount: 3,
            cooldownDays: 30.0 / 86400.0,  // 30 seconds in days
            counterKey: "banner_count",
            eventKey: "last_banner"
        ))
    var shouldShowBanner: Bool

    init() {
        // Start timer to update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateState()
        }

        // Initialize context provider
        setupInitialState()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupInitialState() {
        contextProvider.setCounter("banner_count", to: 0)
        updateState()
    }

    private func updateState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let context = self.contextProvider.currentContext()
            self.timeSinceLaunch = context.timeSinceLaunch
            self.bannerCount = context.counter(for: "banner_count")

            if let lastBanner = context.event(for: "last_banner") {
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                self.lastBannerTime = formatter.string(from: lastBanner)
            } else {
                self.lastBannerTime = "Never"
            }
        }
    }

    func showBanner() {
        guard shouldShowBanner else { return }

        // Update context to reflect banner was shown
        contextProvider.incrementCounter("banner_count")
        contextProvider.recordEvent("last_banner")

        // Show alert
        showingAlert = true

        // Update UI
        updateState()
    }

    func reset() {
        contextProvider.setCounter("banner_count", to: 0)
        contextProvider.removeEvent("last_banner")
        updateState()
    }
}

#Preview {
    ContentView()
}
