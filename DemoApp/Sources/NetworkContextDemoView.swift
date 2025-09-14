import Foundation
import SpecificationKit
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
struct NetworkContextDemoView: View {
    // Mock server state
    @StateObject private var mockServer = MockNetworkServer()

    // Network provider configuration
    @State private var endpoint = "https://api.example.com/context"
    @State private var refreshInterval: Double = 300
    @State private var requestTimeout: Double = 30
    @State private var retryPolicy: RetryPolicyOption = .exponentialBackoff
    @State private var maxAttempts = 3
    @State private var cacheEnabled = true

    // Provider state
    @State private var networkProvider: NetworkContextProvider?
    @State private var isLoading = false
    @State private var lastUpdateTime: Date?
    @State private var errorMessage: String?
    @State private var contextData: String = "No data loaded"
    @State private var cacheStatus: String = "No cache"

    // Demo specifications
    @State private var featureFlagResult: String = "—"
    @State private var userSegmentResult: String = "—"
    @State private var configResult: String = "—"

    enum RetryPolicyOption: String, CaseIterable, Identifiable {
        case none = "None"
        case exponentialBackoff = "Exponential Backoff"
        case fixedDelay = "Fixed Delay"

        var id: String { rawValue }

        func toNetworkPolicy(maxAttempts: Int) -> NetworkContextProvider.RetryPolicy {
            switch self {
            case .none:
                return .none
            case .exponentialBackoff:
                return .exponentialBackoff(maxAttempts: maxAttempts)
            case .fixedDelay:
                return .fixedDelay(1.5, maxAttempts: maxAttempts)
            }
        }
    }

