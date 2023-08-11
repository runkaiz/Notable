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

    @EnvironmentObject var actionService: ActionService
    @Environment(\.scenePhase) var scenePhase
    
    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .none)
    private var piles: FetchedResults<Pile>

    @State private var tabSelection: Tabs = .tab1
    @State private var presentAlert = false
    @State private var presentRenamer = false
    @State private var newPileName = ""

    @State private var selection: Entry?

    @State private var selectedColor: Color?

    @State private var showColorPicker = false

    private var colors: [Color] = [
        Color(red: 39/255, green: 39/255, blue: 39/255),
        Color(red: 241/255, green: 113/255, blue: 5/255),
        Color(red: 160/255, green: 210/255, blue: 219/255)
    ]

    @State private var contextPile: Pile?

    @State private var emptyTagAnimateTrigger = false
    
    @State public var shouldPushToOrphan = false

    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                List(selection: $selection) {
                    Section {
                        NavigationLink {
                            OrphanEntriesView(didGetPushedHere: $shouldPushToOrphan)
                        } label: {
                            HStack{
                                Image(systemName: "tray.and.arrow.down.fill")
                                Text("Inbox")
                            }
                        }
                    }
                    .navigationDestination(isPresented: $shouldPushToOrphan) {
                        OrphanEntriesView(didGetPushedHere: $shouldPushToOrphan )
                    }
                    
                    ForEach(piles, id: \.id) { pile in
                        NavigationLink {
                            EntryListView(pile: pile)
                        } label: {
                            PileItem(pile: pile)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                            Button(role: .destructive) {
                                viewContext.delete(pile)
                                save(viewContext)
                            } label: {
                                Text("Delete")
                            }
                            Button {
                                contextPile = pile
                                showColorPicker.toggle()
                            } label: {
                                Text("Color")
                            }
                            .tint(.brown)
                            Button {
                                contextPile = pile
                                newPileName = pile.name ?? ""
                                presentRenamer.toggle()
                            } label: {
                                Text("Rename")
                            }
                        })
                        .contextMenu {
                            Button {
                                contextPile = pile
                                newPileName = pile.name ?? ""
                                presentRenamer.toggle()
                            } label: {
                                Text("Rename")
                            }
                            Button {
                                contextPile = pile
                                showColorPicker.toggle()
                            } label: {
                                Text("Change Color")
                            }
                            Button(role: .destructive) {
                                contextPile = pile
                                deletePile()
                            } label: {
                                Text("Delete Pile")
                            }
                        }
                    }
#if os(iOS)
                    .onDelete(perform: deletePiles)
#endif
                }
                .tabItem {
                    Label("Piles", systemImage: "tray.2.fill")
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
            .alert("Rename Pile", isPresented: $presentRenamer, actions: {
                TextField("Pile Name", text: $newPileName)

                Button("Rename", action: {
                    contextPile!.name = newPileName
                    save(viewContext)
                    newPileName = ""
                })
                Button("Cancel", role: .cancel, action: {})
            })
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
        }
        .sheet(isPresented: $showColorPicker) {

        } content: {
            let size = CGFloat(44)

            HStack(spacing: 25) {
                Button {
                    selectedColor = colors[0]
                    contextPile!.tag = "Raisin Black"
                    save(viewContext)
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
                    save(viewContext)
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
                    save(viewContext)
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
                    save(viewContext)
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
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                performActionIfNeeded()
            default:
                break
            }
        }

    }
    
    func performActionIfNeeded() {
        guard let action = actionService.action else { return }

        switch action {
        case .newEntry:
            newEntry()
        }

        actionService.action = nil
    }

    enum Tabs {
        case tab1, tab2
    }

    func toggleAlert() {
        presentAlert.toggle()
    }

    // This function will return the correct NavigationBarTitle when different tab is selected.
    func returnNaviBarTitle(tabSelection: Tabs) -> Text {
        switch tabSelection {
        case .tab1: return Text("Piles")
        case .tab2: return Text("Settings")
        }
    }
    
    private func newEntry() {
        tabSelection = .tab1
        shouldPushToOrphan.toggle()
    }

    private func deletePile() {
        withAnimation {
            viewContext.delete(piles[piles.firstIndex(of: contextPile!)!])

            save(viewContext)
        }
    }

    private func addFolder() {
        withAnimation {
            let newPile = Pile(context: viewContext)
            newPile.id = UUID()
            newPile.name = newPileName

            newPileName = ""

            save(viewContext)
        }
    }

    private func deletePiles(offsets: IndexSet) {
        withAnimation {
            offsets.map { piles[$0] }.forEach(viewContext.delete)

            save(viewContext)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
