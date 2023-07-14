//
//  ContentView.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .none)
    private var entries: FetchedResults<Entry>
    
    @State private var selection: Entry?
    @State var tabSelection: Tabs = .tab1
    
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                VStack {
                    // Search view
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            
                            TextField("search", text: $searchText, onEditingChanged: { isEditing in
                                withAnimation {
                                    self.showCancelButton = true
                                }
                            }).foregroundColor(.primary)
                            
                            Button(action: {
                                self.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                        .foregroundColor(.secondary)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10.0)
                        
                        if showCancelButton  {
                            Button("Cancel") {
                                UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                                self.searchText = ""
                                self.showCancelButton = false
                            }
                            .foregroundColor(Color(.systemBlue))
                        }
                    }
                    .padding(.horizontal)
                    .navigationBarHidden(showCancelButton)
                    
                    List(selection: $selection) {
                        ForEach(entries.filter{$0.title!.hasPrefix(searchText) || searchText == ""}, id: \.id) { entry in
                            NavigationLink {
                                EditorView(entry: entry)
                            } label: {
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
                            Button(action: addEntry) {
                                Label("Add Entry", systemImage: "plus")
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
        }.onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    enum Tabs{
        case tab1, tab2
    }
    
    // This function will return the correct NavigationBarTitle when different tab is selected.
    func returnNaviBarTitle(tabSelection: Tabs) -> String{
        switch tabSelection{
        case .tab1: return "Entries"
        case .tab2: return "Settings"
        }
    }
    
    private func addEntry() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.title = "Untitled"
            newEntry.content = ""
            newEntry.isRichText = false
            
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
