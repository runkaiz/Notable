//
//  NotableApp.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import SwiftUI
import CoreData

@main
struct NotableApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared

    private let actionService = ActionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(actionService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
