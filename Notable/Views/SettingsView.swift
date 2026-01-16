//
//  SettingsView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/10/23.
//

import SwiftUI
import CoreData
import CodeEditor
import CloudKitSyncMonitor

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Entry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>

    @EnvironmentObject var sharedData: SharedData

    @available(iOS 14.0, *)
    @ObservedObject var syncMonitor = SyncMonitor.shared

    @ObservedObject var cloudKitState = CloudKitSyncState.shared

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

    @AppStorage("forceAppleSpeech")
    private var forceAppleSpeech = false

    @AppStorage("developerModeEnabled")
    private var developerModeEnabled = false

    @State private var isDemoMode = DemoDataManager.shared.isDemoDataActive
    @State private var showingDemoAlert = false
    @State private var tapCount = 0
    @State private var showingDeveloperToast = false

    var body: some View {
        Form {
            Section(header: Text(String(localized: "Markdown Editor settings"))) {
                Stepper(value: $markdownBaseFontSize, in: 1...64) {
                    Text(String(localized: "Font size: \(markdownBaseFontSize)"))
                }
                Toggle(String(localized: "Autocorrect"), isOn: $autocorrect)
            }

            Section(header: Text(String(localized: "Code Editor settings"))) {
                Stepper(value: $editorFontSize, in: 1...64) {
                    Text(String(localized: "Font size: \(editorFontSize)"))
                }
                Picker(String(localized: "Editor Theme"), selection: $theme) {
                    ForEach(CodeEditor.availableThemes) { theme in
                        Text("\(theme.rawValue.capitalized)")
                            .tag(theme)
                    }
                }
            }

            Section(header: Text(String(localized: "Audio Transcription"))) {
                // Transcription model status indicator
                HStack {
                    Text(String(localized: "Model Status:"))
                    Spacer()
                    transcriptionStatusView
                }

                // Show progress bar when downloading
                if case .downloading(let progress) = sharedData.transcriptionService.modelStatus {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(sharedData.transcriptionService.modelStatus.displayText)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: progress)
                    }
                    .foregroundColor(.blue)
                }

                Toggle(String(localized: "Force Apple Speech"), isOn: $forceAppleSpeech)

                Text(String(localized: "By default, Notable uses WhisperKit for accurate transcription with Apple Speech as fallback. Enable this to always use Apple Speech instead."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text(String(localized: "iCloud"))) {
                if #available(iOS 14.0, *) {
                    // Primary status indicator
                    HStack {
                        Text(String(localized: "Status:"))
                        Spacer()
                        syncStatusIcon
                    }

                    // Show last successful sync time if available
                    if let lastSync = cloudKitState.lastSuccessfulSync {
                        HStack {
                            Text(String(localized: "Last Sync:"))
                            Spacer()
                            Text(timeAgoString(from: lastSync))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Show account warning if needed
                    if case .accountNotAvailable = syncMonitor.syncStateSummary {
                        Text(String(localized: "Hey, log into your iCloud account if you want to sync"))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    // Debug info: show if there's a mismatch
                    if cloudKitState.lastSuccessfulSync != nil &&
                       syncMonitor.syncStateSummary.symbolName.contains("xmark") {
                        Text(String(localized: "Note: CloudKit monitor may show stale status. Check Last Sync time above for actual sync state."))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text(String(localized: "Search Database"))) {
                Button(action: {
                    sharedData.forceRebuild()
                    processDatabase(sharedData: sharedData, entries: Array(entries))
                }, label: {
                    HStack {
                        Text(String(localized: "Rebuild Search Index"))
                        if sharedData.isIndexing {
                            Spacer()
                            ProgressView()
                        }
                    }
                })
                .disabled(sharedData.isIndexing)

                // Show detailed progress when indexing
                if sharedData.isIndexing {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(localized: "Indexing entries..."))
                                .font(.caption)
                            Spacer()
                            Text("\(sharedData.indexedCount) / \(sharedData.totalToIndex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: sharedData.indexingProgress)
                    }
                    .foregroundColor(.blue)
                }

                Text(String(localized: "Rebuilds the semantic search index. Use this if search results seem incorrect."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if developerModeEnabled {
                Section(header: Text(String(localized: "Developer Options"))) {
                    Toggle(String(localized: "Developer Mode"), isOn: $developerModeEnabled)
                        .tint(.orange)

                    Text(String(localized: "Developer mode is enabled. Tap the Settings title 10 times to toggle."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if developerModeEnabled {
                Section(header: Text(String(localized: "Demo Mode"))) {
                if #available(iOS 17.0, *) {
                    Toggle(String(localized: "Enable Demo Mode"), isOn: $isDemoMode)
                        .onChange(of: isDemoMode) { oldValue, newValue in
                            if newValue {
                                DemoDataManager.shared.createDemoData(context: viewContext)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isDemoMode = DemoDataManager.shared.isDemoDataActive
                                }
                            } else {
                                showingDemoAlert = true
                            }
                        }
                } else {
                    Toggle(String(localized: "Enable Demo Mode"), isOn: $isDemoMode)
                        .onChange(of: isDemoMode) { newValue in
                            if newValue {
                                DemoDataManager.shared.createDemoData(context: viewContext)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isDemoMode = DemoDataManager.shared.isDemoDataActive
                                }
                            } else {
                                showingDemoAlert = true
                            }
                        }
                }

                Text(String(localized: "Populates the app with sample piles and entries for screenshots and demonstrations."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Section {
                NavigationLink(String(localized: "Acknowledgement")) {
                    AcknowledgeView()
#if os(iOS)
                        .navigationTitle(String(localized: "Acknowledgement"))
                        .navigationBarTitleDisplayMode(.inline)
#endif
                }
            } header: {
                // Hidden tap gesture - tap "Miscellaneous" 10 times to enable developer mode
                Text("Miscellaneous")
                    .onTapGesture {
                        tapCount += 1

                        if tapCount >= 10 {
                            developerModeEnabled.toggle()
                            showingDeveloperToast = true
                            tapCount = 0

                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(developerModeEnabled ? .success : .warning)

                            // Hide toast after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingDeveloperToast = false
                            }
                        }
                    }
            }
        }
        .alert(String(localized: "Remove Demo Data?"), isPresented: $showingDemoAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {
                isDemoMode = true
            }
            Button(String(localized: "Remove"), role: .destructive) {
                DemoDataManager.shared.removeDemoData(context: viewContext)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isDemoMode = DemoDataManager.shared.isDemoDataActive
                }
            }
        } message: {
            Text(String(localized: "This will delete all piles and entries. This action cannot be undone."))
        }
        .overlay(
            Group {
                if showingDeveloperToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: developerModeEnabled ? "hammer.fill" : "lock.fill")
                            Text(developerModeEnabled ? "Developer Mode Enabled" : "Developer Mode Disabled")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule()
                                .fill(developerModeEnabled ? Color.orange : Color.gray)
                        )
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingDeveloperToast)
                }
            }
        )
    }

    @ViewBuilder
    private var transcriptionStatusView: some View {
        let status = sharedData.transcriptionService.modelStatus

        HStack(spacing: 6) {
            if case .downloading = status {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: status.statusIcon)
                    .foregroundColor(colorFromString(status.statusColor))
            }

            if case .downloading = status {
                // Don't show text here, it's shown in the progress section below
                EmptyView()
            } else {
                Text(status.displayText)
                    .foregroundColor(colorFromString(status.statusColor))
            }
        }
    }

    @ViewBuilder
    private var syncStatusIcon: some View {
        // Show success if we have a recent successful sync (within 5 seconds)
        if let lastSync = cloudKitState.lastSuccessfulSync,
           Date().timeIntervalSince(lastSync) < 5 {
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green)
        } else if cloudKitState.isCurrentlySyncing {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.8)
                Image(systemName: "arrow.triangle.2.circlepath.icloud")
            }
            .foregroundColor(.blue)
        } else {
            // Fall back to CloudKitSyncMonitor status
            Image(systemName: syncMonitor.syncStateSummary.symbolName)
                .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "gray": return .gray
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        default: return .primary
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
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
