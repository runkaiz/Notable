//
//  ContentView.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import SwiftUI
import CoreData
import PhotosUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .none)
    private var entries: FetchedResults<Entry>
    
    @State private var selection: Entry?
    @State private var tabSelection: Tabs = .tab1
    
    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                VStack {
                    List(selection: $selection) {
                        ForEach(entries, id: \.id) { entry in
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
#if os(iOS)
                        .onDelete(perform: deleteEntries)
#endif
                    }
#if os(macOS)
                    .onDeleteCommand(perform: selection == nil ? nil : deleteEntry)
#endif
                }
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if tabSelection == .tab1 && !entries.isEmpty {
                            EditButton()
                        }
                    }
#endif
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if tabSelection == .tab1 {
                            
                            Menu {
                                Button(action: addEntry) {
                                    Label("New Text Entry", systemImage: "plus.app")
                                }
                                Button(action: togglePicker) {
                                    Label("New Image Entry", systemImage: "photo.badge.plus")
                                }
                                Button(action: addFolder) {
                                    Label("New Pile", systemImage: "folder.badge.plus")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                            
                        }
                    }
                }
                
                .tabItem {
                    Label("Entries", systemImage: "tray.fill")
                }
                .tag(Tabs.tab1)
#if os(macOS)
                Text("Select an entry")
#endif
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(Tabs.tab2)
            }
#if os(iOS)
            .navigationBarTitle(returnNaviBarTitle(tabSelection: self.tabSelection))
#endif
            .onAppear {
                selection = nil
            }
            .onChange(of: selectedImage) { _ in
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
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    enum Tabs{
        case tab1, tab2
    }
    
    // This function will return the correct NavigationBarTitle when different tab is selected.
    func returnNaviBarTitle(tabSelection: Tabs) -> String {
        switch tabSelection{
        case .tab1: return "Entries"
        case .tab2: return "Settings"
        }
    }
    
    private func addFolder() {
        
    }
    
    private func addPicture(image: Data) {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.image.rawValue
            newEntry.image = image
            
            selection = nil
            
            do {
                // TODO: Handle this properly
                let fetchRequest: NSFetchRequest<Pile> = Pile.fetchRequest()
                
                let id = "default"
                fetchRequest.predicate = NSPredicate(format: "name = %d", id)
                
                let matchingItems = try viewContext.fetch(fetchRequest)
                if !matchingItems.isEmpty {
                    // Default exists
                    matchingItems.first?.addToEntries(newEntry)
                } else {
                    // Entry does not exist
                    let newPile = Pile(context: viewContext)
                    newPile.name = "default"
                    newPile.addToEntries(newEntry)
                    print("Entry does not exist in CoreData.")
                }
                
                try viewContext.save()
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
            
            selection = nil
            
            do {
                try viewContext.save()
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
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension UIApplication {
    /// Resigns the keyboard.
    ///
    /// Used for resigning the keyboard when pressing the cancel button in a searchbar based on [this](https://stackoverflow.com/a/58473985/3687284) solution.
    /// - Parameter force: set true to resign the keyboard.
    func endEditing(_ force: Bool) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}
