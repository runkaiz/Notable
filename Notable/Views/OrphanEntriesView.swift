//
//  OrphanEntriesView.swift
//  Notable
//
//  Created by Runkai Zhang on 8/8/23.
//

import NaturalLanguage
import PhotosUI
import SVDB
import SwiftUI
import UniformTypeIdentifiers

struct OrphanEntriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var sharedData: SharedData

    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>

    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .default
    )
    private var piles: FetchedResults<Pile>

    @Binding var didGetPushedHere: Bool

    @State private var selection: Entry?

    @State private var presentEntryRenamer = false
    @State private var newEntryName = ""

    @State private var showLinkPrompt = false
    @State private var newLink = ""

    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?

    @State private var contextEntry: Entry?

    @State private var showPileChooser = false
    @State private var selectedPile: Pile?

    @State private var isImporting = false

    @State private var showRecorder = false

    var orphanEntries: [Entry] {
        entries.filter { $0.pile == nil }
    }

    var filteredOrphanEntries: [Entry] {
        var resultEntries: [Entry] = []
        var results: [SearchResult] = []

        // Guard against nil database - return empty results gracefully
        guard let database = sharedData.database else {
            print("Warning: SVDB database not available for search")
            return resultEntries
        }

        let embedding: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .english)
        let embedded = embedding?.vector(for: searchText)

        if let wordEmbedding = embedded {
            results = database.search(query: wordEmbedding, num_results: 5)
        }

        for result in results {
            for entry in orphanEntries {
                if entry.content == result.text {
                    resultEntries.append(entry)
                }
            }
        }
        return resultEntries
    }

    var orphanCounts: (texts: Int, images: Int, links: Int, recordings: Int) {
        var texts = 0
        var images = 0
        var links = 0
        var recordings = 0

        for entry in orphanEntries {
            guard let typeString = entry.type,
                  let type = EntryType(rawValue: typeString)
            else {
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
        List(selection: $selection) {
            Section {
                HStack {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(String(localized: "Summary"))
                    Spacer()
                }
                HStack(spacing: 20) {
                    HStack {
                        Image(systemName: "text.word.spacing")
                            .foregroundStyle(.secondary)
                        Text("\(orphanCounts.texts)")
                            .font(.body)
                    }
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                        Text("\(orphanCounts.images)")
                            .font(.body)
                    }
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundStyle(.secondary)
                        Text("\(orphanCounts.recordings)")
                            .font(.body)
                    }
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                        Text("\(orphanCounts.links)")
                            .font(.body)
                    }
                    Spacer()
                }
            }

            if orphanEntries.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: String(localized: "Inbox is Empty"),
                    description: String(localized: "Your inbox is clear! New entries without a pile will appear here. Tap the + button above to add your first entry."),
                    actionTitle: String(localized: "Add Entry"),
                    action: {
                        addEntry(viewContext, pile: nil)
                    }
                )
                .listRowSeparator(.hidden)
            }

            let displayEntries = searchText.isEmpty ? orphanEntries : filteredOrphanEntries

            ForEach(displayEntries, id: \.id) { entry in
                EntryTransformer(entry: entry)
                    .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                        Button {
                            contextEntry = entry
                            if let first = piles.first {
                                selectedPile = first
                            }

                            showPileChooser.toggle()
                        } label: {
                            Label(String(localized: "Assign"), systemImage: "move.3d")
                        }
                        .tint(.accentColor)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                        Button(role: .destructive) {
                            viewContext.delete(entry)
                            save(viewContext)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }

                        if entry.type == EntryType.text.rawValue {
                            Button {
                                contextEntry = entry
                                newEntryName = entry.title ?? ""
                                presentEntryRenamer.toggle()
                            } label: {
                                Label(String(localized: "Rename"), systemImage: "pencil")
                            }
                            .tint(.orange)
                        }

                        // Share button for all entry types
                        if entry.type == EntryType.text.rawValue {
                            ShareLink(item: entry.content ?? "", subject: Text(entry.title ?? String(localized: "Entry"))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.image.rawValue, let imageData = entry.image, let uiImage = UIImage(data: imageData) {
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(entry.title ?? String(localized: "Image"), image: Image(uiImage: uiImage))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.link.rawValue, let url = entry.link {
                            ShareLink(item: url) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.recording.rawValue, let audioData = entry.audio {
                            ShareLink(item: audioData, preview: SharePreview(entry.title ?? String(localized: "Recording"))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        }
                    })
                    .contextMenu {
                        // Share button for all entry types
                        if entry.type == EntryType.text.rawValue {
                            ShareLink(item: entry.content ?? "", subject: Text(entry.title ?? String(localized: "Entry"))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.image.rawValue, let imageData = entry.image, let uiImage = UIImage(data: imageData) {
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(entry.title ?? String(localized: "Image"), image: Image(uiImage: uiImage))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.link.rawValue, let url = entry.link {
                            ShareLink(item: url) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.recording.rawValue, let audioData = entry.audio {
                            ShareLink(item: audioData, preview: SharePreview(entry.title ?? String(localized: "Recording"))) {
                                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                            }
                        }

                        Button {
                            contextEntry = entry
                            if let first = piles.first {
                                selectedPile = first
                            }

                            showPileChooser.toggle()
                        } label: {
                            Label(String(localized: "Assign to pile"), systemImage: "move.3d")
                        }

                        if entry.type == EntryType.text.rawValue {
                            Button {
                                contextEntry = entry
                                newEntryName = entry.title ?? ""
                                presentEntryRenamer.toggle()
                            } label: {
                                Label(String(localized: "Rename"), systemImage: "pencil")
                            }
                        }

                        Button(role: .destructive) {
                            viewContext.delete(entry)

                            save(viewContext)
                        } label: {
                            Label(String(localized: "Delete Entry"), systemImage: "trash")
                        }
                    }
            }
#if os(iOS)
            .onDelete(perform: deleteEntries)
#endif
        }
        .listStyle(.grouped)
        .navigationTitle(String(localized: "Inbox"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .onAppear {
            if didGetPushedHere {
                addEntry(viewContext, pile: nil)
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !orphanEntries.isEmpty {
                    EditButton()
                }
            }

            if #available(iOS 26.0, *) {
                // iOS 26+: Bottom bar with search and add button side by side
                DefaultToolbarItem(kind: .search, placement: .bottomBar)

                ToolbarSpacer(placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Button {
                            addEntry(viewContext, pile: nil)
                        } label: {
                            Label(String(localized: "New Text Entry"), systemImage: "doc.badge.plus")
                        }

                        // Submenu for image sources
                        Menu {
                            Button {
                                selectedImage = nil
                                showPhotosPicker.toggle()
                            } label: {
                                Label(String(localized: "Photos Library"), systemImage: "photo.on.rectangle")
                            }

                            // TODO: Add camera option when implemented
                            // Button {
                            //     // Camera implementation
                            // } label: {
                            //     Label("Camera", systemImage: "camera")
                            // }
                        } label: {
                            Label(String(localized: "New Image Entry"), systemImage: "photo.badge.plus")
                        }

                        Button(action: toggleRecorder) {
                            Label(String(localized: "New Voice Memo"), systemImage: "waveform.badge.mic")
                        }
                        Button(action: togglePrompt) {
                            Label(String(localized: "New Link Entry"), systemImage: "link.badge.plus")
                        }
                        Button(action: toggleImporter) {
                            Label(String(localized: "Import File"), systemImage: "arrow.down.doc")
                        }
                    } label: {
                        Label(String(localized: "New"), systemImage: "plus")
                    }
                }
            } else {
                // iOS 17-25: Traditional top toolbar add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            addEntry(viewContext, pile: nil)
                        } label: {
                            Label(String(localized: "New Text Entry"), systemImage: "doc.badge.plus")
                        }

                        // Submenu for image sources
                        Menu {
                            Button {
                                selectedImage = nil
                                showPhotosPicker.toggle()
                            } label: {
                                Label(String(localized: "Photos Library"), systemImage: "photo.on.rectangle")
                            }

                            // TODO: Add camera option when implemented
                            // Button {
                            //     // Camera implementation
                            // } label: {
                            //     Label("Camera", systemImage: "camera")
                            // }
                        } label: {
                            Label(String(localized: "New Image Entry"), systemImage: "photo.badge.plus")
                        }

                        Button(action: toggleRecorder) {
                            Label(String(localized: "New Voice Memo"), systemImage: "waveform.badge.mic")
                        }
                        Button(action: togglePrompt) {
                            Label(String(localized: "New Link Entry"), systemImage: "link.badge.plus")
                        }
                        Button(action: toggleImporter) {
                            Label(String(localized: "Import File"), systemImage: "arrow.down.doc")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
#endif
        }
        .onChange(of: selectedImage) {
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                    addPicture(viewContext, image: data, pile: nil)

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
        .alert(String(localized: "Rename Entry"), isPresented: $presentEntryRenamer, actions: {
            TextField(String(localized: "Entry Title"), text: $newEntryName)

            Button(String(localized: "Rename"), action: {
                guard let entry = contextEntry else { return }
                entry.title = newEntryName
                save(viewContext)
                newEntryName = ""
            })
            Button(String(localized: "Cancel"), role: .cancel, action: {})
        })
        .alert(String(localized: "New Link"), isPresented: $showLinkPrompt, actions: {
            TextField(String(localized: "Website URL"), text: $newLink)
                .keyboardType(.URL)

            Button(String(localized: "Add"), action: {
                addLink(viewContext, newLink: newLink, pile: nil)
                newLink = ""
            })
            Button(String(localized: "Cancel"), role: .cancel, action: {})
        })
        .sheet(isPresented: $showPileChooser) {} content: {
            VStack {
                Picker(String(localized: "Select pile"), selection: $selectedPile) {
                    ForEach(piles, id: \.id) { pile in
                        Text(pile.name ?? "")
                            .tag(Optional(pile))
                    }
                }
                .pickerStyle(.wheel)

                HStack {
                    Spacer()
                    Button(String(localized: "Assign"), action: {
                        assignToPile()
                        showPileChooser.toggle()
                    })
                    .padding()
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.text, .image, .audio]) { result in
            switch result {
            case let .success(fileURL):
                // gain access to the directory
                let gotAccess = fileURL.startAccessingSecurityScopedResource()
                if !gotAccess { return }

                do {
                    // Get the UTType of the imported file
                    let resourceValues = try fileURL.resourceValues(forKeys: [.contentTypeKey])

                    if let contentType = resourceValues.contentType {
                        if contentType.conforms(to: .image) {
                            // Handle image import
                            let imageData = try Data(contentsOf: fileURL)
                            addPicture(viewContext, image: imageData, pile: nil)
                        } else if contentType.conforms(to: .audio) {
                            // Handle audio import
                            let audioData = try Data(contentsOf: fileURL)

                            withAnimation {
                                let newEntry = Entry(context: viewContext)
                                newEntry.timestamp = Date()
                                newEntry.id = UUID()
                                newEntry.type = EntryType.recording.rawValue
                                newEntry.audio = audioData
                                newEntry.title = fileURL.deletingPathExtension().lastPathComponent

                                save(viewContext)
                            }

                            // Optionally transcribe imported audio
                            let audioDuration = getAudioDuration(from: audioData)
                            let maxAutoTranscribeDuration: TimeInterval = 120 // 2 minutes

                            if audioDuration > 0 && audioDuration < maxAutoTranscribeDuration {
                                // Find the entry we just created
                                if let entry = entries.first(where: { $0.audio == audioData }) {
                                    Task {
                                        await retranscribeEntry(viewContext, entry: entry, transcriptionService: sharedData.transcriptionService)
                                    }
                                }
                            }
                        } else {
                            // Handle text import (existing logic)
                            let contents = try String(contentsOf: fileURL, encoding: .utf8)

                            withAnimation {
                                let newEntry = Entry(context: viewContext)
                                newEntry.timestamp = Date()
                                newEntry.id = UUID()
                                newEntry.title = fileURL.lastPathComponent
                                newEntry.content = contents
                                newEntry.isMarkdown = true
                                newEntry.language = "markdown"
                                newEntry.type = EntryType.text.rawValue

                                save(viewContext)
                            }
                        }
                    }
                } catch let error as NSError {
                    print("❌ Failed to import file: \(error.localizedDescription)")
                }
                // release access
                fileURL.stopAccessingSecurityScopedResource()
            case let .failure(error):
                // handle error
                print("❌ File import failed: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showRecorder) {
            AudioRecorderView { audioURL in
                addRecording(viewContext, audioURL: audioURL, pile: nil, transcriptionService: sharedData.transcriptionService)
            }
        }
    }

    private func assignToPile() {
        guard let entry = contextEntry else { return }
        entry.pile = selectedPile
        save(viewContext)
    }

    private func toggleImporter() {
        isImporting.toggle()
    }

    private func togglePrompt() {
        showLinkPrompt.toggle()
    }

    private func toggleRecorder() {
        showRecorder.toggle()
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            // Use orphanEntries (the displayed list) instead of entries (all entries)
            // to ensure we delete the correct items
            let displayEntries = searchText.isEmpty ? orphanEntries : filteredOrphanEntries
            offsets.map { displayEntries[$0] }.forEach(viewContext.delete)

            save(viewContext)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
