To get the test coverage metric value from the Swift Package Manager CLI command `swift test`, you need to use the flag:

```bash
swift test --enable-code-coverage
```

This enables code coverage data collection during testing. The coverage data is output in JSON format in the build directory at:

```
.build/debug/codecov/<package-name>.json
```

To analyze the coverage metrics from this JSON file, you can use a tool like the open-source `swift-test-codecov` which ingests this JSON file and provides high-level analysis and summary metrics from the CLI.

Usage example after running tests with coverage enabled:

```bash
swift-test-codecov .build/debug/codecov/<package-name>.json
```

This tool can display summary coverage percentage metrics and statistics for lines, functions, etc., directly in the terminal.

So the workflow is:
1. Run `swift test --enable-code-coverage`
2. Locate the JSON coverage output file in `.build/debug/codecov/`
3. Use a coverage analysis tool like `swift-test-codecov` to extract the coverage metric values from the JSON and display them on CLI [1][5][4].

Sources
[1] mattpolzin/swift-test-codecov https://github.com/mattpolzin/swift-test-codecov
[2] Code Coverage for Swift Applications https://www.rkvalidate.com/code-coverage-for-swift/
[3] What is code coverage and how do YOU measure it? [closed] https://stackoverflow.com/questions/195008/what-is-code-coverage-and-how-do-you-measure-it
[4] How to enable Xcode Code Coverage? https://www.browserstack.com/guide/xcode-code-coverage
[5] Code coverage for Swift Package Manager based apps https://bitrise.io/blog/post/code-coverage-for-swift-package-manager-based-apps
[6] Determining how much code your tests cover https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover
[7] Code Coverage for iOS Development Using Swift, Xcode, and ... https://about.codecov.io/blog/code-coverage-for-ios-development-using-swift-xcode-and-github-actions/
[8] How is --enable-code-coverage intended to be used? https://forums.swift.org/t/how-is-enable-code-coverage-intended-to-be-used/26296
