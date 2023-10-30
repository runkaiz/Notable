//
//  OrphanEntriesView.swift
//  Notable
//
//  Created by Runkai Zhang on 8/8/23.
//

import SwiftUI
import PhotosUI

struct OrphanEntriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>
    
    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .default)
    private var piles: FetchedResults<Pile>
    
    @Binding public var didGetPushedHere: Bool
    
    @State private var selection: Entry?
    
    @State private var presentEntryRenamer = false
    @State private var newEntryName = ""
    
    @State private var showLinkPrompt = false
    @State private var newLink = ""
    
    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    
    @State private var contextEntry: Entry?
    
    @State private var showPileChooser = false
    @State private var selectedPile: Pile?
    
    @State private var isConfirmingImageTools = false
    
    @State private var isImporting = false
    
    var body: some View {
        List(selection: $selection) {
            ForEach(entries, id: \.id) { entry in
                if entry.pile == nil {
                    EntryTransformer(entry: entry)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                            Button(role: .destructive) {
                                viewContext.delete(entry)
                                save(viewContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            if entry.type == EntryType.text.rawValue {
                                Button {
                                    contextEntry = entry
                                    newEntryName = entry.title ?? ""
                                    presentEntryRenamer.toggle()
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }
                            
                            Button {
                                contextEntry = entry
                                if let first = piles.first {
                                    selectedPile = first
                                }
                                
                                showPileChooser.toggle()
                            } label: {
                                Label("Assign", systemImage: "move.3d")
                            }
                            .tint(.accentColor)
                        })
                        .contextMenu {
                            Button {
                                contextEntry = entry
                                if let first = piles.first {
                                    selectedPile = first
                                }
                                
                                showPileChooser.toggle()
                            } label: {
                                Text("Assign to pile")
                            }
                            
                            if entry.type == EntryType.text.rawValue {
                                Button {
                                    contextEntry = entry
                                    newEntryName = entry.title ?? ""
                                    presentEntryRenamer.toggle()
                                } label: {
                                    Text("Rename")
                                }
                            }
                            
                            Button(role: .destructive) {
                                viewContext.delete(entry)
                                
                                save(viewContext)
                            } label: {
                                Text("Delete Entry")
                            }
                        }
                }
            }
#if os(iOS)
            .onDelete(perform: deleteEntries)
#endif
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if didGetPushedHere {
                addEntry(viewContext, pile: nil)
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if entries.contains(where: {$0.pile == nil}) {
                    EditButton()
                }
            }
#endif
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        addEntry(viewContext, pile: nil)
                    } label: {
                        Label("New Text Entry", systemImage: "doc.badge.plus")
                    }
                    Button(action: togglePicker) {
                        Label("New Image Entry", systemImage: "photo.badge.plus")
                    }
                    Button(action: togglePrompt) {
                        Label("New Link Entry", systemImage: "photo.badge.plus")
                    }
                    Button(action: toggleImporter) {
                        Label("Import File", systemImage: "photo.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: selectedImage) {
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                    addPicture(viewContext, image: data, pile: nil)
                    
                    return
                }
                
                print("Failed")
            }
        }
        .confirmationDialog(
            "Choose your source of images.",
            isPresented: $isConfirmingImageTools
        ) {
            Button {
                // No SwiftUI native camera access for now
            } label: {
                Text("Camera")
            }
            
            Button {
                showPhotosPicker.toggle()
            } label: {
                Text("Photos Library")
            }
            
            Button("Cancel", role: .cancel) {
                return
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedImage,
            matching: .any(of: [.images, .screenshots]),
            preferredItemEncoding: .automatic
        )
        .alert("Rename Entry", isPresented: $presentEntryRenamer, actions: {
            TextField("Entry Title", text: $newEntryName)
            
            Button("Rename", action: {
                contextEntry!.title = newEntryName
                save(viewContext)
                newEntryName = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
        .alert("New Link", isPresented: $showLinkPrompt, actions: {
            TextField("Website URL", text: $newLink)
                .keyboardType(.URL)
            
            Button("Add", action: {
                addLink(viewContext, newLink: newLink, pile: nil)
                newLink = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
        .sheet(isPresented: $showPileChooser) {
            
        } content: {
            VStack {
                Picker("Select pile", selection: $selectedPile) {
                    ForEach(piles, id: \.id) { pile in
                        Text(pile.name ?? "")
                            .tag(Optional(pile))
                    }
                }
                .pickerStyle(.wheel)
                
                HStack {
                    Spacer()
                    Button("Assign", action: {
                        assignToPile()
                        showPileChooser.toggle()
                    })
                    .padding()
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.text]) { result in
            switch result {
            case .success(let directory):
                // gain access to the directory
                let gotAccess = directory.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                // access the directory URL
                // (read templates in the directory, make a bookmark, etc.)
                do {
                    let contents = try String(contentsOf: directory, encoding: .utf8)
                    
                    withAnimation {
                        let newEntry = Entry(context: viewContext)
                        newEntry.timestamp = Date()
                        newEntry.id = UUID()
                        newEntry.title = directory.lastPathComponent
                        newEntry.content = contents
                        newEntry.isMarkdown = true
                        newEntry.language = "markdown"
                        newEntry.type = EntryType.text.rawValue
                        
                        save(viewContext)
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                // release access
                directory.stopAccessingSecurityScopedResource()
            case .failure(let error):
                // handle error
                print(error)
            }
        }
    }
    
    private func assignToPile() {
        contextEntry!.pile = selectedPile
        
        save(viewContext)
    }
    
    private func toggleImporter() {
        isImporting.toggle()
    }
    
    private func togglePrompt() {
        showLinkPrompt.toggle()
    }
    
    private func togglePicker() {
        selectedImage = nil
        isConfirmingImageTools.toggle()
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            
            save(viewContext)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
