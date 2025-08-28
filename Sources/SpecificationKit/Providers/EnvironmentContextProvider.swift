//
//  EnvironmentContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A context provider that bridges platform/environment values and simple persisted settings
/// (e.g., UserDefaults/AppStorage) into `EvaluationContext`.
///
/// This type is UI-agnostic: integrate with SwiftUI by updating its published properties
/// from `@Environment` and `@AppStorage` in your views.
@MainActor
public final class EnvironmentContextProvider: ObservableObject, @preconcurrency ContextProviding {
    public typealias Context = EvaluationContext

    // MARK: - Environment Snapshot
    /// Calendar to be reflected into the generated context (defaults to `.current`).
    public var calendar: Calendar = .current
    /// Time zone to be reflected into the generated context (defaults to `.current`).
    public var timeZone: TimeZone = .current
    /// Locale to be reflected into the generated context (defaults to `.current`).
    public var locale: Locale = .current
    /// Interface style hint (e.g., "light"/"dark"). Populate from SwiftUI colorScheme.
    public var interfaceStyle: String = "light"

    // MARK: - App State
    public var launchDate: Date
    public var flags: [String: Bool]
    public var counters: [String: Int]
    public var events: [String: Date]
    public var userData: [String: Any]
    public var segments: Set<String>

    // MARK: - Initialization
    public init(
        launchDate: Date = Date(),
        flags: [String: Bool] = [:],
        counters: [String: Int] = [:],
        events: [String: Date] = [:],
        userData: [String: Any] = [:],
        segments: Set<String> = []
    ) {
        self.launchDate = launchDate
        self.flags = flags
        self.counters = counters
        self.events = events
        self.userData = userData
        self.segments = segments
    }

    // MARK: - ContextProviding
    public func currentContext() -> EvaluationContext {
        var data = userData
        // Inject environment-derived values for convenient access in specs.
        data["environment.calendar.identifier"] = calendar.identifier
        data["environment.timeZone.identifier"] = timeZone.identifier
        data["environment.locale.identifier"] = locale.identifier
        data["environment.interfaceStyle"] = interfaceStyle

        return EvaluationContext(
            currentDate: Date(),
            launchDate: launchDate,
            userData: data,
            counters: counters,
            events: events,
            flags: flags,
            segments: segments
        )
    }
}
