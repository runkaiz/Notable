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

    @AppStorage("editorFontSize")
    private var editorFontSize = 18

    @AppStorage("markdownBaseFontSize")
    private var markdownBaseFontSize = 18

    @AppStorage("autocorrect")
    private var autocorrect = true

    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode

    init(entry: Entry) {
        self.entry = entry

        if entry.isMarkdown {
            _selectedMode = State(initialValue: "Markdown")
        } else {
            _selectedMode = State(initialValue: "Code")
        }

        // Default to markdown for consistency with new entry creation (see Operations.swift)
        _language = State(initialValue: CodeEditor.Language(rawValue: entry.language ?? "markdown"))
    }

    var body: some View {
        VStack(spacing: 0) {
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
                Section {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }
                .onChange(of: selectedMode) {
                    if selectedMode == "Markdown" {
                        entry.isMarkdown = true
                    } else {
                        entry.isMarkdown = false
                    }

                    save(viewContext)
                }

                if entry.isMarkdown {
                    Section(header: Text("Markdown Settings")) {
                        Stepper(value: $markdownBaseFontSize, in: 8...48) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(markdownBaseFontSize)")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Toggle("Autocorrect", isOn: $autocorrect)
                    }
                } else {
                    Section(header: Text("Code Settings")) {
                        Stepper(value: $editorFontSize, in: 8...48) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(editorFontSize)")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Picker("Language", selection: $language) {
                            ForEach(CodeEditor.availableLanguages) { language in
                                Text("\(language.rawValue.capitalized)")
                                    .tag(language)
                            }
                        }
                        .onChange(of: language) {
                            entry.language = language.rawValue
                            save(viewContext)
                        }

                        Picker("Theme", selection: $theme) {
                            ForEach(CodeEditor.availableThemes) { theme in
                                Text("\(theme.rawValue.capitalized)")
                                    .tag(theme)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Created")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(entry.timestamp ?? Date(), style: .date)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Image(systemName: "character.cursor.ibeam")
                                .foregroundColor(.secondary)
                            Text("Word Count")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(wordCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var wordCount: Int {
        let content = entry.content ?? ""
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    func dismissSheet() {
        dismiss()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
