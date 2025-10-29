//
//  EntryListView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/25/23.
//

import SwiftUI
import CoreData
import PhotosUI
import NaturalLanguage
import SVDB
import UniformTypeIdentifiers

struct EntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var sharedData: SharedData

    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>

    @FetchRequest(
        entity: Pile.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Pile.name, ascending: true)],
        animation: .default
    )
    private var piles: FetchedResults<Pile>

    @State var pile: Pile

    @State private var selection: Entry?

    @State private var showPhotosPicker = false
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var selectedImage: PhotosPickerItem?

    @State private var presentRenamer = false
    @State private var newPileName = ""

    @State private var contextEntry: Entry?

    @State private var presentEntryRenamer = false
    @State private var newEntryName = ""

    @State private var showLinkPrompt = false
    @State private var newLink = ""

    @State private var isImporting = false

    @State private var showRecorder = false

    @State private var showPileChooser = false
    @State private var selectedPile: Pile?

    var pileEntries: [Entry] {
        entries.filter { $0.pile == pile }
    }

    var filteredPileEntries: [Entry] {
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
            for entry in pileEntries {
                if entry.content == result.text {
                    resultEntries.append(entry)
                }
            }
        }
        return resultEntries
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                VStack {
                    HStack {
                        Image(systemName: "info.square")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Description")
                        Spacer()
                    }
                    .dismissKeyboardOnTap()
                    .padding(.top, 12)
                    .padding(.horizontal)
                    Divider()
                    TextField("Description", text: $pile.desc ?? "", axis: .vertical)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .font(.body)
                        .foregroundStyle(Color.gray)
                }.listRowInsets(EdgeInsets())
            }
            .onAppear {
                if pile.desc == nil {
                    pile.desc = ""
                }

                save(viewContext)
            }
            .onChange(of: pile.desc) {
                save(viewContext)
            }

            if pileEntries.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "Pile is Empty",
                    description: "This pile doesn't have any entries yet. Add notes, images, or links to organize your content here.",
                    actionTitle: "Add Entry",
                    action: {
                        addEntry(viewContext, pile: pile)
                    }
                )
                .listRowSeparator(.hidden)
            }

            let displayEntries = searchText.isEmpty ? pileEntries : filteredPileEntries

            // Show empty state for search with no results
            if !searchText.isEmpty && displayEntries.isEmpty && !pileEntries.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results Found",
                    description: "No entries match your search query. Try different keywords or clear the search.",
                    actionTitle: nil,
                    action: {}
                )
                .listRowSeparator(.hidden)
            }

            ForEach(displayEntries, id: \.id) { entry in
                EntryTransformer(entry: entry)
                    .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                        Button {
                            contextEntry = entry
                            // Set default selection to inbox (nil) if available, otherwise first pile
                            selectedPile = nil
                            showPileChooser.toggle()
                        } label: {
                            Label("Move", systemImage: "arrow.left.arrow.right")
                        }
                        .tint(.accentColor)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                        Button(role: .destructive) {
                            viewContext.delete(entry)
                            save(viewContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        if entry.type == EntryType.text.rawValue {
                            Button {
                                contextEntry = entry
                                newEntryName = entry.title ?? ""
                                presentEntryRenamer.toggle()
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }

                        // Share button for all entry types
                        if entry.type == EntryType.text.rawValue {
                            ShareLink(item: entry.content ?? "", subject: Text(entry.title ?? "Entry")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.image.rawValue, let imageData = entry.image, let uiImage = UIImage(data: imageData) {
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(entry.title ?? "Image", image: Image(uiImage: uiImage))) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.link.rawValue, let url = entry.link {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.recording.rawValue, let audioData = entry.audio {
                            ShareLink(item: audioData, preview: SharePreview(entry.title ?? "Recording")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    })
                    .contextMenu {
                        // Share button for all entry types
                        if entry.type == EntryType.text.rawValue {
                            ShareLink(item: entry.content ?? "", subject: Text(entry.title ?? "Entry")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.image.rawValue, let imageData = entry.image, let uiImage = UIImage(data: imageData) {
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(entry.title ?? "Image", image: Image(uiImage: uiImage))) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.link.rawValue, let url = entry.link {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else if entry.type == EntryType.recording.rawValue, let audioData = entry.audio {
                            ShareLink(item: audioData, preview: SharePreview(entry.title ?? "Recording")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }

                        Button {
                            contextEntry = entry
                            selectedPile = nil
                            showPileChooser.toggle()
                        } label: {
                            Label("Move to pile", systemImage: "arrow.left.arrow.right")
                        }

                        if entry.type == EntryType.text.rawValue {
                            Button {
                                contextEntry = entry
                                newEntryName = entry.title ?? ""
                                presentEntryRenamer.toggle()
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                        }

                        Button(role: .destructive) {
                            viewContext.delete(entry)
                            save(viewContext)
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
            }
#if os(iOS)
            .onDelete(perform: deleteEntries)
#endif
        }
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(pile.name ?? "Error") {
                    newPileName = pile.name ?? ""
                    presentRenamer.toggle()
                }
                .bold()
                .foregroundColor(.primary)
            }
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !pileEntries.isEmpty {
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
                            addEntry(viewContext, pile: pile)
                        } label: {
                            Label("New Text Entry", systemImage: "doc.badge.plus")
                        }

                        // Submenu for image sources
                        Menu {
                            Button {
                                selectedImage = nil
                                showPhotosPicker.toggle()
                            } label: {
                                Label("Photos Library", systemImage: "photo.on.rectangle")
                            }

                            // TODO: Add camera option when implemented
                            // Button {
                            //     // Camera implementation
                            // } label: {
                            //     Label("Camera", systemImage: "camera")
                            // }
                        } label: {
                            Label("New Image Entry", systemImage: "photo.badge.plus")
                        }

                        Button(action: toggleRecorder) {
                            Label("New Voice Memo", systemImage: "waveform.badge.mic")
                        }
                        Button(action: togglePrompt) {
                            Label("New Link Entry", systemImage: "link.badge.plus")
                        }
                        Button(action: toggleImporter) {
                            Label("Import File", systemImage: "arrow.down.doc")
                        }
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            } else {
                // iOS 17-25: Traditional top toolbar add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            addEntry(viewContext, pile: pile)
                        } label: {
                            Label("New Text Entry", systemImage: "doc.badge.plus")
                        }

                        // Submenu for image sources
                        Menu {
                            Button {
                                selectedImage = nil
                                showPhotosPicker.toggle()
                            } label: {
                                Label("Photos Library", systemImage: "photo.on.rectangle")
                            }

                            // TODO: Add camera option when implemented
                            // Button {
                            //     // Camera implementation
                            // } label: {
                            //     Label("Camera", systemImage: "camera")
                            // }
                        } label: {
                            Label("New Image Entry", systemImage: "photo.badge.plus")
                        }

                        Button(action: toggleRecorder) {
                            Label("New Voice Memo", systemImage: "waveform.badge.mic")
                        }
                        Button(action: togglePrompt) {
                            Label("New Link Entry", systemImage: "link.badge.plus")
                        }
                        Button(action: toggleImporter) {
                            Label("Import File", systemImage: "arrow.down.doc")
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
                    addPicture(viewContext, image: data, pile: pile)

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
                pile.name = newPileName
                save(viewContext)
                newPileName = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
        .alert("Rename Entry", isPresented: $presentEntryRenamer, actions: {
            TextField("Entry Title", text: $newEntryName)

            Button("Rename", action: {
                guard let entry = contextEntry else { return }
                entry.title = newEntryName
                save(viewContext)
                newEntryName = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
        .alert("New Link", isPresented: $showLinkPrompt, actions: {
            TextField("Website URL", text: $newLink)
                .keyboardType(.URL)

            Button("Add", action: {
                addLink(viewContext, newLink: newLink, pile: pile)
                newLink = ""
            })
            Button("Cancel", role: .cancel, action: {})
        })
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.text, .image, .audio]) { result in
            switch result {
            case .success(let fileURL):
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
                            addPicture(viewContext, image: imageData, pile: pile)
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

                                pile.addToEntries(newEntry)

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

                                pile.addToEntries(newEntry)

                                save(viewContext)
                            }
                        }
                    }
                } catch let error as NSError {
                    print("❌ Failed to import file: \(error.localizedDescription)")
                }
                // release access
                fileURL.stopAccessingSecurityScopedResource()
            case .failure(let error):
                // handle error
                print("❌ File import failed: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showRecorder) {
            AudioRecorderView { audioURL in
                addRecording(viewContext, audioURL: audioURL, pile: pile, transcriptionService: sharedData.transcriptionService)
            }
        }
        .sheet(isPresented: $showPileChooser) {} content: {
            VStack {
                Text("Move to pile")
                    .font(.headline)
                    .padding(.top)

                Picker("Select pile", selection: $selectedPile) {
                    Text("Inbox")
                        .tag(nil as Pile?)

                    ForEach(piles, id: \.id) { targetPile in
                        if targetPile.id != pile.id {
                            Text(targetPile.name ?? "")
                                .tag(Optional(targetPile))
                        }
                    }
                }
                .pickerStyle(.wheel)

                HStack {
                    Spacer()
                    Button("Move", action: {
                        moveToPile()
                        showPileChooser.toggle()
                    })
                    .padding()
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    private func moveToPile() {
        guard let entry = contextEntry else { return }
        entry.pile = selectedPile
        save(viewContext)
    }

    private func togglePrompt() {
        showLinkPrompt.toggle()
    }

    private func toggleImporter() {
        isImporting.toggle()
    }

    private func toggleRecorder() {
        showRecorder.toggle()
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)

            save(viewContext)
        }
    }
}

public extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

public struct DismissKeyboardOnTap: ViewModifier {
    public func body(content: Content) -> some View {
#if os(macOS)
        return content
#else
        return content.gesture(tapGesture)
#endif
    }

    private var tapGesture: some Gesture {
        TapGesture().onEnded(endEditing)
    }

    private func endEditing() {
        UIApplication.shared.connectedScenes
            .filter {$0.activationState == .foregroundActive}
            .map {$0 as? UIWindowScene}
            .compactMap({$0})
            .first?.windows
            .filter {$0.isKeyWindow}
            .first?.endEditing(true)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
