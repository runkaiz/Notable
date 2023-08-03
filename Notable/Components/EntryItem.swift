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
            Section {
                Image(uiImage: UIImage(data: entry.image ?? Data()) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .listRowInsets(EdgeInsets())
                Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                    .font(.subheadline)
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.word.spacing")
                    Text(entry.title ?? "")
                }
                Text(entry.content?.replacingOccurrences(of: "\n", with: " ") ?? "")
                    .lineLimit(3)
                    .font(.body)
                Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                    .font(.footnote)
            }
            .padding(.vertical, 6)
        }
        
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
