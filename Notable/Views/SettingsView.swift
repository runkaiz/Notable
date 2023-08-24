//
//  SettingsView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/10/23.
//

import SwiftUI
import CoreData
import CodeEditor
import NaturalLanguage
import SVDB
import CloudKitSyncMonitor

struct SettingsView: View {
    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>
    
    @available(iOS 14.0, *)
    @ObservedObject var syncMonitor = SyncMonitor.shared
    
    @AppStorage("autocorrect")
    private var autocorrect = true

    @AppStorage("editorFontSize")
    private var editorFontSize = 18
    
    @AppStorage("markdownBaseFontSize")
    private var markdownBaseFontSize = 18

    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown

    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode

    var body: some View {
        Form {
            Section(header: Text("Markdown Editor settings")) {
                Stepper(value: $markdownBaseFontSize, in: 1...64) {
                    Text("Font size: \(markdownBaseFontSize)")
                }
                Toggle("Autocorrect", isOn: $autocorrect)
            }

            Section(header: Text("Code Editor settings")) {
                Stepper(value: $editorFontSize, in: 1...64) {
                    Text("Font size: \(editorFontSize)")
                }
                Picker("Editor Theme", selection: $theme) {
                    ForEach(CodeEditor.availableThemes) { theme in
                        Text("\(theme.rawValue.capitalized)")
                            .tag(theme)
                    }
                }
            }
            
            Section(header: Text("iCloud")) {
                if #available(iOS 14.0, *) {
                    HStack {
                        Text("Status:")
                        Spacer()
                        Image(systemName: syncMonitor.syncStateSummary.symbolName)
                            .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                    }
                    
                    if case .accountNotAvailable = syncMonitor.syncStateSummary {
                        Text("Hey, log into your iCloud account if you want to sync")
                    }
                }
            }
            
            Section(header: Text("Search Database")) {
                Button(action: {
                    do {
                        let database = try SVDB.shared.collection("entries")
                        
                        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
                            return
                        }
                        
                        database.clear()
                        
                        for entry in entries {
                            if entry.type == EntryType.text.rawValue {
                                if let text = entry.title {
                                    if let wordEmbedding = embedding.vector(for: text) {
                                        database.addDocument(text: text, embedding: wordEmbedding)
                                    }
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                }, label: {
                    Text("Reprocess Embed Database")
                })
            }

            Section(header: Text("Miscellaneous")) {
                NavigationLink("Acknowledgement") {
                    AcknowledgeView()
#if os(iOS)
                        .navigationTitle("Acknowledgement")
                        .navigationBarTitleDisplayMode(.inline)
#endif
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

public extension CodeEditor.ThemeName {
    static var foundation = CodeEditor.ThemeName(rawValue: "foundation")
    static var xcode = CodeEditor.ThemeName(rawValue: "xcode")
}
