# Notable Test Suite

This directory contains unit tests for the Notable app.

## Adding Tests to Xcode

The test files have been created but need to be added to the Xcode project:

1. Open `Notable.xcodeproj` in Xcode
2. Right-click on the project navigator and select "Add Files to Notable..."
3. Select the `NotableTests` folder
4. In the "Add to targets" section, create a new test target:
   - Click "+" to add a new target
   - Select "iOS" → "Unit Testing Bundle"
   - Name it "NotableTests"
   - Set the "Target to be Tested" to "Notable"
5. Add the test files to the new target

Alternatively, you can create the test target first:
1. File → New → Target
2. Select "iOS" → "Unit Testing Bundle"
3. Name: "NotableTests"
4. Then drag the `.swift` files from `NotableTests/` into the test target in Xcode

## Running Tests

### From Xcode
- **Run all tests**: Cmd + U
- **Run specific test**: Click the diamond icon next to the test method
- **View test results**: Cmd + 9 (Test Navigator)

### From Command Line
```bash
# Run all tests
xcodebuild test -scheme Notable -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.0.1'

# Run specific test class
xcodebuild test -scheme Notable -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.0.1' -only-testing:NotableTests/OperationsTests

# Run specific test method
xcodebuild test -scheme Notable -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.0.1' -only-testing:NotableTests/OperationsTests/testCleanText_RemovesNewlines
```

## Test Coverage

Current test files:

### OperationsTests.swift
Tests core operations functions:
- **Text Cleaning**: Validates `cleanText()` properly removes markdown syntax, newlines, and extra spaces
- **URL Validation**: Tests `verifyUrl()` with valid/invalid URLs
- **Audio Duration**: Tests `getAudioDuration()` error handling

### DataMigrationTests.swift
Tests the data migration system:
- Migration history tracking
- Version state management
- Reset functionality

### ImageValidationTests.swift
Tests image compression and validation:
- Size validation (CloudKit 10MB limit)
- Compression quality
- Edge cases

## Adding New Tests

When adding new features, create corresponding test files:

1. Create a new test file in `NotableTests/`
2. Import XCTest and `@testable import Notable`
3. Create test class inheriting from `XCTestCase`
4. Add test methods (must start with `test`)
5. Use XCTest assertions: `XCTAssertEqual`, `XCTAssertTrue`, etc.

Example:
```swift
import XCTest
@testable import Notable

final class MyFeatureTests: XCTestCase {
    func testMyFeature() {
        // Arrange
        let input = "test"

        // Act
        let result = myFunction(input)

        // Assert
        XCTAssertEqual(result, "expected")
    }
}
```

## CI/CD Integration

These tests can be integrated into the CI pipeline:

```bash
# In ci_scripts/ci_post_clone.sh
xcodebuild test \
  -scheme Notable \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -resultBundlePath TestResults.xcresult
```

## Coverage Reports

To generate code coverage:

1. In Xcode: Product → Scheme → Edit Scheme → Test → Options → Check "Code Coverage"
2. Run tests (Cmd + U)
3. View coverage: Cmd + 9 → Coverage tab

Or via command line:
```bash
xcodebuild test \
  -scheme Notable \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

## Future Test Additions

Recommended tests to add:

1. **CoreData Tests**: Test Entry and Pile creation, relationships, deletion
2. **SVDB Tests**: Test search indexing and query results
3. **Transcription Tests**: Test WhisperKit and Apple Speech integration (may require mocking)
4. **CloudKit Sync Tests**: Test sync state management
5. **UI Tests**: Add UI testing target for critical user flows
6. **Performance Tests**: Use XCTestCase performance tests for SVDB indexing

## Mocking and Test Helpers

Consider creating test helpers for:
- Mock NSManagedObjectContext for CoreData tests
- Sample Entry/Pile fixtures
- Mock TranscriptionService for audio tests
