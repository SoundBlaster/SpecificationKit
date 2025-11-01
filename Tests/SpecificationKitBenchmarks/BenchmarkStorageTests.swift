import XCTest

final class BenchmarkStorageTests: XCTestCase {
    func testDefaultInitializerUsesTemporaryDirectoryFallback() {
        let fakeTemporaryDirectory = URL(fileURLWithPath: "/tmp/speckit-tests", isDirectory: true)
        let fileManager = FakeFileManager(temporaryDirectory: fakeTemporaryDirectory)

        let storage = BenchmarkStorage(fileManager: fileManager)

        XCTAssertEqual(
            storage.storageDirectory,
            fakeTemporaryDirectory.appendingPathComponent("SpecificationKitBenchmarks", isDirectory: true),
            "Storage should use the file manager's temporary directory when documents are unavailable"
        )
    }
}

private final class FakeFileManager: FileManager {
    private let fakeTemporaryDirectory: URL

    init(temporaryDirectory: URL) {
        self.fakeTemporaryDirectory = temporaryDirectory
        super.init()
    }

    override var temporaryDirectory: URL {
        fakeTemporaryDirectory
    }

    override func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        return []
    }

    override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        // no-op for tests
    }
}
