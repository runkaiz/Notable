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
    
    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                List(selection: $selection) {
                    ForEach(entries, id: \.id) { entry in
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
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if tabSelection == .tab1 {
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
