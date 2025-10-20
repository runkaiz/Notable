# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Notable is a high-performance Markdown editor for iOS built with SwiftUI. It features pile-based organization (similar to stacks), semantic search using natural language embeddings, iCloud sync via CloudKit, and support for text/markdown, images, and links.

## Build Commands

### Building the App
```bash
# Build for simulator (Debug)
xcodebuild -scheme Notable -destination 'platform=iOS Simulator,name=iPhone 15' -configuration Debug build

# Build for simulator (Release)
xcodebuild -scheme Notable -destination 'platform=iOS Simulator,name=iPhone 15' -configuration Release build

# Build for device
xcodebuild -scheme Notable -destination 'generic/platform=iOS' -configuration Release build
```

### Opening in Xcode
```bash
open Notable.xcodeproj
```

### Clean Build
```bash
xcodebuild -scheme Notable clean
```

## Testing

Note: This project currently has no test targets. Tests should be added in the future.

## Core Architecture

### Entry Point & App Structure
- **NotableApp.swift** - Main app entry point using `@main` and `WindowGroup`
- **AppDelegate.swift** - Handles app shortcuts and lifecycle events
- Environment setup injects `managedObjectContext`, `ActionService`, and `SharedData`

### Data Layer (CoreData + CloudKit)
- **Persistence.swift** - Configures `NSPersistentCloudKitContainer` with automatic iCloud sync
  - Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy` (local changes win)
  - Automatic merge from parent enabled
  - Remote notifications enabled for sync updates
- **Notable.xcdatamodeld/** - CoreData model with two main entities:
  - `Pile` - Container for entries (id, name, desc, tag color)
  - `Entry` - Content items (id, title, content, timestamp, type, isMarkdown, language, image, link)
  - Relationship: Pile ↔ Entry (one-to-many, deletion rule: nullify)

### State Management
- **SharedData.swift** - Global `ObservableObject` managing:
  - SVDB vector search index (`database: Collection?`)
  - ML/embeddings state (CLIPKit currently commented out)
- **Operations.swift** - Core business logic:
  - `addEntry()`, `addPicture()`, `addLink()` - CRUD operations
  - `processDatabase()` - Populates SVDB index with sentence embeddings
  - `cleanText()` - Preprocesses text for embedding (removes markdown)

### View Hierarchy
```
NotableApp
├── ContentView (TabView: Piles | Settings)
│   ├── Pile management & search
│   └── Inbox counter (orphan entries)
├── EntryListView (Pile detail view)
│   └── Entry list with add/delete/assign
├── OrphanEntriesView (Inbox for unassigned entries)
│   └── Entries where pile == nil
├── EditorView (Markdown/Code editor)
│   ├── HighlightedTextEditor (markdown mode)
│   └── CodeEditor (code mode, 40+ languages)
└── SettingsView (App configuration)
    └── CloudKitSyncMonitor for sync status
```

### Components
- **EntryTransformer.swift** - Router: text entries → EditorView, others → EntryItem display
- **EntryItem.swift** - Polymorphic display for text/image/link entries
- **PileItem.swift** - Pile summary card showing counts
- **EditorConfigSheet.swift** - Mode/language selector for editor

## Key Architectural Patterns

### Pile-Based Organization
Rather than folders/tags, Notable uses "Piles" (one-to-many with entries). Entries can be:
- Assigned to a pile
- Unassigned (orphans) - shown in Inbox view (OrphanEntriesView)
- Each pile has optional color tag and description

### Polymorphic Entry System
Three entry types: `text`, `image`, `link`
- **Text entries**: Full markdown/code editing via EditorView
- **Image entries**: Photo picker integration, binary storage with external storage enabled
- **Link entries**: SwiftLinkPreview for preview cards

Each entry can toggle between markdown and code mode with language selection.

### Semantic Search
Uses SVDB (Semantic Vector Database) with NLEmbedding:
- Text cleaned with `cleanText()` to remove markdown artifacts
- Embeddings generated via `NLEmbedding.sentenceEmbedding(for: .english)`
- SVDB indexed on scene activation (`.onChange(of: scenePhase)`)
- Search returns top 5 results via vector similarity

**Important**: Database reprocessing happens on every scene activation - be mindful of performance with large datasets.

### iCloud Sync
- Container: `iCloud.xyz.runkaizhang.notable`
- Both Pile and Entry entities marked as `syncable="YES"`
- Automatic conflict resolution via merge policy
- Remote notifications trigger index updates

## Development Notes

### Entry Creation Flow
```
User action → addEntry/addPicture/addLink (Operations.swift)
→ Create Entry(context: viewContext)
→ Set properties, optionally assign to pile
→ save(viewContext)
→ NSPersistentCloudKitContainer syncs to CloudKit
→ @FetchRequest auto-updates UI
```

### Editor Preferences
Stored in `@AppStorage` (UserDefaults), not CoreData:
- `markdownFontSize`, `codeFontSize`
- `selectedLanguage`, `selectedTheme`
- `autocorrectDisabled`

### File Imports
Uses security-scoped resources:
```swift
if url.startAccessingSecurityScopedResource() {
    // Read file
    url.stopAccessingSecurityScopedResource()
}
```

### App Shortcuts
Home screen long-press action: "New Entry"
- Defined in Info.plist `UIApplicationShortcutItems`
- Parsed in AppDelegate via `ActionService`

## Package Dependencies

Key third-party libraries (see Package.resolved):
- **SVDB** (2.0.0) - Semantic vector search
- **CodeEditor** (1.2.2) - Code syntax highlighting
- **HighlightedTextEditor** (2.1.0) - Markdown preview
- **SwiftLinkPreview** (3.4.0) - Link preview cards
- **CloudKitSyncMonitor** (1.2.1) - iCloud sync status UI
- **AcknowList** (3.0.1) - License display
- **CLIPKit** (main) - ML embeddings (currently commented out)

## Common Patterns

### Adding New Entry Types
1. Add type to Entry entity in Notable.xcdatamodel
2. Update `EntryItem.swift` to handle display
3. Add creation function in `Operations.swift`
4. Update `EntryListView.swift` and `OrphanEntriesView.swift` menus

### Modifying Search Behavior
- Search logic in `ContentView.swift` `filteredEntries` computed property
- Indexing in `Operations.swift` `processDatabase()`
- Text preprocessing in `cleanText()`

### Changing Pile Colors
Color tags defined in ContentView: "Raisin Black", "Safety Orange", "Non Photo Blue"
- Update color picker sheet in ContentView
- Colors stored as String in Pile.tag

## CI/CD

TestFlight automation via `ci_scripts/ci_post_xcodebuild.sh`:
- Generates release notes from last 3 git commits
- Integrates with App Store Connect

## Localization

Supports English (en) and Simplified Chinese (zh_CN) via built-in SwiftUI localization.

## Known Limitations

- No test coverage (tests should be added)
- SVDB re-indexes entire database on scene activation (performance concern)
- Search limited to top 5 results
- PileItem counts entries on every render (N+1 pattern)
- CLIPKit integration partially implemented but commented out
- Camera access and audio recording listed but not implemented
