//
//  OrphanEntriesView.swift
//  Notable
//
//  Created by Runkai Zhang on 8/8/23.
//

import SwiftUI

struct OrphanEntriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>
    
    var body: some View {
        List {
            ForEach(entries, id: \.id) { entry in
                if entry.pile == nil {
                    EntryTransformer(entry: entry)
                }
            }
#if os(iOS)
            .onDelete(perform: deleteEntries)
#endif
        }
        .navigationTitle("Orphaned Entries")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)

            save(viewContext)
        }
    }
}

#Preview {
    OrphanEntriesView()
}
