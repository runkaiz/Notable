//
//  SettingsView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/10/23.
//

import SwiftUI
import CoreData
import CodeEditor

struct SettingsView: View {
    @AppStorage("autocorrect")
    private var autocorrect = true
    
    @AppStorage("editorFontSize")
    private var editorFontSize = 18
    
    @AppStorage("editorLanguage")
    private var language = CodeEditor.Language.markdown
    
    @AppStorage("editorTheme")
    private var theme = CodeEditor.ThemeName.xcode
    
    var body: some View {
        Form {
            Section(header: Text("Editor settings")) {
//                Toggle("Autocorrect in rich text mode", isOn: $autocorrect)
                Stepper(value: $editorFontSize, in: 1...64) {
                    Text("Font size: \(editorFontSize)")
                }
                Picker("Theme", selection: $theme) {
                    ForEach(CodeEditor.availableThemes) { theme in
                        Text("\(theme.rawValue.capitalized)")
                            .tag(theme)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

public extension CodeEditor.ThemeName {
    static var foundation = CodeEditor.ThemeName(rawValue: "foundation")
    static var xcode = CodeEditor.ThemeName(rawValue: "xcode")
}
