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
    let modes = ["Markdown", "Code"]
    
    init(entry: Entry) {
        self.entry = entry
        
        if entry.isMarkdown {
            _selectedMode = State(initialValue: "Markdown")
        } else {
            _selectedMode = State(initialValue: "Code")
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
            HStack {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(modes, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.segmented)
            }.padding(.horizontal)
                .onChange(of: selectedMode) {
                    if selectedMode == "Markdown" {
                        entry.isMarkdown = true
                    } else {
                        entry.isMarkdown = false
                    }
                    
                    save(viewContext)
                }
            if !entry.isMarkdown {
                HStack {
                    Text("Language")
                    Spacer()
                    Picker("Language", selection: $language) {
                        ForEach(CodeEditor.availableLanguages) { language in
                            Text("\(language.rawValue.capitalized)")
                                .tag(language)
                        }
                    }
                }
                .padding()
                .onChange(of: language) {
                    entry.language = language.rawValue
                    
                    save(viewContext)
                }
            }
        }
    }
    
    func dismissSheet() {
        dismiss()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
