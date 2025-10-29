//
//  ContentView.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import NaturalLanguage
import PhotosUI
import SVDB
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject var sharedData: SharedData

    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .none
    )
    private var piles: FetchedResults<Pile>

    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>

    @EnvironmentObject var actionService: ActionService

    @State private var showSettings = false
    @State private var presentAlert = false
    @State private var presentRenamer = false
    @State private var newPileName = ""

    @State private var selection: Entry?

    @State private var selectedColor: Color?

    @State private var showColorPicker = false

    private var colors: [Color] = [
        Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255),
        Color(red: 241 / 255, green: 113 / 255, blue: 5 / 255),
        Color(red: 160 / 255, green: 210 / 255, blue: 219 / 255)
    ]

    @State private var contextPile: Pile?

    @State private var emptyTagAnimateTrigger = false

    @State var shouldPushToOrphan = false

    @State private var searchText = ""

    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""

    // Quick entry creation states (for inbox)
    @State private var showPhotosPicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var showLinkPrompt = false
    @State private var newLink = ""
    @State private var showRecorder = false

    var filteredEntries: [Entry] {
        var resultEntries: [Entry] = []
        var results: [SearchResult] = []

        // Guard against nil database - return empty results gracefully
        guard let database = sharedData.database else {
            print("Warning: SVDB database not available for search")
            return resultEntries
        }

        let embedding: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .english)
        let embedded = embedding?.vector(for: searchText) // returns double array

        if let wordEmbedding = embedded {
            results = database.search(query: wordEmbedding, num_results: 5)
        }

        // Build a dictionary for O(1) lookup instead of O(n²) nested loop
        // Use a multimap approach since theoretically multiple entries could have identical content
        var contentToEntries: [String: Entry] = [:]
        for entry in entries {
            if let content = entry.content {
                contentToEntries[content] = entry
            }
        }

        // Match search results to entries via dictionary lookup
        for result in results {
            if let entry = contentToEntries[result.text] {
                resultEntries.append(entry)
            }
        }
        return resultEntries
    }

    var orphanEntries: [Entry] {
        entries.filter { $0.pile == nil }
    }

    var orphanCounts: (texts: Int, images: Int, links: Int, recordings: Int) {
        var texts = 0
        var images = 0
        var links = 0
        var recordings = 0

        for entry in orphanEntries {
            guard let typeString = entry.type,
                  let type = EntryType(rawValue: typeString) else {
                continue
            }
            switch type {
            case .image:
                images += 1
            case .text:
                texts += 1
            case .link:
                links += 1
            case .recording:
                recordings += 1
            }
        }

        return (texts, images, links, recordings)
    }

    var body: some View {
        NavigationStack {
                List(selection: $selection) {
                    if searchText.isEmpty {
                        Section {
                            NavigationLink {
                                OrphanEntriesView(didGetPushedHere: $shouldPushToOrphan)
                            } label: {
                                let counts = orphanCounts
                                VStack {
                                    HStack {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                            .accessibilityLabel("Inbox")
                                        Text("Inbox")
                                        Spacer()
                                    }
                                    HStack {
                                        HStack(spacing: 4) {
                                            Image(systemName: "text.word.spacing")
                                            Text(counts.texts.description)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(counts.texts) text entries")
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "photo")
                                            Text(counts.images.description)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(counts.images) image entries")
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "waveform")
                                            Text(counts.recordings.description)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(counts.recordings) voice memo entries")
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "link")
                                            Text(counts.links.description)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(counts.links) link entries")
                                    }
                                }
                            }
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
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    contextPile = pile
                                    showColorPicker.toggle()
                                } label: {
                                    Label("Color", systemImage: "swatchpalette")
                                }
                                .tint(.brown)
                                Button {
                                    contextPile = pile
                                    newPileName = pile.name ?? ""
                                    presentRenamer.toggle()
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            })
                            .contextMenu {
                                Button {
                                    contextPile = pile
                                    newPileName = pile.name ?? ""
                                    presentRenamer.toggle()
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    contextPile = pile
                                    showColorPicker.toggle()
                                } label: {
                                    Label("Change Color", systemImage: "swatchpalette")
                                }
                                Button(role: .destructive) {
                                    contextPile = pile
                                    deletePile()
                                } label: {
                                    Label("Delete Pile", systemImage: "trash")
                                }
                            }
                        }
#if os(iOS)
                        .onDelete(perform: deletePiles)
