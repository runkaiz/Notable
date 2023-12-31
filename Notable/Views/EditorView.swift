//
//  EditorView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/2/23.
//

import SwiftUI
import CodeEditor
import CoreData
import HighlightedTextEditor

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var entry: Entry

    @State private var presentAlert = false
    @State private var newTitle = ""
    @State private var showingSheet = false

    @FocusState var isInputActive: Bool

    @AppStorage("editorFontSize")
    private var editorFontSize = 18
    
    @AppStorage("markdownBaseFontSize")
    private var markdownBaseFontSize = 18

    @AppStorage("autocorrect")
    private var autocorrect = true

    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown

    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode

    init(entry: Entry) {
        self.entry = entry
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if entry.isMarkdown {
#if os(macOS)
                HighlightedTextEditor(text: $entry.content ?? "", highlightRules: [HighlightRule(pattern: .all, formattingRule: TextFormattingRule(key: .font, value: NSFont.systemFont(ofSize: CGFloat(markdownBaseFontSize))))])
                    .introspect { editor in
                        editor.textView.autocorrectionType = autocorrect ? .yes : .no
                    }
#else
                HighlightedTextEditor(text: $entry.content ?? "", highlightRules: .markdown)
                    .introspect { editor in
                        editor.textView.autocorrectionType = autocorrect ? .yes : .no
                    }
#endif
            } else {
#if os(macOS)
                CodeEditor(
                    source: $entry.content ?? "",
                    language: language, theme: theme,
                    fontSize: .init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) }))
                .frame(minWidth: 640, minHeight: 480)
                .focused($isInputActive)
                .keyboardType(.alphabet)
#else
                CodeEditor(
                    source: $entry.content ?? "",
                    language: language, theme: theme,
                    fontSize: .init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) }))
                .padding(.top, CGFloat(12))
                .focused($isInputActive)
                .keyboardType(.alphabet)
#endif
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: entry.content) {
            saveEntry()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(entry.title ?? "Error") {
                    newTitle = entry.title ?? ""
                    presentAlert.toggle()
                }
                .bold()
                .foregroundColor(.primary)
                .alert("Rename Entry", isPresented: $presentAlert, actions: {
                    TextField("Entry Title", text: $newTitle)

                    Button("Rename", action: saveEntry)
                    Button("Cancel", role: .cancel, action: {})
                })
            }
            ToolbarItem {
                Menu {
                    Button("Settings") {
                        isInputActive = false
                        showingSheet.toggle()
                    }
                    ShareLink(item: Note(title: entry.title!, body: entry.content!), preview: SharePreview(entry.title!))
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            VStack {
                EditorConfigSheet(entry: entry)
                Spacer()
            }
            .presentationDetents([.fraction(0.275)])
            .scrollContentBackground(.hidden)
        }
    }

    private func saveEntry() {
        withAnimation {
            if !newTitle.isEmpty { entry.title = newTitle }
            
            entry.type = EntryType.text.rawValue

            save(viewContext)
        }
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
