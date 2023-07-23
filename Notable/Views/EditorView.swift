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
import RichTextKit

enum TemporaryFileError: Error {
    case creationFailed
}

struct Note: Transferable {
    var title: String
    var body: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .text) { note in
            var url: URL?
            
            do {
                // Call the function to create the temporary text file and get the URL
                url = try createTemporaryTxtFile(title: note.title, body: note.body)
                print("Temporary text file created at: \(String(describing: url))")
                
            } catch {
                print("Error creating temporary text file: \(error)")
            }
            
            return SentTransferredFile(url!)
        } importing: { received in
            return Self.init(title: "Imported", body: "Imported Nothing")
        }
    }
    
    private static func createTemporaryTxtFile(title: String, body: String) throws -> URL {
        // Get the app's temporary directory URL
        guard let temporaryDirectoryURL = FileManager.default.temporaryDirectory as URL? else {
            throw TemporaryFileError.creationFailed
        }
        
        let temporaryTxtURL = temporaryDirectoryURL.appendingPathComponent("\(title).txt")
        
        do {
            // Content to be written to the temporary file
            let fileContent = body
            
            // Write the content to the temporary file
            try fileContent.write(to: temporaryTxtURL, atomically: true, encoding: .utf8)
            
            // Return the URL of the created temporary text file
            return temporaryTxtURL
        } catch {
            throw error
        }
    }
}

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var entry: Entry
    
    @StateObject var context = RichTextContext()
    
    @State private var presentAlert = false
    @State private var newTitle = ""
    @State private var note: Note
    @State private var showingSheet = false
    @State private var text: NSAttributedString
    
    @FocusState var isInputActive: Bool
    
#if os(macOS)
    @AppStorage("fontsize") var fontSize = Int(NSFont.systemFontSize)
#else
    @AppStorage("editorFontSize")
    private var editorFontSize = 18
    //    @State private var fontSize = CGFloat(18)
#endif
    
    @AppStorage("autocorrect")
    private var autocorrect = true
    
    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown
    
    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode
    
    init(entry: Entry) {
        self.entry = entry
        self.note = Note(title: entry.title!, body: entry.content!)
        _text = State(initialValue: NSAttributedString(string: entry.content ?? ""))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if entry.isRichText {
                RichTextEditor(text: $text, context: context) {
                    $0.textContentInset = CGSize(width: 8, height: 22)
                    $0.setFontSize(to: CGFloat(editorFontSize))
                }
                .onChange(of: text) { _ in
                    saveEntry()
                }
                
                RichTextKeyboardToolbar(context: context) {
                    
                } trailingButtons: {
                }
                
            } else {
#if os(macOS)
                CodeEditor(source: $entry.content ?? "", language: language, theme: theme, fontSize: .init(get: { CGFloat(fontSize) }, set: { fontSize = Int($0) }))
                    .frame(minWidth: 640, minHeight: 480)
                    .onChange(of: entry.content, perform: { _ in
                        saveEntry()
                    })
                    .focused($isInputActive)
                    .keyboardType(UIKit.UIKeyboardType.alphabet)
#else
                CodeEditor(source: $entry.content ?? "", language: language, theme: theme, fontSize:.init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) }))
                    .padding(.top, CGFloat(12))
                    .onChange(of: entry.content, perform: { _ in
                        saveEntry()
                    })
                    .focused($isInputActive)
                    .keyboardType(UIKit.UIKeyboardType.alphabet)
#endif
            }
        }
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
            EditorConfigSheet(entry: entry)
        }
    }
    
    private func styleItalic() {
        
    }
    
    private func styleBold() {
        
    }
    
    private func saveEntry() {
        if !newTitle.isEmpty { entry.title = newTitle }
        
        if entry.isRichText {
            entry.content = text.string
            note = Note(title: entry.title!, body: entry.content!)
        } else {
            text = NSAttributedString(string: entry.content ?? "")
            note = Note(title: entry.title!, body: entry.content!)
        }
        
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
