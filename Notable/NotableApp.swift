//
//  NotableApp.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import CoreData
import SwiftUI

@main
struct NotableApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sharedData = SharedData()

    let persistenceController = PersistenceController.shared

    private let actionService = ActionService.shared

    init() {
        // Perform data migrations on app launch
        Task {
            await DataMigrationManager.shared.performMigrationsIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(actionService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sharedData)
        }
    }
}