    var body: some View {
        List {
            Section(
                header: Text("Mock Server Configuration"),
                footer: Text(
                    "Configure the mock server behavior to test different network scenarios")
            ) {
                Toggle("Server Available", isOn: $mockServer.isServerAvailable)

                if mockServer.isServerAvailable {
                    Stepper(
                        "Response Delay: \(String(format: "%.1f", mockServer.responseDelay))s",
                        value: $mockServer.responseDelay, in: 0...5, step: 0.5)

                    Picker("Response Type", selection: $mockServer.responseType) {
                        Text("Success").tag(MockNetworkServer.ResponseType.success)
                        Text("HTTP 500 Error").tag(MockNetworkServer.ResponseType.httpError)
                        Text("Invalid JSON").tag(MockNetworkServer.ResponseType.invalidJSON)
                        Text("Timeout").tag(MockNetworkServer.ResponseType.timeout)
                    }
                    .pickerStyle(.segmented)
                }

                Button("Reset Server") {
                    mockServer.reset()
                }
                .foregroundStyle(.blue)
            }

            Section(header: Text("Network Provider Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Endpoint:")
                        TextField("URL", text: $endpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                    Stepper(
                        "Refresh Interval: \(Int(refreshInterval))s",
                        value: $refreshInterval, in: 60...1800, step: 60)

                    Stepper(
                        "Request Timeout: \(Int(requestTimeout))s",
                        value: $requestTimeout, in: 5...120, step: 5)

                    Picker("Retry Policy", selection: $retryPolicy) {
                        ForEach(RetryPolicyOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if retryPolicy != .none {
                        Stepper(
                            "Max Attempts: \(maxAttempts)",
                            value: $maxAttempts, in: 1...10)
                    }

                    Toggle("Cache Enabled", isOn: $cacheEnabled)
                }
            }

            Section(header: Text("Provider Actions")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Create Provider") {
                            createNetworkProvider()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Refresh Context") {
                            Task { await refreshContext() }
                        }
                        .disabled(networkProvider == nil || isLoading)

                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    if let lastUpdate = lastUpdateTime {
                        Text("Last Update: \(lastUpdate, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }

            Section(header: Text("Context Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(contextData)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    Text("Cache Status: \(cacheStatus)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Specification Examples")) {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Test Feature Flag") {
                        Task { await testFeatureFlag() }
                    }
                    Text("Result: \(featureFlagResult)")
                        .font(.caption)

                    Button("Test User Segment") {
                        Task { await testUserSegment() }
                    }
                    Text("Result: \(userSegmentResult)")
                        .font(.caption)

                    Button("Test Configuration") {
                        Task { await testConfiguration() }
                    }
                    Text("Result: \(configResult)")
                        .font(.caption)
                }
            }

            Section(header: Text("Network Monitoring")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request History:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(mockServer.requestHistory.suffix(5), id: \.timestamp) { request in
                        HStack {
                            Image(
                                systemName: request.success
                                    ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundColor(request.success ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(request.timestamp, formatter: timeFormatter)
                                    .font(.caption)
                                Text(request.details)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }

                    if mockServer.requestHistory.isEmpty {
                        Text("No requests yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Network Context")
        .onAppear {
            mockServer.setup()
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }

    private func createNetworkProvider() {
        let config = NetworkContextProvider.Configuration(
            endpoint: URL(string: endpoint) ?? URL(string: "https://api.example.com/context")!,
            refreshInterval: refreshInterval,
            requestTimeout: requestTimeout,
            retryPolicy: retryPolicy.toNetworkPolicy(maxAttempts: maxAttempts),
            fallbackValues: [
                "featureEnabled": false,
                "userTier": "basic",
                "maxConnections": 10,
                "offlineMode": true,
            ],
            cacheEnabled: cacheEnabled
        )

        // Use mock server's session for testing
        networkProvider = NetworkContextProvider(
            configuration: config,
            session: mockServer.urlSession
        )

        errorMessage = nil
        contextData = "Provider created - call Refresh to fetch data"
        cacheStatus = cacheEnabled ? "Cache enabled" : "Cache disabled"
    }

    @MainActor
    private func refreshContext() async {
        guard let provider = networkProvider else { return }

        isLoading = true
        errorMessage = nil

        do {
            let context = try await provider.currentContextAsync()
            lastUpdateTime = Date()

            // Format context data for display
            let userData = context.userData.isEmpty ? "None" : context.userData.description
            let flags = context.flags.isEmpty ? "None" : context.flags.description
            let counters = context.counters.isEmpty ? "None" : context.counters.description

            contextData = """
                UserData: \(userData)
                Flags: \(flags)
                Counters: \(counters)
                Segments: \(context.segments.isEmpty ? "None" : Array(context.segments).joined(separator: ", "))
                """

            cacheStatus = "Context loaded from network"

        } catch let error as NetworkContextProvider.NetworkError {
            handleNetworkError(error)
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            contextData = "Failed to load context"
            cacheStatus = "Error occurred"
        }

        isLoading = false
    }

    private func handleNetworkError(_ error: NetworkContextProvider.NetworkError) {
        switch error {
        case .invalidResponse:
            errorMessage = "Invalid server response"
        case .httpError(let code):
            errorMessage = "HTTP error \(code)"
        case .maxRetriesExceeded:
            errorMessage = "Max retries exceeded"
        case .networkUnavailable:
            errorMessage = "Network unavailable"
        case .parseError(let message):
            errorMessage = "Parse error: \(message)"
        case .configurationError(let message):
            errorMessage = "Configuration error: \(message)"
        }

        contextData = "Using fallback/cached context"
        cacheStatus = cacheEnabled ? "Using cached data" : "Using fallback values"
    }

    private func testFeatureFlag() async {
        guard let provider = networkProvider else {
            featureFlagResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()
            let spec = FeatureFlagSpec(flagKey: "featureEnabled", expected: true)
            let result = spec.isSatisfiedBy(context)
            featureFlagResult = result ? "Feature ENABLED" : "Feature DISABLED"
        } catch {
            featureFlagResult = "Error: \(error.localizedDescription)"
        }
    }

    private func testUserSegment() async {
        guard let provider = networkProvider else {
            userSegmentResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()

            let premiumSpec = UserSegmentSpec(.vip)  // Using .vip since there's no .premium enum case
            let betaSpec = UserSegmentSpec(.beta)

            if premiumSpec.isSatisfiedBy(context) {
                userSegmentResult = "Premium User"
            } else if betaSpec.isSatisfiedBy(context) {
                userSegmentResult = "Beta User"
            } else {
                userSegmentResult = "Standard User"
            }
        } catch {
            userSegmentResult = "Error: \(error.localizedDescription)"
        }
    }

    private func testConfiguration() async {
        guard let provider = networkProvider else {
            configResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()
            let maxConnections = context.userData["maxConnections"] as? Int ?? 10
            let maintenanceMode = context.flag(for: "maintenanceMode")

            configResult =
                "Max Connections: \(maxConnections), Maintenance: \(maintenanceMode ? "ON" : "OFF")"
        } catch {
            configResult = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Network Server

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class MockNetworkServer: NSObject, ObservableObject, URLSessionDataDelegate {
    enum ResponseType: String, CaseIterable {
        case success = "success"
        case httpError = "httpError"
        case invalidJSON = "invalidJSON"
        case timeout = "timeout"
    }

    struct RequestLog {
        let timestamp: Date
        let success: Bool
        let details: String
    }

    @Published var isServerAvailable = true
    @Published var responseDelay: Double = 0.5
    @Published var responseType: ResponseType = .success
    @Published var requestHistory: [RequestLog] = []

    private(set) var urlSession: URLSession!

    func setup() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        MockURLProtocol.mockServer = self
    }

    func reset() {
        isServerAvailable = true
        responseDelay = 0.5
        responseType = .success
        requestHistory.removeAll()
    }

    func handleRequest(for url: URL) -> (Data?, URLResponse?, Error?) {
        let log: RequestLog

        defer {
            DispatchQueue.main.async {
                self.requestHistory.append(log)
            }
        }

        // Simulate delay
        Thread.sleep(forTimeInterval: responseDelay)

        guard isServerAvailable else {
            log = RequestLog(
                timestamp: Date(),
                success: false,
                details: "Server unavailable"
            )
            return (nil, nil, URLError(.networkConnectionLost))
        }

        switch responseType {
        case .success:
            let jsonData = """
                {
                    "userData": {
                        "userId": "demo123",
                        "userTier": "premium",
                        "maxConnections": 50
                    },
                    "flags": {
                        "featureEnabled": true,
                        "betaAccess": true,
                        "maintenanceMode": false
                    },
                    "counters": {
                        "loginCount": 25,
                        "apiCalls": 150
                    },
                    "segments": ["vip", "beta"],
                    "launchDate": 1703894400
                }
                """.data(using: .utf8)!

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )

            log = RequestLog(
                timestamp: Date(),
                success: true,
                details: "200 OK - \(jsonData.count) bytes"
            )

            return (jsonData, response, nil)

        case .httpError:
            let response = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )

            log = RequestLog(
                timestamp: Date(),
                success: false,
                details: "500 Internal Server Error"
            )

            return (Data(), response, nil)

        case .invalidJSON:
            let invalidData = "{ invalid json }".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )

            log = RequestLog(
                timestamp: Date(),
                success: false,
                details: "200 OK - Invalid JSON"
            )

            return (invalidData, response, nil)

        case .timeout:
            log = RequestLog(
                timestamp: Date(),
                success: false,
                details: "Request timeout"
            )

            return (nil, nil, URLError(.timedOut))
        }
    }
}

// MARK: - Mock URL Protocol

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class MockURLProtocol: URLProtocol {
    static weak var mockServer: MockNetworkServer?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url,
            let mockServer = MockURLProtocol.mockServer
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let (data, response, error) = mockServer.handleRequest(for: url)

        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
        }
    }

    override func stopLoading() {
        // No-op
    }
}

#Preview {
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
        NavigationView {
            NetworkContextDemoView()
        }
    } else {
        Text("NetworkContextProvider requires iOS 15.0+")
    }
}
