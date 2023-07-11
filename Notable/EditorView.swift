//
//  EditorView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/2/23.
//

import SwiftUI
import CodeEditor
import CoreData
import CoreTransferable

struct Note: Codable, Transferable {
    var title: String
    var body: String
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.body).suggestedFileName("Ok wtf.txt")
    }
}

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var entry: Entry
    
    @State private var presentAlert = false
    @State private var newTitle = ""
    @State private var note: Note
    
    @FocusState var isInputActive: Bool
    
#if os(macOS)
    @AppStorage("fontsize") var fontSize = Int(NSFont.systemFontSize)
#else
    @AppStorage("editorFontSize")
    private var editorFontSize = 18
//    @State private var fontSize = CGFloat(18)
#endif
    
    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown
    
    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode
    
    init(entry: Entry) {
        self.entry = entry
        self.note = Note(title: entry.title!, body: entry.content!)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
#if os(macOS)
            CodeEditor(source: $entry.content ?? "", language: language, theme: theme, fontSize: .init(get: { CGFloat(fontSize) }, set: { fontSize = Int($0) }))
                .frame(minWidth: 640, minHeight: 480)
#else
            CodeEditor(source: $entry.content ?? "", language: language, theme: theme, fontSize:.init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) }))
#endif
        }
        .onChange(of: entry.content, perform: { _ in
            saveEntry()
        })
        .focused($isInputActive)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(entry.title ?? "Error") {
                    newTitle = entry.title ?? ""
                    presentAlert = true
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
                ShareLink(item: note, preview: SharePreview("\(note.title)"))
            }
        }
    }
    
    private func inactiveInput() {
        isInputActive = false
    }
    
    private func saveEntry() {
        if !newTitle.isEmpty { entry.title = newTitle }
        
        note = Note(title: entry.title!, body: entry.content!)
        
        withAnimation {
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

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
