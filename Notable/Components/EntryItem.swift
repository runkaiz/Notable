//
//  EntryItem.swift
//  Notable
//
//  Created by Runkai Zhang on 7/5/23.
//

import SwiftUI
import CoreData

enum EntryType: String {
    case text
    case image
}

struct EntryItem: View {
    @ObservedObject var entry: Entry
    var type: EntryType
    
    init(entry: Entry) {
        self.entry = entry
        self.type = EntryType(rawValue: entry.type ?? "text")!
    }
    
    var body: some View {
        switch type {
        case .image:
            Image(uiImage: UIImage(data: entry.image ?? Data()) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
        default:
            VStack(alignment: .leading) {
                Text(entry.title ?? "")
                    .font(.headline)
                Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                    .font(.subheadline)
            }
        }
        
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct EntryItem_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
