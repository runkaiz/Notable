//
//  EntryTransformer.swift
//  Notable
//
//  Created by Runkai Zhang on 7/25/23.
//

import SwiftUI

struct EntryTransformer: View {
    
    @State var entry: Entry
    
    var body: some View {
        if entry.type != "image" {
            NavigationLink {
                EditorView(entry: entry)
            } label: {
                EntryItem(entry: entry)
            }
        } else {
            EntryItem(entry: entry)
        }
    }
}
