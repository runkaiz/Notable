//
//  DataMigrationTests.swift
//  NotableTests
//
//  Created by Runkai Zhang
//

import XCTest
@testable import Notable

final class DataMigrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset migration state before each test
        UserDefaults.standard.removeObject(forKey: "LastMigratedVersion")
        UserDefaults.standard.removeObject(forKey: "MigrationHistory")
    }

    func testMigrationHistory_InitiallyEmpty() {
        let history = DataMigrationManager.shared.getMigrationHistory()
        XCTAssertEqual(history.count, 0)
    }

    func testResetMigrationState() {
        // This test verifies the reset function works
        DataMigrationManager.shared.resetMigrationState()

        let lastVersion = UserDefaults.standard.string(forKey: "LastMigratedVersion")
        let history = UserDefaults.standard.stringArray(forKey: "MigrationHistory")

        XCTAssertNil(lastVersion)
        XCTAssertNil(history)
    }
}
