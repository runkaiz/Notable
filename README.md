# Notable 2.0 - Your Intelligent Note-Taking Companion for iOS

Notable is a powerful, high-performance note-taking app for iOS that combines pile-based organization with advanced features like voice memos, AI-powered transcription, and semantic search. Built with SwiftUI and designed for iOS 18+, Notable offers a modern, intuitive interface for capturing and organizing your thoughts, code snippets, links, images, and voice recordings.

## ✨ What's New in 2.0

### 🎙️ Voice Memos & AI Transcription
- **Professional Audio Recording:** Record high-quality voice memos with pause/resume functionality and live waveform visualization
- **Automatic Transcription:** Leverage WhisperKit's on-device ML models with automatic fallback to Apple Speech Recognition for privacy-focused, accurate transcriptions
- **Smart Playback:** Interactive audio player with seekable waveform, expandable controls, and collapsible transcripts
- **Re-transcription:** Don't like the result? Re-transcribe with a tap

### 🎨 Enhanced User Experience
- **Refined Visual Design:** Polished UI components with smooth animations and haptic feedback
- **Better Organization:** Enhanced pile management with color-coded tags
- **Improved Performance:** Optimized data handling and sync operations

## 🚀 Core Features

### Pile-Based Organization
Unlike traditional folder hierarchies, Notable uses "Piles" - flexible collections that let you organize entries your way:
- Create multiple piles for different projects, topics, or workflows
- Color-code your piles with custom tags
- Keep unassigned entries in the Inbox for later organization
- Quick entry assignment via swipe actions

### Multiple Entry Types
- **📝 Text & Markdown:** Rich markdown editing with live preview and syntax highlighting
- **💻 Code Snippets:** Syntax highlighting for 40+ programming languages
- **🖼️ Images:** Capture or import photos with full-resolution storage
- **🔗 Links:** Save URLs with automatic preview generation
- **🎵 Audio:** Record and transcribe voice memos

### Semantic Search
Find anything instantly with natural language search powered by Apple's NLEmbedding:
- Search by meaning, not just keywords
- Results ranked by semantic similarity
- Fast, on-device processing
- Works across all your content

### iCloud Sync
- **Automatic Sync:** All your data syncs seamlessly across your iOS devices via CloudKit
- **Conflict Resolution:** Smart merge strategies keep your data consistent
- **Background Updates:** Remote notifications ensure your devices stay in sync
- **Privacy-First:** Your data never leaves Apple's ecosystem

### Customization
- **Editor Preferences:** Adjust font sizes separately for markdown and code
- **Syntax Themes:** Choose from multiple code editor themes
- **Language Selection:** Support for 40+ programming languages
- **Autocorrect Toggle:** Disable autocorrect for technical writing

### Rich Markdown & Code Editing
- **Full CommonMark Support:** Complete markdown specification compliance
- **Live Preview:** Toggle between edit and preview modes
- **Syntax Highlighting:** Beautiful code rendering with CodeEditor
- **Multi-Language:** Switch between markdown and code modes per entry

## 🛠️ Technical Highlights

- **Built with SwiftUI:** Modern, declarative UI framework
- **CoreData + CloudKit:** Robust local storage with automatic cloud sync
- **WhisperKit Integration:** State-of-the-art on-device speech recognition
- **SVDB:** Semantic vector database for intelligent search
- **Zero-Copy Architecture:** Efficient memory management for large datasets

## 📱 Requirements

- **iOS 18.0+** (optimized for latest iOS features)
- **iCloud Account:** Required for cross-device sync
- **Storage:** Varies based on number of entries and media

## 🏁 Getting Started

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/Notable.git
   cd Notable
   ```

2. **Open in Xcode**
   ```bash
   open Notable.xcodeproj
   ```

3. **Build for Simulator**
   ```bash
   xcodebuild -scheme Notable \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     -configuration Debug build
   ```

4. **Run the App**
   - Select your target device or simulator
   - Build and run (⌘R)
   - Start creating your first pile and entries

## 📖 Documentation

For detailed architecture documentation and development guidelines, see [CLAUDE.md](CLAUDE.md).

## 🤝 Contributing

Contributions are welcome! Whether it's bug fixes, new features, or documentation improvements, feel free to submit a pull request. Please ensure your code follows the project's style guidelines and includes appropriate tests where applicable.

## 📄 License

This project is licensed under the [WTFPL License](LICENSE).

## 🙏 Acknowledgments

Built with these excellent open-source libraries:
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - On-device speech recognition
- [SVDB](https://github.com/underdogorg/svdb) - Semantic vector database
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) - Markdown rendering
- [CodeEditor](https://github.com/ZeeZide/CodeEditor) - Syntax highlighting
- [DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage) - Audio waveform visualization
- [SwiftLinkPreview](https://github.com/LeonardoCardoso/SwiftLinkPreview) - Link preview generation
- [CloudKitSyncMonitor](https://github.com/ggruen/CloudKitSyncMonitor) - Sync status monitoring

---

**Notable 2.0** - Capture your thoughts. Organize your way. Find everything instantly.
