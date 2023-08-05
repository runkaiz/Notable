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

                save()
            }
            .onChange(of: pile.desc) {
                save()
            }

            if entries.isEmpty {
                Text("Add some entries to start your pile.")
            }

            ForEach(entries, id: \.id) { entry in
                if entry.pile == pile {
                    EntryTransformer(entry: entry)
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
                .foregroundColor(.black)
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
                withAnimation {
                    pile.name = newPileName
                    save()
                    newPileName = ""
                }
            })
            Button("Cancel", role: .cancel, action: {})
        })
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

            save()
        }
    }

    private func togglePicker() {
        selectedImage = nil
        showPhotosPicker.toggle()
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
            pile.addToEntries(newEntry)

            selection = nil

            save()
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)

            selection = nil

            save()
        }
    }

    private func deleteEntry() {
        viewContext.delete(entries[entries.firstIndex(of: selection!)!])

        // Reset selection
        selection = nil

        save()
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
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
