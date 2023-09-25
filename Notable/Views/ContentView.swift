//
//  ContentView.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import SwiftUI
import CLIPKit
import SVDB
import NaturalLanguage

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var sharedData: SharedData
    
    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .none)
    private var piles: FetchedResults<Pile>
    
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>
    
    @EnvironmentObject var actionService: ActionService
    
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
    
    @State private var searchText = ""
    
    var filteredEntries: [Entry] {
        var resultEntries: [Entry] = []
        var results: [SearchResult] = []
        
        //        do {
        //            let embedded = try sharedData.clip.textEncoder?.encode(searchText)
        let embedding: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .english)
        let embedded = embedding?.vector(for: searchText) //returns double array
        
        if let wordEmbedding = embedded {
            //                let converted = wordEmbedding.scalars.map { Double($0) }
            results = sharedData.database!.search(query: wordEmbedding, num_results: 5)
        }
        //        } catch {
        //            print(error)
        //        }
        
        for result in results {
            for entry in entries {
                if entry.content == result.text {
                    resultEntries.append(entry)
                }
            }
        }
        return resultEntries
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            NavigationStack {
                List(selection: $selection) {
                    if searchText.isEmpty {
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
                    } else {
                        //                        if sharedData.textModelLoaded {
                        Section {
                            ForEach(filteredEntries, id: \.id) { entry in
                                EntryTransformer(entry: entry)
                            }
                        }
                        //                        } else {
                        //                            Text("Model is loading...")
                        //                        }
                    }
                }
                .toolbar {
                    //                if tabSelection == .tab1 {
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
#if os(iOS)
                .navigationBarTitle("Piles")
#endif
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, placement: .navigationBarDrawer)
            }
            .tabItem {
                Label("Piles", systemImage: "tray.2.fill")
            }
            .tag(Tabs.tab1)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(sharedData)
#if os(iOS)
                    .navigationBarTitle("Settings")
#endif
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.tab2)
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
            
            processDatabase(sharedData: sharedData, entries: Array(entries))
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
