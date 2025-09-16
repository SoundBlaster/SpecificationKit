# SpecificationKit Development Commands

## Building and Testing
- `swift build` - Build the main library
- `swift test` - Run all tests
- `swift package resolve` - Resolve dependencies
- `swift build -v` - Build with verbose output
- `swift test -v` - Run tests with verbose output

## Demo Application
- `cd DemoApp && swift build` - Build the demo app
- `cd DemoApp && swift run SpecificationKitDemo` - Run the SwiftUI demo
- `cd DemoApp && swift run SpecificationKitDemo --cli` - Run the CLI demo

## Testing Specific Areas
- `swift test --filter <TestClassName>` - Run specific test classes
- `swift test --filter <TestMethod>` - Run specific test methods

## Documentation
- DocC documentation generation (via swift-docc-plugin)
- Documentation files in Sources/SpecificationKit/Documentation.docc/

## Git Commands (Darwin)
- `git status` - Check repository status
- `git add .` - Stage all changes
- `git commit -m "message"` - Commit changes
- `git push` - Push to remote

## System Utilities (Darwin)
- `ls` - List directory contents
- `find . -name "*.swift"` - Find Swift files
- `grep -r "pattern" .` - Search for patterns
- `cd directory` - Change directory