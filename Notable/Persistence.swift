//
//  Persistence.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let newPile = Pile(context: viewContext)
        newPile.id = UUID()
        newPile.name = "Example Pile"
        newPile.desc = "Example description for an example pile"
        newPile.tag = "Non Photo Blue"

        for _ in 0..<10 {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.title = "Test"
            newEntry.content = "# lalala\nlalalal"
            newEntry.isMarkdown = true
            newEntry.language = "markdown"
            newEntry.type = "text"

            newPile.addToEntries(newEntry)
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Notable")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
