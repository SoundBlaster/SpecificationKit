//
//  SpecificationTracerTests.swift
//  SpecificationKitTests
//
//  Tests for SpecificationTracer debugging utilities
//

import XCTest

@testable import SpecificationKit

final class SpecificationTracerTests: XCTestCase {

    var tracer: SpecificationTracer!

    override func setUp() {
        super.setUp()
        tracer = SpecificationTracer.shared

        // Ensure clean state
        _ = tracer.stopTracing()
    }

    override func tearDown() {
        _ = tracer.stopTracing()
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testTracerSingletonAccess() {
        // Test that shared instance is consistent
        let tracer1 = SpecificationTracer.shared
        let tracer2 = SpecificationTracer.shared

        XCTAssertTrue(tracer1 === tracer2, "Shared instance should be singleton")
    }

    func testSessionLifecycle() {
        // Initially not tracing
        XCTAssertFalse(tracer.isTracing)

        // Start tracing
        let sessionId = tracer.startTracing()
        XCTAssertTrue(tracer.isTracing)

        // Stop tracing
        let session = tracer.stopTracing()
        XCTAssertFalse(tracer.isTracing)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.id, sessionId)
        XCTAssertFalse(session?.isActive ?? true)
    }

    func testStopTracingWhenNotActive() {
        // Stopping when not tracing should return nil
        let session = tracer.stopTracing()
        XCTAssertNil(session)
    }

    func testMultipleStartsOverwriteSession() {
        // Start first session
        let sessionId1 = tracer.startTracing()

        // Start second session (should overwrite first)
        let sessionId2 = tracer.startTracing()
        XCTAssertNotEqual(sessionId1, sessionId2)

        // Stop should return second session
        let session = tracer.stopTracing()
        XCTAssertEqual(session?.id, sessionId2)
    }

    // MARK: - Basic Tracing Tests

    func testBasicSpecificationTracing() {
        let spec = PredicateSpec<Int> { $0 > 50 }

        tracer.startTracing()
        let result = tracer.trace(specification: spec, context: 75)
        let session = tracer.stopTracing()

        XCTAssertTrue(result)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.entries.count, 1)

