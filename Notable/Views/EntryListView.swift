//
//  EntryListView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/25/23.
//

import SwiftUI
import CoreData
import PhotosUI

struct EntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .none)
    private var entries: FetchedResults<Entry>
    
    @State var pile: Pile
    
    @State private var organizedList: [Entry] = [Entry]()
    @State private var selection: Entry?
    
    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    
    var body: some View {
        List(selection: $selection) {
            Section {
                Group {
                    Label("Description", systemImage: "info.circle").labelStyle(ColorfulIconLabelStyle(color: .gray))
                    
                    TextEditor(text: $pile.desc ?? "")
                        .frame(minHeight: 50)
                }
            }
            .onAppear {
                if pile.desc == nil {
                    pile.desc = ""
                }
                
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            .onChange(of: pile.desc) {
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            
            if organizedList.isEmpty {
                Text("Add some entries to start your pile.")
            }
            
            ForEach(organizedList, id: \.id) { entry in
                EntryTransformer(entry: entry)
            }
#if os(iOS)
            .onDelete(perform: deleteEntries)
#endif
        }
        .listStyle(.grouped)
        .navigationTitle(pile.name ?? "error")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !organizedList.isEmpty {
                    EditButton()
                }
            }
#endif
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: addEntry) {
                        Label("New Text Entry", systemImage: "doc.badge.plus")
                    }
                    Button(action: togglePicker) {
                        Label("New Image Entry", systemImage: "photo.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            updateOrganizedList()
        }
        .onChange(of: selectedImage) {
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                    addPicture(image: data)
                    
                    return
                }
                
                print("Failed")
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedImage, matching: .any(of: [.images, .screenshots]), preferredItemEncoding: .automatic)
    }
    
    private func updateOrganizedList() {
        organizedList.removeAll()
        
        for entry in entries {
            if let pileID = pile.id {
                if entry.pile?.id == pileID {
                    organizedList.append(entry)
                }
            } else {
                pile.id = UUID()
                
                if let pileID = pile.id {
                    if entry.pile?.id == pileID {
                        organizedList.append(entry)
                    }
                }
            }
        }
    }
    
    private func addPicture(image: Data) {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.image.rawValue
            newEntry.image = image
            pile.addToEntries(newEntry)
            
            selection = nil
            
            do {
                try viewContext.save()
                updateOrganizedList()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func togglePicker() {
        showPhotosPicker.toggle()
    }
    
    private func addEntry() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.title = "Untitled"
            newEntry.content = ""
            newEntry.isRichText = false
            newEntry.language = "markdown"
            pile.addToEntries(newEntry)
            
            selection = nil
            
            do {
                try viewContext.save()
                updateOrganizedList()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            
            selection = nil
            
            do {
                try viewContext.save()
                updateOrganizedList()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteEntry() {
        viewContext.delete(entries[entries.firstIndex(of: selection!)!])
        
        // Reset selection
        selection = nil
        
        do {
            try viewContext.save()
            updateOrganizedList()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .font(.system(size: 17))
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 7).frame(width: 28, height: 28).foregroundColor(color))
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
