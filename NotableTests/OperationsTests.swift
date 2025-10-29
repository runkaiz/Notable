//
//  OperationsTests.swift
//  NotableTests
//
//  Created by Runkai Zhang
//

import XCTest
@testable import Notable

final class OperationsTests: XCTestCase {

    // MARK: - Text Cleaning Tests

    func testCleanText_RemovesNewlines() {
        let input = "Hello\nWorld"
        let expected = "Hello World"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_RemovesCarriageReturns() {
        let input = "Hello\rWorld"
        let expected = "Hello World"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_RemovesMarkdownHeadings() {
        let input = "# Heading"
        let expected = "Heading"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_RemovesMarkdownEmphasis() {
        let input = "*bold* and _italic_ text"
        let expected = "bold and italic text"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_RemovesCodeMarkers() {
        let input = "`code` snippet"
        let expected = "code snippet"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_RemovesMultipleSpaces() {
        let input = "Hello    World"
        let expected = "Hello World"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_TrimsWhitespace() {
        let input = "  Hello World  "
        let expected = "Hello World"
        let result = cleanText(input)
        XCTAssertEqual(result, expected)
    }

    func testCleanText_ComplexMarkdown() {
        let input = """
        # Title
        ## Subtitle

        This is *bold* and _italic_ text.
        Here's some `code`.

        - List item 1
        - List item 2
        """
        let result = cleanText(input)

        // Should remove all markdown syntax
        XCTAssertFalse(result.contains("#"))
        XCTAssertFalse(result.contains("*"))
        XCTAssertFalse(result.contains("_"))
        XCTAssertFalse(result.contains("`"))
        XCTAssertFalse(result.contains("\n"))
    }

    // MARK: - URL Validation Tests

    func testVerifyUrl_ValidHTTPURL() {
        let url = "https://www.example.com"
        XCTAssertTrue(verifyUrl(urlString: url))
    }

    func testVerifyUrl_ValidHTTPSURL() {
        let url = "https://www.example.com"
        XCTAssertTrue(verifyUrl(urlString: url))
    }

    func testVerifyUrl_InvalidURL() {
        let url = "not a url"
        XCTAssertFalse(verifyUrl(urlString: url))
    }

    func testVerifyUrl_NilURL() {
        XCTAssertFalse(verifyUrl(urlString: nil))
    }

    func testVerifyUrl_EmptyString() {
        let url = ""
        XCTAssertFalse(verifyUrl(urlString: url))
    }

    // MARK: - Audio Duration Tests

    func testGetAudioDuration_InvalidData() {
        let invalidData = Data([0x00, 0x01, 0x02])
        let duration = getAudioDuration(from: invalidData)
        XCTAssertEqual(duration, 0.0)
    }
}
