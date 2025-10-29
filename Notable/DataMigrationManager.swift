//
//  DataMigrationManager.swift
//  Notable
//
//  Created by Runkai Zhang
//

import Foundation
import CoreData
import os.log

/// Manages data migrations between app versions
public class DataMigrationManager {
    public static let shared = DataMigrationManager()

    private let lastMigratedVersionKey = "LastMigratedVersion"
    private let migrationHistoryKey = "MigrationHistory"

    /// Version-specific migration closures
    private var migrations: [String: () async -> Bool] = [:]

    private init() {
        registerMigrations()
    }

    /// Registers all version-specific migrations
    private func registerMigrations() {
        // Example: Migration for version 2.0
        migrations["2.0"] = {
            await self.migrate_to_2_0()
        }

        // Future migrations can be added here
        // migrations["2.1"] = { await self.migrate_to_2_1() }
    }

    /// Performs necessary migrations based on current and last migrated version
    public func performMigrationsIfNeeded() async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            os_log("❌ Could not read current app version", log: .default, type: .error)
            return
        }

        let lastMigratedVersion = UserDefaults.standard.string(forKey: lastMigratedVersionKey)

        // If same version, no migration needed
        if lastMigratedVersion == currentVersion {
            os_log("✅ App version unchanged (%{public}@), no migration needed",
                   log: .default, type: .info, currentVersion)
            return
        }

        os_log("📦 Migrating from version %{public}@ to %{public}@",
               log: .default,
               type: .info,
               lastMigratedVersion ?? "none",
               currentVersion)

        // Perform version-specific migrations
        if let migration = migrations[currentVersion] {
            let success = await migration()

            if success {
                os_log("✅ Migration to %{public}@ completed successfully",
                       log: .default, type: .info, currentVersion)

                // Record successful migration
                recordMigration(to: currentVersion)
            } else {
                os_log("❌ Migration to %{public}@ failed",
                       log: .default, type: .error, currentVersion)
            }
        } else {
            // No specific migration for this version, just update the version marker
            os_log("ℹ️ No specific migration defined for %{public}@, updating version marker",
                   log: .default, type: .info, currentVersion)
            UserDefaults.standard.set(currentVersion, forKey: lastMigratedVersionKey)
        }
    }

    /// Records a successful migration in history
    private func recordMigration(to version: String) {
        UserDefaults.standard.set(version, forKey: lastMigratedVersionKey)

        // Also append to migration history
        var history = UserDefaults.standard.stringArray(forKey: migrationHistoryKey) ?? []
        let timestamp = ISO8601DateFormatter().string(from: Date())
        history.append("\(version) - \(timestamp)")
        UserDefaults.standard.set(history, forKey: migrationHistoryKey)

        os_log("📝 Migration history updated: %{public}@", log: .default, type: .debug, history.joined(separator: ", "))
    }

    // MARK: - Version-Specific Migrations

    /// Migration to version 2.0
    /// - Returns: Success status
    private func migrate_to_2_0() async -> Bool {
        os_log("🚀 Running migration to 2.0...", log: .default, type: .info)

        // Example migration tasks for 2.0:
        // 1. Any CoreData schema changes are handled by CoreData lightweight migration
        // 2. SVDB rebuild is handled by SharedData
        // 3. Any new feature initializations can go here

        // For now, this is a placeholder showing the pattern
        // In the future, add actual migration logic here

        os_log("✅ 2.0 migration completed", log: .default, type: .info)
        return true
    }

    // MARK: - Utility Methods

    /// Gets migration history for debugging
    public func getMigrationHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: migrationHistoryKey) ?? []
    }

    /// Resets migration state (use with caution, mainly for debugging)
    public func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: lastMigratedVersionKey)
        UserDefaults.standard.removeObject(forKey: migrationHistoryKey)
        os_log("⚠️ Migration state reset", log: .default, type: .info)
    }
}
