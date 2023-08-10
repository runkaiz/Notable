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
        animation: .default)
    private var entries: FetchedResults<Entry>

    @State var pile: Pile

    @State private var selection: Entry?

    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?

    @State private var presentRenamer = false
    @State private var newPileName = ""
    
    @State private var contextEntry: Entry?
    
    @State private var presentEntryRenamer = false
    @State private var newEntryName = ""
    
    @State private var showLinkPrompt = false
    @State private var newLink = ""

    var body: some View {
        List(selection: $selection) {
            Section {
                VStack {
                    HStack {
                        Image(systemName: "info.square")
                        Text("Description")
                        Spacer()
                    }
                    .dismissKeyboardOnTap()
                    .padding(.top, 12)
                    .padding(.horizontal)
                    Divider()
                    TextField("Description", text: $pile.desc ?? "", axis: .vertical)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }.listRowInsets(EdgeInsets())
            }
            .onAppear {
                if pile.desc == nil {
                    pile.desc = ""
                }

                save(viewContext)
            }
            .onChange(of: pile.desc) {
                save(viewContext)
            }

            if entries.isEmpty {
                Text("Add some entries to start your pile.")
            }

            ForEach(entries, id: \.id) { entry in
                if entry.pile == pile {
                    EntryTransformer(entry: entry)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                            Button(role: .destructive) {
                                viewContext.delete(entry)
                                save(viewContext)
                            } label: {
                                Text("Delete")
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
                        })
                        .contextMenu {
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
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(pile.name ?? "Error") {
                    newPileName = pile.name ?? ""
                    presentRenamer.toggle()
                }
                .bold()
                .foregroundColor(.primary)
            }
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if entries.contains(where: {$0.pile == pile}) {
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
                    Button(action: togglePrompt) {
                        Label("New Link Entry", systemImage: "photo.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
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
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedImage,
            matching: .any(of: [.images, .screenshots]),
            preferredItemEncoding: .automatic
        )
        .alert("Rename Pile", isPresented: $presentRenamer, actions: {
            TextField("Pile Name", text: $newPileName)

            Button("Rename", action: {
                pile.name = newPileName
                save(viewContext)
                newPileName = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
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
                addLink()
                newLink = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
    }
    
    private func togglePrompt() {
        showLinkPrompt.toggle()
    }

    private func togglePicker() {
        selectedImage = nil
        showPhotosPicker.toggle()
    }
    
    private func addPicture(image: Data) {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.image.rawValue
            newEntry.image = image
            pile.addToEntries(newEntry)

            save(viewContext)
        }
    }
    
    private func addLink() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.link.rawValue
            newEntry.link = URL(string: newLink)

            pile.addToEntries(newEntry)

            save(viewContext)
        }
    }

    private func addEntry() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.title = "Untitled"
            newEntry.content = ""
            newEntry.isMarkdown = true
            newEntry.language = "markdown"
            newEntry.type = EntryType.text.rawValue
            pile.addToEntries(newEntry)

            save(viewContext)
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)

            save(viewContext)
        }
    }

    private func deleteEntry() {
        viewContext.delete(entries[entries.firstIndex(of: selection!)!])

        save(viewContext)
    }
}

public extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

public struct DismissKeyboardOnTap: ViewModifier {
    public func body(content: Content) -> some View {
#if os(macOS)
        return content
#else
        return content.gesture(tapGesture)
#endif
    }

    private var tapGesture: some Gesture {
        TapGesture().onEnded(endEditing)
    }

    private func endEditing() {
        UIApplication.shared.connectedScenes
            .filter {$0.activationState == .foregroundActive}
            .map {$0 as? UIWindowScene}
            .compactMap({$0})
            .first?.windows
            .filter {$0.isKeyWindow}
            .first?.endEditing(true)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
