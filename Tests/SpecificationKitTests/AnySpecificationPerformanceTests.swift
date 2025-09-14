import XCTest

@testable import SpecificationKit

final class AnySpecificationPerformanceTests: XCTestCase {

    // MARK: - Test Specifications

    private struct FastSpec: Specification {
        typealias Context = String
        func isSatisfiedBy(_ context: String) -> Bool {
            return context.count > 5
        }
    }

    private struct SlowSpec: Specification {
        typealias Context = String
        func isSatisfiedBy(_ context: String) -> Bool {
            // Simulate some work
            let _ = (0..<100).map { $0 * $0 }
            return context.contains("test")
        }
    }

    // MARK: - Single Specification Performance

    func testSingleSpecificationPerformance() {
        let spec = FastSpec()
        let anySpec = AnySpecification(spec)
        let contexts = Array(repeating: "test string with more than 5 characters", count: 10000)

        measure {
            for context in contexts {
                _ = anySpec.isSatisfiedBy(context)
            }
        }
    }

    func testDirectSpecificationPerformance() {
        let spec = FastSpec()
        let contexts = Array(repeating: "test string with more than 5 characters", count: 10000)

        measure {
            for context in contexts {
                _ = spec.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Composition Performance

    func testCompositionPerformance() {
        let spec1 = AnySpecification(FastSpec())
        let spec2 = AnySpecification(SlowSpec())
        let compositeSpec = spec1.and(spec2)
        let contexts = Array(repeating: "test string", count: 1000)

        measure {
            for context in contexts {
                _ = compositeSpec.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Collection Operations Performance

    func testAllSatisfyPerformance() {
        let specs = Array(repeating: AnySpecification(FastSpec()), count: 100)
        let context = "test string with more than 5 characters"

        measure {
            for _ in 0..<1000 {
                _ = specs.allSatisfy { $0.isSatisfiedBy(context) }
            }
        }
    }

    func testAnySatisfyPerformance() {
        // Create array with mostly false specs and one true at the end
        var specs: [AnySpecification<String>] = Array(
            repeating: AnySpecification { _ in false }, count: 99)
        specs.append(AnySpecification(FastSpec()))
        let context = "test string with more than 5 characters"

        measure {
            for _ in 0..<1000 {
                _ = specs.contains { $0.isSatisfiedBy(context) }
            }
        }
    }

    // MARK: - Specialized Storage Performance

    func testAlwaysTruePerformance() {
        let alwaysTrue = AnySpecification<String>.always
        let contexts = Array(repeating: "any context", count: 50000)

        measure {
            for context in contexts {
                _ = alwaysTrue.isSatisfiedBy(context)
            }
        }
    }

    func testAlwaysFalsePerformance() {
        let alwaysFalse = AnySpecification<String>.never
        let contexts = Array(repeating: "any context", count: 50000)

        measure {
            for context in contexts {
                _ = alwaysFalse.isSatisfiedBy(context)
            }
        }
    }

    func testPredicateSpecPerformance() {
        let predicateSpec = AnySpecification<String> { $0.count > 5 }
        let contexts = Array(repeating: "test string", count: 20000)

        measure {
            for context in contexts {
                _ = predicateSpec.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Memory Allocation Performance

    func testMemoryAllocationPerformance() {
        let spec = FastSpec()

        measure {
            for _ in 0..<10000 {
                let anySpec = AnySpecification(spec)
                _ = anySpec.isSatisfiedBy("test")
            }
        }
    }

    // MARK: - Large Dataset Performance

    func testLargeDatasetPerformance() {
        let specs = [
            AnySpecification<String> { $0.count > 3 },
            AnySpecification<String> { $0.contains("test") },
            AnySpecification<String> { !$0.isEmpty },
            AnySpecification(FastSpec()),
        ]

        let contexts = (0..<5000).map { "test string \($0)" }

        measure {
            for context in contexts {
                for spec in specs {
                    _ = spec.isSatisfiedBy(context)
                }
            }
        }
    }

    // MARK: - Nested Composition Performance

    func testNestedCompositionPerformance() {
        let baseSpec = AnySpecification<String> { $0.count > 0 }
        let level1 = baseSpec.and(AnySpecification { $0.count > 1 })
        let level2 = level1.and(AnySpecification { $0.count > 2 })
        let level3 = level2.or(AnySpecification { $0.contains("fallback") })

        let contexts = Array(repeating: "test context", count: 5000)

        measure {
            for context in contexts {
                _ = level3.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Comparison Tests

    func testWrappedVsDirectComparison() {
        let directSpec = FastSpec()
        let _ = AnySpecification(directSpec)
        let context = "test string with sufficient length"

        // Baseline: Direct specification
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            for _ in 0..<100000 {
                _ = directSpec.isSatisfiedBy(context)
            }
        }
    }

    func testWrappedSpecificationOverhead() {
        let directSpec = FastSpec()
        let wrappedSpec = AnySpecification(directSpec)
        let context = "test string with sufficient length"

        // Test: Wrapped specification
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            for _ in 0..<100000 {
                _ = wrappedSpec.isSatisfiedBy(context)
            }
        }
    }
}
