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

    @State private var selectedColor: Color?

    @State private var showColorPicker = false

    @State private var colors: [Color] = [
        Color(red: 39/255, green: 39/255, blue: 39/255),
        Color(red: 241/255, green: 113/255, blue: 5/255),
        Color(red: 160/255, green: 210/255, blue: 219/255)
    ]

    @State private var contextPile: Pile?

    @State private var emptyTagAnimateTrigger = false

    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                List(selection: $selection) {
                    ForEach(piles, id: \.id) { pile in
                        NavigationLink {
                            EntryListView(pile: pile)
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text(pile.name ?? "")
                                Spacer()
                                if let tagColor = pile.tag {
                                    switch tagColor {
                                    case "Raisin Black":
                                        Circle().fill(colors[0]).frame(width: 10, height: 10)
                                    case "Safety Orange":
                                        Circle().fill(colors[1]).frame(width: 10, height: 10)
                                    case "Non Photo Blue":
                                        Circle().fill(colors[2]).frame(width: 10, height: 10)
                                    default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .contextMenu(ContextMenu(menuItems: {
                            Button {
                            } label: {
                                Text("Rename")
                            }
                            Button {
                                contextPile = pile
                                showColorPicker.toggle()
                            } label: {
                                Text("Change Color")
                            }

                        }))
                    }
#if os(iOS)
                    .onDelete(perform: deletePiles)
#endif
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
            .toolbar {
                if tabSelection == .tab1 {
    #if os(iOS)
                    if !piles.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
    #endif
                    ToolbarItem(placement: .navigationBarTrailing) {
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
        .sheet(isPresented: $showColorPicker) {

        } content: {
            let size = CGFloat(44)

            HStack(spacing: 25) {
                Button {
                    selectedColor = colors[0]
                    contextPile!.tag = "Raisin Black"
                    save()
                } label: {
                    if selectedColor == colors[0] {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 4)
                            .background(Circle().foregroundStyle(colors[0]))
                            .frame(width: size, height: size)
                    } else {
                        Circle()
                            .foregroundStyle(colors[0])
                            .frame(width: size, height: size)
                    }
                }
                Button {
                    selectedColor = colors[1]
                    contextPile!.tag = "Safety Orange"
                    save()
                } label: {
                    if selectedColor == colors[1] {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 4)
                            .background(Circle().foregroundStyle(colors[1]))
                            .frame(width: size, height: size)
                    } else {
                        Circle()
                            .foregroundStyle(colors[1])
                            .frame(width: size, height: size)
                    }
                }
                Button {
                    selectedColor = colors[2]
                    contextPile!.tag = "Non Photo Blue"
                    save()
                } label: {
                    if selectedColor == colors[2] {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 4)
                            .background(Circle().foregroundStyle(colors[2]))
                            .frame(width: size, height: size)
                    } else {
                        Circle()
                            .foregroundStyle(colors[2])
                            .frame(width: size, height: size)
                    }
                }
                Button {
                    emptyTagAnimateTrigger.toggle()
                    selectedColor = nil
                    contextPile!.tag = nil
                    save()
                } label: {
                    Image(systemName: "circle.dotted")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                }
                .symbolEffect(.bounce, value: emptyTagAnimateTrigger)
            }
            .presentationDetents([.fraction(0.15)])
            .onAppear {
                switch contextPile!.tag {
                case "Raisin Black":
                    selectedColor = colors[0]
                case "Safety Orange":
                    selectedColor = colors[1]
                case "Non Photo Blue":
                    selectedColor = colors[2]
                default:
                    selectedColor = nil
                }
            }
        }
    }

    enum Tabs {
        case tab1, tab2
    }

    func toggleAlert() {
        presentAlert.toggle()
    }

    // This function will return the correct NavigationBarTitle when different tab is selected.
    func returnNaviBarTitle(tabSelection: Tabs) -> String {
        switch tabSelection {
        case .tab1: return "Piles"
        case .tab2: return "Settings"
        }
    }

    private func save() {
        withAnimation {
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
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
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
