//
//  SharedData.swift
//  Notable
//
//  Created by Runkai Zhang on 9/24/23.
//

import Foundation
import SVDB

public class SharedData: ObservableObject {
    @Published var database: Collection? = nil
    @Published var needsDatabaseRebuild: Bool = false
    @Published var transcriptionService: TranscriptionService

    // SVDB indexing progress
    @Published var isIndexing: Bool = false
    @Published var indexingProgress: Double = 0.0
    @Published var indexedCount: Int = 0
    @Published var totalToIndex: Int = 0

    private let lastVersionKey = "LastLaunchedVersion"

    init() {
        database = try? SVDB.shared.collection("entries")
        transcriptionService = TranscriptionService()
        checkVersionAndMarkForRebuild()
    }

    private func checkVersionAndMarkForRebuild() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Warning: Could not read app version")
            return
        }

        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)

        if lastVersion != currentVersion {
            // Version changed or first launch
            print("Version changed from \(lastVersion ?? "none") to \(currentVersion). Marking SVDB for rebuild.")
            needsDatabaseRebuild = true

            // Clear and rebuild the database
            database?.clear()

            // Update stored version
            UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
        } else {
            print("Same version (\(currentVersion)). SVDB rebuild not needed.")
            needsDatabaseRebuild = false
        }
    }

    /// Force rebuild the database (useful for manual triggers)
    public func forceRebuild() {
        print("Force rebuilding SVDB...")
        database?.clear()
        needsDatabaseRebuild = true
    }
}
