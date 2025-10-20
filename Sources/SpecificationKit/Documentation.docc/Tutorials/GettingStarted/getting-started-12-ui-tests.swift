import XCTest
import SwiftUI
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Specification that uses context
struct EligibilitySpec: Specification {
    typealias T = EvaluationContext

    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        guard let user = context.userData(for: "currentUser", as: User.self) else {
            return false
        }
        return user.isPremium || user.age >= 18
    }
}

// Test SwiftUI views with MockContextProvider
final class ViewTests: XCTestCase {
    func testSpecificationWithMockContext() {
        // Setup mock context provider
        let provider = MockContextProvider()
        let spec = EligibilitySpec()

        // Test with eligible user
        let eligibleUser = User(name: "Alice", age: 25, isPremium: false)
        let eligibleContext = EvaluationContext(userData: ["currentUser": eligibleUser])
        provider.setContext(eligibleContext)

        XCTAssertTrue(spec.isSatisfiedBy(provider.context))

        // Test with ineligible user
        let ineligibleUser = User(name: "Bob", age: 16, isPremium: false)
        let ineligibleContext = EvaluationContext(userData: ["currentUser": ineligibleUser])
        provider.setContext(ineligibleContext)

        XCTAssertFalse(spec.isSatisfiedBy(provider.context))
    }

    func testContextUpdates() {
        // Context can be updated for reactive testing
        let provider = MockContextProvider()

        // Start with regular user
        var user = User(name: "Alice", age: 25, isPremium: false)
        provider.setContext(EvaluationContext(userData: ["currentUser": user]))

        // Verify initial state
        let spec = EligibilitySpec()
        XCTAssertTrue(spec.isSatisfiedBy(provider.context))

        // Update to teen (ineligible)
        user = User(name: "Alice", age: 16, isPremium: false)
        provider.setContext(EvaluationContext(userData: ["currentUser": user]))
        XCTAssertFalse(spec.isSatisfiedBy(provider.context))
    }
}
