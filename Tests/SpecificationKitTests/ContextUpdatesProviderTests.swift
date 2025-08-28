import XCTest
@testable import SpecificationKit

#if canImport(Combine)
import Combine

final class ContextUpdatesProviderTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_DefaultProvider_emits_onFlagSet() {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        let exp = expectation(description: "contextUpdates emits on flag set")
        var received = 0

        if let p = provider as? ContextUpdatesProviding {
            p.contextUpdates
                .sink { _ in
                    received += 1
                    if received == 1 { exp.fulfill() }
                }
                .store(in: &cancellables)
        } else {
            XCTFail("DefaultContextProvider should conform to ContextUpdatesProviding")
        }

        provider.setFlag("demo_flag", to: true)
        wait(for: [exp], timeout: 1.0)
    }

    func test_DefaultProvider_emits_onCounterAndEvent() {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        let exp = expectation(description: "contextUpdates emits twice for two mutations")
        exp.expectedFulfillmentCount = 2

        if let p = provider as? ContextUpdatesProviding {
            p.contextUpdates
                .sink { _ in exp.fulfill() }
                .store(in: &cancellables)
        }

        _ = provider.incrementCounter("obs_count")
        provider.recordEvent("obs_event")

        wait(for: [exp], timeout: 1.0)
    }

    func test_DefaultProvider_contextStream_yields_onUpdate() async {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        guard let p = provider as? ContextUpdatesProviding else {
            XCTFail("DefaultContextProvider should conform to ContextUpdatesProviding")
            return
        }

        let stream = p.contextStream
        var iterator = stream.makeAsyncIterator()

        // Trigger after starting iterator to avoid missed signal
        Task { provider.setUserData("key", to: 1) }

        // Expect first yield
        let yielded = await iterator.next() != nil
        XCTAssertTrue(yielded)
    }
}

final class EnvironmentContextProviderUpdatesTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    @MainActor
    func test_EnvironmentProvider_emits_onPublishedChange() {
        let env = EnvironmentContextProvider()

        let exp = expectation(description: "env contextUpdates emits on published change")

        env.contextUpdates
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // Mutate a published property
        env.flags["foo"] = true

        wait(for: [exp], timeout: 1.0)
    }
}

#endif
