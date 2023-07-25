//
//  EditorConfigSheet.swift
//  Notable
//
//  Created by Runkai Zhang on 7/14/23.
//

import SwiftUI
import CodeEditor

struct EditorConfigSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var entry: Entry
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var language: CodeEditor.Language
    
    @State private var selectedMode: String
    let modes = ["Rich Text", "Code"]
    
    init(entry: Entry) {
        self.entry = entry
        
        if entry.isRichText {
            _selectedMode = State(initialValue:"Rich Text")
        } else {
            _selectedMode = State(initialValue:"Code")
        }
        
        _language = State(initialValue: CodeEditor.Language(rawValue: entry.language ?? "lisp"))
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: dismissSheet, label: {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(width: 30)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .contentShape(Circle())
                })
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Text("Close"))
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            
            Form {
                Section("Editor Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedMode) { _ in
                        if selectedMode == "Rich Text" {
                            entry.isRichText = true
                        } else {
                            entry.isRichText = false
                        }
                        
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
                if !entry.isRichText {
                    Section("Code Editor Settings") {
                        Picker("Language", selection: $language) {
                            ForEach(CodeEditor.availableLanguages) { language in
                                Text("\(language.rawValue.capitalized)")
                                    .tag(language)
                            }
                        }
                        .onChange(of: language) { _ in
                            entry.language = language.rawValue
                            
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
            }
            .scrollContentBackground(.hidden)
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .fixedSize(horizontal: false, vertical: false)
        }
    }
    
    func dismissSheet() {
        dismiss()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
