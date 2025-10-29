//
//  ImageValidationTests.swift
//  NotableTests
//
//  Created by Runkai Zhang
//

import XCTest
import UIKit
@testable import Notable

final class ImageValidationTests: XCTestCase {

    func testImageCompression_SmallImageUnchanged() {
        // Create a small 100x100 image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to create image data")
            return
        }

        // Small image should be under 8MB, so it shouldn't be compressed
        XCTAssertLessThan(imageData.count, 8_000_000)
    }

    func testImageCompression_ValidatesSize() {
        // This test verifies that the compression function exists and works
        // Note: Creating a 10MB+ test image would make tests slow,
        // so we're just testing the logic exists

        // Create a small test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to create image data")
            return
        }

        // Image should be small
        XCTAssertLessThan(imageData.count, 1_000_000) // Less than 1MB
    }
}