        let entry = session?.entries.first
        XCTAssertEqual(entry?.specification, "PredicateSpec<Int>")
        XCTAssertEqual(entry?.context, "75")
        XCTAssertEqual(entry?.result, "true")
        XCTAssertEqual(entry?.depth, 0)
        XCTAssertNil(entry?.parentId)
        XCTAssertGreaterThanOrEqual(entry?.executionTime ?? 0, 0)
    }

    func testTracingWithoutActiveSession() {
        // Tracing without active session should work normally but not record
        let spec = PredicateSpec<Int> { $0 > 50 }
        let result = tracer.trace(specification: spec, context: 75)

        XCTAssertTrue(result)

        // No session should be available
        let session = tracer.stopTracing()
        XCTAssertNil(session)
    }

    func testMultipleSpecificationTracing() {
        let spec1 = PredicateSpec<Int> { $0 > 50 }
        let spec2 = PredicateSpec<String> { $0.count > 5 }

        tracer.startTracing()
        _ = tracer.trace(specification: spec1, context: 75)
        _ = tracer.trace(specification: spec2, context: "Hello World")
        let session = tracer.stopTracing()

        XCTAssertEqual(session?.entries.count, 2)

        let intEntry = session?.entries.first { $0.specification == "PredicateSpec<Int>" }
        let stringEntry = session?.entries.first { $0.specification == "PredicateSpec<String>" }

        XCTAssertNotNil(intEntry)
        XCTAssertNotNil(stringEntry)
        XCTAssertEqual(intEntry?.result, "true")
        XCTAssertEqual(stringEntry?.result, "true")
    }

    // MARK: - Metadata Tracing Tests

    func testTracingWithMetadata() {
        let spec = PredicateSpec<Int> { $0 > 50 }
        let metadata = ["test_case": "boundary_value", "input_range": "0-100"]

        tracer.startTracing()
        _ = tracer.traceWithMetadata(
            specification: spec,
            context: 75,
            metadata: metadata
        )
        let session = tracer.stopTracing()

        XCTAssertEqual(session?.entries.count, 1)

        let entry = session?.entries.first
        XCTAssertEqual(entry?.metadata["test_case"] as? String, "boundary_value")
        XCTAssertEqual(entry?.metadata["input_range"] as? String, "0-100")
    }

    // MARK: - Type-Erased Specification Tests

    func testAnySpecificationTracing() {
        let spec = AnySpecification(PredicateSpec<Int> { $0 > 50 })

        tracer.startTracing()
        let result = tracer.traceAny(specification: spec, context: 75)
        let session = tracer.stopTracing()

        XCTAssertTrue(result)
        XCTAssertEqual(session?.entries.count, 1)

        let entry = session?.entries.first
        XCTAssertEqual(entry?.specification, "AnySpecification<Int>")
        XCTAssertEqual(entry?.result, "true")
    }

    // MARK: - Composite Specification Tests

    func testCompositeSpecificationANDTracing() {
        let spec1 = PredicateSpec<Int> { $0 > 50 }
        let spec2 = PredicateSpec<Int> { $0 < 100 }

        tracer.startTracing()
        let result = tracer.traceComposite(
            "AND",
            left: spec1,
            right: spec2,
            context: 75
        )
        let session = tracer.stopTracing()

        XCTAssertTrue(result)
        XCTAssertEqual(session?.entries.count, 3)  // left, right, composite

        // Check for composite entry
        let compositeEntry = session?.entries.first { $0.specification == "ANDSpecification" }
        XCTAssertNotNil(compositeEntry)
        XCTAssertEqual(compositeEntry?.result, "true")
        XCTAssertEqual(compositeEntry?.metadata["operation"] as? String, "AND")
        XCTAssertEqual(compositeEntry?.metadata["short_circuited"] as? Bool, false)
    }

    func testCompositeSpecificationORTracing() {
        let spec1 = PredicateSpec<Int> { $0 > 100 }  // false for 75
        let spec2 = PredicateSpec<Int> { $0 < 100 }  // true for 75

        tracer.startTracing()
        let result = tracer.traceComposite(
            "OR",
            left: spec1,
            right: spec2,
            context: 75
        )
        let session = tracer.stopTracing()

        XCTAssertTrue(result)
        XCTAssertEqual(session?.entries.count, 3)  // left, right, composite

        let compositeEntry = session?.entries.first { $0.specification == "ORSpecification" }
        XCTAssertNotNil(compositeEntry)
        XCTAssertEqual(compositeEntry?.result, "true")
        XCTAssertEqual(compositeEntry?.metadata["operation"] as? String, "OR")
        XCTAssertEqual(compositeEntry?.metadata["short_circuited"] as? Bool, false)
    }

    func testCompositeSpecificationANDShortCircuit() {
        let spec1 = PredicateSpec<Int> { $0 > 100 }  // false for 75
        let spec2 = PredicateSpec<Int> { $0 < 100 }  // would be true but shouldn't evaluate

        tracer.startTracing()
        let result = tracer.traceComposite(
            "AND",
            left: spec1,
            right: spec2,
            context: 75
        )
        let session = tracer.stopTracing()

        XCTAssertFalse(result)
        XCTAssertEqual(session?.entries.count, 2)  // left, composite (right not evaluated)

        let compositeEntry = session?.entries.first { $0.specification == "ANDSpecification" }
        XCTAssertNotNil(compositeEntry)
        XCTAssertEqual(compositeEntry?.result, "false")
        XCTAssertEqual(compositeEntry?.metadata["short_circuited"] as? Bool, true)
    }

    func testCompositeSpecificationORShortCircuit() {
        let spec1 = PredicateSpec<Int> { $0 > 50 }  // true for 75
        let spec2 = PredicateSpec<Int> { $0 < 100 }  // would be true but shouldn't evaluate

        tracer.startTracing()
        let result = tracer.traceComposite(
            "OR",
            left: spec1,
            right: spec2,
            context: 75
        )
        let session = tracer.stopTracing()

        XCTAssertTrue(result)
        XCTAssertEqual(session?.entries.count, 2)  // left, composite (right not evaluated)

        let compositeEntry = session?.entries.first { $0.specification == "ORSpecification" }
        XCTAssertNotNil(compositeEntry)
        XCTAssertEqual(compositeEntry?.result, "true")
        XCTAssertEqual(compositeEntry?.metadata["short_circuited"] as? Bool, true)
    }

    // MARK: - Hierarchical Tracing Tests

    func testNestedSpecificationTracing() {
        let spec = PredicateSpec<Int> { $0 > 50 }
        let parentId = UUID()

        tracer.startTracing()
        _ = tracer.trace(
            specification: spec,
            context: 75,
            parentId: parentId,
            depth: 1
        )
        let session = tracer.stopTracing()

        XCTAssertEqual(session?.entries.count, 1)

        let entry = session?.entries.first
        XCTAssertEqual(entry?.depth, 1)
        XCTAssertEqual(entry?.parentId, parentId)
    }

    // MARK: - Trace Tree Tests

    func testTraceTreeBuilding() {
        // Create a simple hierarchy by using the composite tracing functionality
        tracer.startTracing()

        let parentSpec = PredicateSpec<Int> { $0 > 0 }
        let childSpec = PredicateSpec<Int> { $0 < 100 }

        // Use composite tracing to create parent-child relationships
        _ = tracer.traceComposite("AND", left: parentSpec, right: childSpec, context: 50)

        let session = tracer.stopTracing()
        XCTAssertEqual(session?.entries.count, 3)  // left, right, composite

        let traceTree = session?.traceTree ?? []
        XCTAssertEqual(traceTree.count, 1)  // One root node (the composite)

        let rootNode = traceTree.first
        XCTAssertEqual(rootNode?.children.count, 2)  // Two children (left and right)
        XCTAssertEqual(rootNode?.entry.depth, 0)
        XCTAssertTrue(rootNode?.children.allSatisfy { $0.entry.depth == 1 } ?? false)
    }

    func testTraceTreeWithMultipleRoots() {
        tracer.startTracing()

        let spec1 = PredicateSpec<Int> { $0 > 0 }
        let spec2 = PredicateSpec<String> { !$0.isEmpty }

        _ = tracer.trace(specification: spec1, context: 50, parentId: nil, depth: 0)
        _ = tracer.trace(specification: spec2, context: "test", parentId: nil, depth: 0)

        let session = tracer.stopTracing()
        let traceTree = session?.traceTree ?? []

        XCTAssertEqual(traceTree.count, 2)  // Two root nodes
        XCTAssertTrue(traceTree.allSatisfy { $0.entry.depth == 0 })
        XCTAssertTrue(traceTree.allSatisfy { $0.children.isEmpty })
    }

    // MARK: - Performance and Timing Tests

    func testExecutionTimingAccuracy() {
        let slowSpec = PredicateSpec<Int> { candidate in
            // Simulate slow operation
            Thread.sleep(forTimeInterval: 0.001)  // 1ms
            return candidate > 50
        }

        tracer.startTracing()
        _ = tracer.trace(specification: slowSpec, context: 75)
        let session = tracer.stopTracing()

        let entry = session?.entries.first
        XCTAssertNotNil(entry)
        XCTAssertGreaterThan(entry?.executionTime ?? 0, 0.0005)  // At least 0.5ms
        XCTAssertLessThan(entry?.executionTime ?? 1, 0.01)  // Less than 10ms
    }

    func testSessionTotalExecutionTime() {
        tracer.startTracing()

        // Add multiple traced executions with slightly more complex operations
        for i in 1...5 {
            // Use a more complex predicate that takes measurable time
            let spec = PredicateSpec<Int> { value in
                // Simple computation to ensure some execution time
                let result = (0..<10).reduce(0) { sum, _ in sum + value }
                return result > 0
            }
            _ = tracer.trace(specification: spec, context: i)
        }

        let session = tracer.stopTracing()

        // With high-precision timing, we should always get some measurable time
        // Even if very small, it should be greater than 0
        let totalTime = session?.totalExecutionTime ?? 0
        XCTAssertGreaterThan(
            totalTime, 0, "Total execution time should be measurable with high-precision timing")

        // Total should equal sum of individual execution times
        let manualSum = session?.entries.map(\.executionTime).reduce(0, +) ?? 0
        XCTAssertEqual(totalTime, manualSum, accuracy: 0.000001)

        // Verify all entries have some execution time recorded
        let entriesWithZeroTime = session?.entries.filter { $0.executionTime == 0 }.count ?? 0
        XCTAssertEqual(entriesWithZeroTime, 0, "All entries should have measurable execution time")
    }

    // MARK: - Tree Visualization Tests

    func testPrintTreeOutput() {
        // This test verifies that printTree doesn't crash
        // Visual output testing would require capturing stdout
        tracer.startTracing()
        _ = tracer.trace(specification: PredicateSpec<Int> { $0 > 0 }, context: 50)
        let session = tracer.stopTracing()

        let traceTree = session?.traceTree ?? []
        XCTAssertFalse(traceTree.isEmpty)

        // This should not crash
        for tree in traceTree {
            tree.printTree()
        }
    }

    func testDotGraphGeneration() {
        tracer.startTracing()
        _ = tracer.trace(specification: PredicateSpec<Int> { $0 > 0 }, context: 50)
        let session = tracer.stopTracing()

        let traceTree = session?.traceTree ?? []
        XCTAssertFalse(traceTree.isEmpty)

        let dotGraph = traceTree.first?.generateDotGraph()
        XCTAssertNotNil(dotGraph)
        XCTAssertTrue(dotGraph?.contains("digraph SpecificationTrace") ?? false)
        XCTAssertTrue(dotGraph?.contains("PredicateSpec") ?? false)
        XCTAssertTrue(dotGraph?.contains("true") ?? false)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentTracing() {
        let expectation = XCTestExpectation(description: "Concurrent tracing")
        let spec = PredicateSpec<Int> { $0 > 50 }

        tracer.startTracing()

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test-concurrent", attributes: .concurrent)

        // Launch multiple concurrent traces (reduced count for faster test)
        for i in 1...10 {
            group.enter()
            queue.async {
                _ = self.tracer.trace(specification: spec, context: i)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let session = self.tracer.stopTracing()
            XCTAssertEqual(session?.entries.count, 10)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Integration with Existing Specs Tests

    func testMaxCountSpecTracing() {
        let spec = MaxCountSpec(counterKey: "test_action", maximumCount: 3)

        tracer.startTracing()

        // First three should pass (0, 1, 2 < 3)
        for i in 0..<3 {
            let context = EvaluationContext(counters: ["test_action": i])
            let result = tracer.trace(specification: spec, context: context)
            XCTAssertTrue(result)
        }

        // Fourth should fail (3 >= 3)
        let failContext = EvaluationContext(counters: ["test_action": 3])
        let result = tracer.trace(specification: spec, context: failContext)
        XCTAssertFalse(result)

        let session = tracer.stopTracing()
        XCTAssertEqual(session?.entries.count, 4)

        let entries = session?.entries ?? []
        XCTAssertTrue(entries.prefix(3).allSatisfy { $0.result == "true" })
        XCTAssertEqual(entries.last?.result, "false")
    }

    func testCooldownIntervalSpecTracing() {
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 1.0)

        tracer.startTracing()

        // Should fail due to recent event
        let recentContext = EvaluationContext(events: ["test_event": Date()])
        let result1 = tracer.trace(specification: spec, context: recentContext)
        XCTAssertFalse(result1)

        // Should pass with old event (2 seconds ago)
        let oldContext = EvaluationContext(events: ["test_event": Date().addingTimeInterval(-2.0)])
        let result2 = tracer.trace(specification: spec, context: oldContext)
        XCTAssertTrue(result2)

        let session = tracer.stopTracing()
        XCTAssertEqual(session?.entries.count, 2)

        let entries = session?.entries ?? []
        XCTAssertEqual(entries.first?.result, "false")
        XCTAssertEqual(entries.last?.result, "true")
    }

    // MARK: - Edge Cases and Error Conditions

    func testEmptyTraceSession() {
        tracer.startTracing()
        let session = tracer.stopTracing()

        XCTAssertNotNil(session)
        XCTAssertTrue(session?.entries.isEmpty ?? false)
        XCTAssertEqual(session?.totalExecutionTime, 0)
        XCTAssertTrue(session?.traceTree.isEmpty ?? false)
    }

    func testTraceEntryIDUniqueness() {
        tracer.startTracing()

        let spec = PredicateSpec<Int> { $0 > 0 }
        for i in 1...10 {
            _ = tracer.trace(specification: spec, context: i)
        }

        let session = tracer.stopTracing()
        let entries = session?.entries ?? []
        let uniqueIds = Set(entries.map(\.id))

        XCTAssertEqual(entries.count, uniqueIds.count, "All trace entry IDs should be unique")
    }

    func testInvalidParentIdHandling() {
        let fakeParentId = UUID()

        tracer.startTracing()
        _ = tracer.trace(
            specification: PredicateSpec<Int> { $0 > 0 },
            context: 50,
            parentId: fakeParentId,
            depth: 1
        )
        let session = tracer.stopTracing()

        // Should still record the entry with the invalid parent ID
        XCTAssertEqual(session?.entries.count, 1)
        XCTAssertEqual(session?.entries.first?.parentId, fakeParentId)

        // Tree building should handle orphaned entries gracefully
        let traceTree = session?.traceTree ?? []
        XCTAssertTrue(traceTree.isEmpty)  // No root nodes since all entries have parents
    }
}

// MARK: - Debug Extensions Tests

#if DEBUG
    extension SpecificationTracerTests {

        func testJSONExport() throws {
            tracer.startTracing()
            _ = tracer.trace(specification: PredicateSpec<Int> { $0 > 0 }, context: 50)
            let session = tracer.stopTracing()

            XCTAssertNotNil(session)

            let jsonData = try tracer.exportSession(session!)
            XCTAssertGreaterThan(jsonData.count, 0)

            // Verify it's valid JSON
            let json = try JSONSerialization.jsonObject(with: jsonData)
            XCTAssertNotNil(json)
        }

        func testAnalysisReport() {
            tracer.startTracing()

            // Create some diverse trace data
            _ = tracer.trace(specification: PredicateSpec<Int> { $0 > 0 }, context: 50)
            _ = tracer.trace(specification: PredicateSpec<String> { !$0.isEmpty }, context: "test")
            _ = tracer.trace(specification: PredicateSpec<Int> { $0 > 0 }, context: 25)  // Same spec again

            let session = tracer.stopTracing()
            XCTAssertNotNil(session)

            let report = tracer.generateAnalysisReport(session!)

            XCTAssertTrue(report.contains("Specification Trace Analysis"))
            XCTAssertTrue(report.contains("Session Information"))
            XCTAssertTrue(report.contains("Specification Breakdown"))
            XCTAssertTrue(report.contains("PredicateSpec<Int>"))
            XCTAssertTrue(report.contains("PredicateSpec<String>"))
        }
    }
#endif