#endif
                    } else {
                        Section {
                            ForEach(filteredEntries, id: \.id) { entry in
                                EntryTransformer(entry: entry)
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
#if os(iOS)
                    if !piles.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }

                    if #available(iOS 26.0, *) {
                        // iOS 26+: Bottom bar with search and add button side by side
                        DefaultToolbarItem(kind: .search, placement: .bottomBar)

                        ToolbarSpacer(placement: .bottomBar)

                        ToolbarItem(placement: .bottomBar) {
                            Menu {
                                Button(action: toggleAlert) {
                                    Label("New Pile", systemImage: "folder.badge.plus")
                                }

                                Divider()

                                // Quick entry creation (goes to inbox)
                                Button {
                                    addEntry(viewContext, pile: nil)
                                } label: {
                                    Label("New Text Entry", systemImage: "doc.badge.plus")
                                }

                                Menu {
                                    Button {
                                        selectedImage = nil
                                        showPhotosPicker.toggle()
                                    } label: {
                                        Label("Photos Library", systemImage: "photo.on.rectangle")
                                    }
                                } label: {
                                    Label("New Image Entry", systemImage: "photo.badge.plus")
                                }

                                Button {
                                    showRecorder.toggle()
                                } label: {
                                    Label("New Voice Memo", systemImage: "waveform.badge.mic")
                                }

                                Button {
                                    showLinkPrompt.toggle()
                                } label: {
                                    Label("New Link Entry", systemImage: "link.badge.plus")
                                }
                            } label: {
                                Label("New", systemImage: "plus")
                            }
                        }
                    } else {
                        // iOS 17-25: Traditional top toolbar add button
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: toggleAlert) {
                                    Label("New Pile", systemImage: "folder.badge.plus")
                                }

                                Divider()

                                // Quick entry creation (goes to inbox)
                                Button {
                                    addEntry(viewContext, pile: nil)
                                } label: {
                                    Label("New Text Entry", systemImage: "doc.badge.plus")
                                }

                                Menu {
                                    Button {
                                        selectedImage = nil
                                        showPhotosPicker.toggle()
                                    } label: {
                                        Label("Photos Library", systemImage: "photo.on.rectangle")
                                    }
                                } label: {
                                    Label("New Image Entry", systemImage: "photo.badge.plus")
                                }

                                Button {
                                    showRecorder.toggle()
                                } label: {
                                    Label("New Voice Memo", systemImage: "waveform.badge.mic")
                                }

                                Button {
                                    showLinkPrompt.toggle()
                                } label: {
                                    Label("New Link Entry", systemImage: "link.badge.plus")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
#endif
                }
#if os(iOS)
                .navigationBarTitle("Piles")
#endif
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText)
                .navigationDestination(isPresented: $shouldPushToOrphan) {
                    OrphanEntriesView(didGetPushedHere: $shouldPushToOrphan)
                }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(sharedData)
#if os(iOS)
                    .navigationBarTitle("Settings")
#endif
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSettings = false
                            }
                        }
                    }
            }
        }
        .alert("Rename Pile", isPresented: $presentRenamer, actions: {
            TextField("Pile Name", text: $newPileName)

            Button("Rename", action: {
                guard let pile = contextPile else { return }
                pile.name = newPileName
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
        .sheet(isPresented: $showColorPicker) {} content: {
            let size = CGFloat(44)

            HStack(spacing: 25) {
                Button {
                    guard let pile = contextPile else { return }
                    selectedColor = colors[0]
                    pile.tag = "Raisin Black"
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
                .accessibilityLabel("Black tag")
                .accessibilityHint(selectedColor == colors[0] ? "Currently selected" : "Tap to apply black tag")
                Button {
                    guard let pile = contextPile else { return }
                    selectedColor = colors[1]
                    pile.tag = "Safety Orange"
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
                .accessibilityLabel("Orange tag")
                .accessibilityHint(selectedColor == colors[1] ? "Currently selected" : "Tap to apply orange tag")
                Button {
                    guard let pile = contextPile else { return }
                    selectedColor = colors[2]
                    pile.tag = "Non Photo Blue"
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
                .accessibilityLabel("Blue tag")
                .accessibilityHint(selectedColor == colors[2] ? "Currently selected" : "Tap to apply blue tag")
                Button {
                    guard let pile = contextPile else { return }
                    emptyTagAnimateTrigger.toggle()
                    selectedColor = nil
                    pile.tag = nil
                    save(viewContext)
                } label: {
                    Image(systemName: "circle.dotted")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                }
                .accessibilityLabel("No tag")
                .accessibilityHint(selectedColor == nil ? "Currently selected" : "Tap to remove tag")
                .symbolEffect(.bounce, value: emptyTagAnimateTrigger)
            }
            .presentationDetents([.fraction(0.15)])
            .onAppear {
                guard let pile = contextPile else { return }
                switch pile.tag {
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
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedImage,
            matching: .any(of: [.images, .screenshots]),
            preferredItemEncoding: .automatic
        )
        .onChange(of: selectedImage) {
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                    addPicture(viewContext, image: data, pile: nil)
                    return
                }
                print("Failed to load image")
            }
        }
        .alert("New Link", isPresented: $showLinkPrompt) {
            TextField("Website URL", text: $newLink)
                .keyboardType(.URL)

            Button("Add") {
                addLink(viewContext, newLink: newLink, pile: nil)
                newLink = ""
            }
            Button("Cancel", role: .cancel) {
                newLink = ""
            }
        }
        .sheet(isPresented: $showRecorder) {
            AudioRecorderView { audioURL in
                addRecording(viewContext, audioURL: audioURL, pile: nil, transcriptionService: sharedData.transcriptionService)
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                performActionIfNeeded()

                // Recover any entries stuck in transcribing state
                recoverStuckTranscribingEntries(viewContext)

                // Rebuild database if version changed or if needed
                if sharedData.needsDatabaseRebuild {
                    print("Rebuilding SVDB after version update...")
                    processDatabase(sharedData: sharedData, entries: Array(entries))
                    sharedData.needsDatabaseRebuild = false
                }
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CoreDataSaveError"))) { notification in
            if let error = notification.userInfo?["error"] as? NSError {
                saveErrorMessage = error.localizedDescription
                showSaveErrorAlert = true
            }
        }
        .alert("Save Error", isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to save changes: \(saveErrorMessage)")
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

    func toggleAlert() {
        presentAlert.toggle()
    }

    private func newEntry() {
        shouldPushToOrphan.toggle()
    }

    private func deletePile() {
        guard let pile = contextPile,
              let index = piles.firstIndex(of: pile) else {
            return
        }

        withAnimation {
            viewContext.delete(piles[index])
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
