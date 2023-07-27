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
    let persistenceController = PersistenceController.shared
    let connectivity = Connectivity.shared
    
    init() {
        var piles: [Pile] = []
        
        do {
            // Create fetch request.
            let fetchRequest: NSFetchRequest<Pile> = Pile.fetchRequest()

            // Edit the sort key as appropriate.
            let sortDescriptor = NSSortDescriptor(key: #keyPath(Pile.name), ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]

            piles = try persistenceController.container.viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch: \(error)")
        }
        
        connectivity.send(piles: piles)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
