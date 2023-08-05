//
//  EditorView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/2/23.
//

import SwiftUI
import CodeEditor
import CoreData

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var entry: Entry

    @State private var presentAlert = false
    @State private var newTitle = ""
    @State private var note: Note
    @State private var showingSheet = false

    @FocusState var isInputActive: Bool

#if os(macOS)
    @AppStorage("fontsize") var fontSize = Int(NSFont.systemFontSize)
#else
    @AppStorage("editorFontSize")
    private var editorFontSize = 18
#endif

    @AppStorage("autocorrect")
    private var autocorrect = true

    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown

    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode

    private var mdTheme = Theme(themePath: Bundle.main.path(forResource: "light", ofType: "json")!)

    init(entry: Entry) {
        self.entry = entry
        self.note = Note(title: entry.title ?? "", body: entry.content ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if entry.isMarkdown {
                SwiftDownEditor(text: $entry.content ?? "")
                    .theme(mdTheme)
                    .insetsSize(12)
                    .keyboardType(.alphabet)
                    .autocorrectionType(autocorrect ? UITextAutocorrectionType.yes : UITextAutocorrectionType.no)
            } else {
#if os(macOS)
                CodeEditor(
                    source: $entry.content ?? "",
                    language: language, theme: theme,
                    fontSize: .init(get: { CGFloat(fontSize) }, set: { fontSize = Int($0) }))
                .frame(minWidth: 640, minHeight: 480)
                .focused($isInputActive)
                .keyboardType(UIKit.UIKeyboardType.alphabet)
#else
                CodeEditor(
                    source: $entry.content ?? "",
                    language: language, theme: theme,
                    fontSize: .init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) }))
                .padding(.top, CGFloat(12))
                .focused($isInputActive)
                .keyboardType(UIKit.UIKeyboardType.alphabet)
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
                .foregroundColor(.black)
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
                    ShareLink(item: note, preview: SharePreview("\(note.title)"))
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

            note = Note(title: entry.title!, body: entry.content!)
            
            entry.type = "text"

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
