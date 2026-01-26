//
//  EditorView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/2/23.
//

import CodeEditor
import CoreData
import SwiftUI
import MarkdownUI

// MARK: - EditorView

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var entry: Entry

    @State private var presentAlert = false
    @State private var newTitle = ""
    @State private var showingSheet = false
    @State private var isPreviewMode = false

    @FocusState var isInputActive: Bool

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
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if entry.isMarkdown {
                if isPreviewMode {
                    // Preview Mode: Render markdown with MarkdownUI
                    ScrollView {
                        Markdown(entry.content ?? "")
                            .markdownTextStyle {
                                FontSize(CGFloat(markdownBaseFontSize))
                            }
                            .markdownTheme(.customNotable(baseFontSize: CGFloat(markdownBaseFontSize)))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // Edit Mode: Plain text editor
                    TextEditor(text: $entry.content ?? "")
                        .font(.system(size: CGFloat(markdownBaseFontSize)))
                        .autocorrectionDisabled(!autocorrect)
                        .focused($isInputActive)
#if os(iOS)
                        .padding(.top, 8)
#endif
                }
            } else {
// Code editor for non-markdown entries
#if os(macOS)
                CodeEditor(
                    source: $entry.content ?? "",
                    language: CodeEditor.Language(rawValue: entry.language ?? "markdown"),
                    theme: theme,
                    fontSize: .init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) })
                )
                .frame(minWidth: 640, minHeight: 480)
                .focused($isInputActive)
                .keyboardType(.alphabet)
#else
                CodeEditor(
                    source: $entry.content ?? "",
                    language: CodeEditor.Language(rawValue: entry.language ?? "markdown"),
                    theme: theme,
                    fontSize: .init(get: { CGFloat(editorFontSize) }, set: { editorFontSize = Int($0) })
                )
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
                .alert(String(localized: "Rename Entry"), isPresented: $presentAlert, actions: {
                    TextField(String(localized: "Entry Title"), text: $newTitle)

                    Button(String(localized: "Rename"), action: saveEntry)
                    Button(String(localized: "Cancel"), role: .cancel, action: {})
                })
            }

            if entry.isMarkdown {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPreviewMode.toggle()
                        if isPreviewMode {
                            isInputActive = false
                        }
                    } label: {
                        Image(systemName: isPreviewMode ? "pencil" : "eye")
                    }
                }
            }

            ToolbarItem {
                Menu {
                    Button {
                        isInputActive = false
                        showingSheet.toggle()
                    } label: {
                        Label(String(localized: "Settings"), systemImage: "slider.horizontal.3")
                    }
                    if let title = entry.title, let content = entry.content {
                        ShareLink(item: Note(title: title, body: content), preview: SharePreview(title))
                    }
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            EditorConfigSheet(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

// MARK: - Custom Markdown Theme

extension Theme {
    static func customNotable(baseFontSize: CGFloat) -> Theme {
        Theme()
            .text {
                ForegroundColor(.primary)
                FontSize(baseFontSize)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(baseFontSize * 1.5)
                    }
                    .padding(.vertical, 8)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(baseFontSize * 1.3)
                    }
                    .padding(.vertical, 6)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(baseFontSize * 1.15)
                    }
                    .padding(.vertical, 4)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.medium)
                        FontSize(baseFontSize * 1.1)
                    }
                    .padding(.vertical, 2)
            }
            .heading5 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.medium)
                        FontSize(baseFontSize * 1.05)
                    }
            }
            .heading6 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.regular)
                        FontSize(baseFontSize)
                    }
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(baseFontSize * 0.9)
                BackgroundColor(.secondary.opacity(0.15))
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(baseFontSize * 0.9)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
    }
}
