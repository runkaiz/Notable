//
//  Operations.swift
//  Notable
//
//  Created by Runkai Zhang on 8/11/23.
//

import CoreData
import SwiftUI

public func addEntry(_ viewContext: NSManagedObjectContext, pile: Pile?) {
    withAnimation {
        let newEntry = Entry(context: viewContext)
        newEntry.timestamp = Date()
        newEntry.id = UUID()
        newEntry.title = "Untitled"
        newEntry.content = ""
        newEntry.isMarkdown = true
        newEntry.language = "markdown"
        newEntry.type = EntryType.text.rawValue
        
        if let pile = pile {
            pile.addToEntries(newEntry)
        }
        
        save(viewContext)
    }
}

public func addPicture(_ viewContext: NSManagedObjectContext, image: Data, pile: Pile?) {
    withAnimation {
        let newEntry = Entry(context: viewContext)
        newEntry.timestamp = Date()
        newEntry.id = UUID()
        newEntry.type = EntryType.image.rawValue
        newEntry.image = image
        
        if let pile = pile {
            pile.addToEntries(newEntry)
        }
        
        save(viewContext)
    }
}

public func addLink(_ viewContext: NSManagedObjectContext, newLink: String, pile: Pile?) {
    withAnimation {
        if verifyUrl(urlString: newLink) {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.link.rawValue
            newEntry.link = URL(string: newLink)
            
            if let pile = pile {
                pile.addToEntries(newEntry)
            }
            
            save(viewContext)
        } else {
            // Handle error here
        }
    }
}

public func verifyUrl (urlString: String?) -> Bool {
   if let urlString = urlString {
       if let url  = URL(string: urlString) {
           return UIApplication.shared.canOpenURL(url)
       }
   }
   return false
}

public func deleteEntry(_ viewContext: NSManagedObjectContext, entries: [Entry], selection: Entry?) {
    withAnimation {
        viewContext.delete(entries[entries.firstIndex(of: selection!)!])
        
        save(viewContext)
    }
}

public func save(_ viewContext: NSManagedObjectContext) {
    do {
        try viewContext.save()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
}
