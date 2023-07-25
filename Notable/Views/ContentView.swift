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
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .none)
    private var piles: FetchedResults<Pile>
    
    @State private var tabSelection: Tabs = .tab1
    @State private var presentAlert = false
    @State private var newPileName = ""
    
    @State private var selection: Entry?
    
    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                List(selection: $selection) {
                    ForEach(piles, id: \.id) { pile in
                        NavigationLink {
                            EntryListView(pile: pile)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(pile.name ?? "Unamed")
                                    .font(.headline)
                            }
                        }
                    }
#if os(iOS)
                    .onDelete(perform: deletePiles)
#endif
                }
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if tabSelection == .tab1 && !piles.isEmpty {
                            EditButton()
                        }
                    }
#endif
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if tabSelection == .tab1 {
                            Menu {
                                Button(action: toggleAlert) {
                                    Label("New Pile", systemImage: "folder.badge.plus")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Piles", systemImage: "tray.fill")
                }
                .tag(Tabs.tab1)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(Tabs.tab2)
            }
            .alert("Name Pile", isPresented: $presentAlert, actions: {
                TextField("Pile Name", text: $newPileName)
                
                Button("Create", action: addFolder)
                Button("Cancel", role: .cancel, action: {})
            })
#if os(iOS)
            .navigationBarTitle(returnNaviBarTitle(tabSelection: self.tabSelection))
#endif
            }
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            selection = nil
        }
    }
    
    enum Tabs{
        case tab1, tab2
    }
    
    func toggleAlert() {
        presentAlert.toggle()
    }
    
    // This function will return the correct NavigationBarTitle when different tab is selected.
    func returnNaviBarTitle(tabSelection: Tabs) -> String {
        switch tabSelection{
        case .tab1: return "Piles"
        case .tab2: return "Settings"
        }
    }
    
    private func addFolder() {
        withAnimation {
            let newPile = Pile(context: viewContext)
            newPile.id = UUID()
            newPile.name = newPileName
            
            newPileName = ""
            
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
    
    private func deletePiles(offsets: IndexSet) {
        withAnimation {
            offsets.map { piles[$0] }.forEach(viewContext.delete)

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
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
