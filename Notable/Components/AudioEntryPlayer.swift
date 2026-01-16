//
//  AudioEntryPlayer.swift
//  Notable
//
//  Created by Runkai Zhang
//

import AVFoundation
import DSWaveformImage
import DSWaveformImageViews
import SwiftUI
import CoreData

// MARK: - AudioPlayerManager

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func loadAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0

            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to load audio: \(error.localizedDescription)")
        }
    }

    func playPause() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            // Pause playback, keeping current position
            print("Playback pause initiated")
            player.pause()
            timer?.invalidate()
            isPlaying = false
        } else {
            // Resume or start playback from current position
            print("Playback start/resume initiated")
            player.play()
            isPlaying = true

            // Start timer to update progress - add to common modes so it continues during scrolling
            let newTimer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
            timer = newTimer
            RunLoop.current.add(newTimer, forMode: .common)
        }
    }

    func stop() {
        print("Playback stop initiated")
        // Stop playback and reset to beginning
        guard let player = audioPlayer else { return }

        player.stop()
        player.currentTime = 0

        // Reset all state
        currentTime = 0
        progress = 0
        isPlaying = false
        timer?.invalidate()

        // Prepare player for next playback
        player.prepareToPlay()
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }

        player.currentTime = time
        currentTime = time
        progress = duration > 0 ? time / duration : 0

        // If we're playing, continue playing from new position
        // If we're paused, stay paused at new position
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
    }

    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        // Audio finished playing naturally (reached the end)
        isPlaying = false
        timer?.invalidate()

        // Reset to beginning for next play
        currentTime = 0
        progress = 0
        player.currentTime = 0
    }

    deinit {
        timer?.invalidate()
        audioPlayer?.stop()
    }
}

// MARK: - AudioEntryPlayer

struct AudioEntryPlayer: View {
    @ObservedObject var entry: Entry
    let audioData: Data
    let timestamp: Date

    @StateObject private var player = AudioPlayerManager()
    @State private var waveformImage: UIImage?
    @State private var isDragging = false
    @State private var isExpanded = false
    @State private var showTranscript = false
    @State private var isTranscribingThisEntry = false

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var sharedData: SharedData
    @AppStorage("forceAppleSpeech") private var forceAppleSpeech = false

    init(entry: Entry, audioData: Data, timestamp: Date) {
        self.entry = entry
        self.audioData = audioData
        self.timestamp = timestamp
    }

    var body: some View {
        VStack(spacing: 0) {
            // Audio player section
            HStack(spacing: 0) {
                // Waveform section - resizes based on expansion state
                VStack(spacing: 8) {
                    // Waveform with progress overlay
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            if let image = waveformImage {
                                // Background waveform (gray/uncolored)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                                    .opacity(0.3)

                                // Progress overlay - masked by waveform shape
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                                    .foregroundStyle(.primary)
                                    .mask(
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .frame(width: geometry.size.width * player.progress)
                                            Spacer(minLength: 0)
                                        }
                                    )
                            } else {
                                // Fallback: simple shapes
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.tertiarySystemFill))
                                    .frame(width: geometry.size.width, height: geometry.size.height)

                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(width: geometry.size.width * player.progress, height: geometry.size.height, alignment: .leading)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()

                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isExpanded.toggle()
                            }
                        }
                        .gesture(
                            // Only actively handle drag when expanded
                            isExpanded ?
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let width = value.location.x
                                    let newProgress = max(0, min(1, width / geometry.size.width))
                                    player.seek(to: newProgress * player.duration)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                            : nil
                        )
                    }
                    .frame(height: 50)

                    // Time labels - always visible
                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.caption2)
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(formatTime(player.duration))
                            .font(.caption2)
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Controls section - always visible, expands to show more
                VStack(spacing: 0) {
                    // Top spacer - grows when stop button is shown
                    Spacer(minLength: 0)
                        .frame(maxHeight: (isExpanded && !player.isPlaying && player.currentTime > 0) ? .infinity : 0)

                    // Play/Pause button - always visible, moves up when stop button appears
                    Button(action: {
                        print("🎵 Play/Pause button tapped (isPlaying=\(player.isPlaying))")
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            player.playPause()
                        }
                    }) {
                        Circle()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                    .offset(x: player.isPlaying ? 0 : 1.5)
                                    .animation(.spring(response: 0.2, dampingFraction: 1.0), value: player.isPlaying)
                                    .allowsHitTesting(false)
                            )
                    }
                    .id("playbutton-\(player.isPlaying)")
                    .transition(.identity)
                    .buttonStyle(.plain)

                    // Stop button - conditionally shown with animation
                    if isExpanded && !player.isPlaying && player.currentTime > 0 {
                        Button(action: {
                            print("🛑 Stop button tapped")
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                player.stop()
                            }
                        }) {
                            Circle()
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .allowsHitTesting(false)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale(scale: 0.5).combined(with: .opacity).combined(with: .move(edge: .top))
                        ))
                    }

                    // Bottom spacer - grows when stop button is shown
                    Spacer(minLength: 0)
                        .frame(maxHeight: (isExpanded && !player.isPlaying && player.currentTime > 0) ? .infinity : 0)
                }
                .padding(.leading, 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded && !player.isPlaying && player.currentTime > 0)
            }
            .padding(12)

            // Transcript section
            if let transcript = entry.transcript, !transcript.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showTranscript.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(String(localized: "Transcript"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if showTranscript {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(transcript)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)

                            // Re-transcribe and Export buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Start re-transcription immediately
                                    Task {
                                        await retranscribe(using: nil)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption2)
                                        Text(String(localized: "Re-transcribe"))
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isTranscribingThisEntry)

                                if isTranscribingThisEntry {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }

                                Spacer()

                                // Export button
                                ShareLink(
                                    item: Note(
                                        title: generateTranscriptFilename(),
                                        body: transcript
                                    ),
                                    preview: SharePreview(generateTranscriptFilename())
                                ) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption2)
                                        Text(String(localized: "Export"))
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            } else {
                // Show "Transcribing..." or "Tap to transcribe" button
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)

                    if isTranscribingThisEntry || (entry.transcribing) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)

                            Text(String(localized: "Transcribing..."))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    } else {
                        Button(action: {
                            // Auto-transcribe without picker
                            Task {
                                await retranscribe(using: nil)
                            }
                        }) {
                            HStack {
                                Image(systemName: "waveform.badge.mic")
                                    .font(.caption)
                                    .foregroundStyle(.blue)

                                Text(String(localized: "Tap to transcribe"))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isTranscribingThisEntry)
                    }
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTranscript)
        .onAppear {
            player.loadAudio(data: audioData)
            generateWaveform()
        }
        .onDisappear {
            player.stop()
        }
        .onChange(of: player.isPlaying) { _, newValue in
            // Auto-expand when playing starts
            if newValue && !isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded = true
                }
            }
            // Auto-collapse when playback finishes
            if !newValue && player.currentTime == 0 && isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded = false
                }
            }
        }
    }

    private func retranscribe(using provider: TranscriptionProvider?) async {
        // Set local state to show this specific entry is transcribing
        await MainActor.run {
            isTranscribingThisEntry = true
        }

        // Respect the forceAppleSpeech setting
        let effectiveProvider: TranscriptionProvider?
        if forceAppleSpeech {
            effectiveProvider = .appleSpeech
        } else {
            effectiveProvider = provider
        }

        await retranscribeEntry(
            viewContext,
            entry: entry,
            transcriptionService: sharedData.transcriptionService,
            provider: effectiveProvider
        )

        await MainActor.run {
            isTranscribingThisEntry = false
            if !showTranscript && entry.transcript != nil && !(entry.transcript?.isEmpty ?? true) {
                withAnimation {
                    showTranscript = true
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func generateTranscriptFilename() -> String {
        // Use the entry's title if it exists and isn't the default "Voice Memo"
        if let title = entry.title, !title.isEmpty, title != "Voice Memo" {
            return "\(title) - Transcript"
        }

        // Otherwise, generate a filename based on timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm"
        let dateString = formatter.string(from: timestamp)
        return "Voice Memo \(dateString) - Transcript"
    }

    private func generateWaveform() {
        Task {
            // Detect the audio format from the data to use the correct file extension
            let fileExtension = detectAudioFormat(from: audioData)
            print("🎵 Generating waveform for \(fileExtension) file (\(audioData.count) bytes)")

            // Write audio data to temporary file for waveform generation
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            do {
                try audioData.write(to: tempURL)
                print("📝 Wrote temp file: \(tempURL.lastPathComponent)")

                // Analyze audio to determine optimal scaling
                var scalingFactor: Float = 1.0
                if let audioFile = try? AVAudioFile(forReading: tempURL) {
                    let format = audioFile.processingFormat
                    print("📊 Audio file info: \(format.sampleRate)Hz, \(format.channelCount) channels, \(audioFile.length) frames")

                    // Analyze peak amplitude for normalization
                    scalingFactor = analyzePeakAmplitude(audioFile: audioFile)
                    print("🎚️ Calculated scaling factor: \(scalingFactor)")
                } else {
                    print("⚠️ Could not read audio file - may cause waveform issues")
                }

                let configuration = Waveform.Configuration(
                    size: CGSize(width: UIScreen.main.bounds.width - 64, height: 60),
                    backgroundColor: .clear,
                    style: .filled(UIColor.systemGray),
                    verticalScalingFactor: CGFloat(scalingFactor),
                    shouldAntialias: true
                )

                let renderer = WaveformImageDrawer()
                do {
                    let image = try await renderer.waveformImage(
                        fromAudioAt: tempURL,
                        with: configuration
                    )
                    await MainActor.run {
                        waveformImage = image
                    }
                    print("✅ Waveform generated successfully for \(fileExtension) file")
                } catch {
                    print("❌ Failed to generate waveform: \(error.localizedDescription)")
                    print("   Error details: \(error)")
                }
            } catch {
                print("❌ Failed to write audio data to temporary file: \(error.localizedDescription)")
            }

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    /// Analyzes audio file to calculate optimal scaling factor for waveform normalization
    /// Returns a scaling factor where 1.0 = no scaling, >1.0 = amplify quiet audio, <1.0 = reduce loud audio
    private func analyzePeakAmplitude(audioFile: AVAudioFile) -> Float {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
            print("⚠️ Could not create audio buffer for analysis")
            return 1.0
        }

        do {
            try audioFile.read(into: buffer)
        } catch {
            print("⚠️ Could not read audio file for analysis: \(error.localizedDescription)")
            return 1.0
        }

        guard let channelData = buffer.floatChannelData else {
            print("⚠️ No channel data available")
            return 1.0
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        // Find peak amplitude across all channels
        var peakAmplitude: Float = 0.0
        for channel in 0..<channelCount {
            let channelBuffer = channelData[channel]
            for frame in 0..<frameLength {
                let amplitude = abs(channelBuffer[frame])
                if amplitude > peakAmplitude {
                    peakAmplitude = amplitude
                }
            }
        }

        print("📈 Peak amplitude: \(peakAmplitude)")

        // Calculate scaling factor
        // If peak is very high (> 0.9), we don't need much scaling
        // If peak is low, amplify it to make waveform visible
        // Target peak around 0.95 for good visual representation

        if peakAmplitude < 0.01 {
            // Very quiet audio - amplify significantly
            return 1.0
        } else if peakAmplitude > 0.95 {
            // Very loud/normalized audio - scale down slightly to show variation
            return 0.85
        } else {
            // Calculate scaling to bring peak close to 0.95
            let targetPeak: Float = 0.95
            return targetPeak / peakAmplitude
        }
    }

    /// Detects audio format from file data by checking magic bytes
    private func detectAudioFormat(from data: Data) -> String {
        guard data.count >= 12 else { return "m4a" }

        let bytes = [UInt8](data.prefix(12))

        // MP3 - starts with ID3 tag or MPEG frame sync
        if bytes.count >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33 {
            return "mp3" // ID3v2 tag
        }
        if bytes.count >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 {
            return "mp3" // MPEG frame sync
        }

        // WAV - RIFF header
        if bytes.count >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            return "wav"
        }

        // M4A/AAC - ftyp box (ISO Base Media File Format)
        if bytes.count >= 8 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return "m4a"
        }

        // FLAC
        if bytes.count >= 4 && bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43 {
            return "flac"
        }

        // OGG
        if bytes.count >= 4 && bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53 {
            return "ogg"
        }

        // CAF (Core Audio Format)
        if bytes.count >= 4 && bytes[0] == 0x63 && bytes[1] == 0x61 && bytes[2] == 0x66 && bytes[3] == 0x66 {
            return "caf"
        }

        // AIFF
        if bytes.count >= 4 && bytes[0] == 0x46 && bytes[1] == 0x4F && bytes[2] == 0x52 && bytes[3] == 0x4D {
            if bytes.count >= 12 && bytes[8] == 0x41 && bytes[9] == 0x49 && bytes[10] == 0x46 && bytes[11] == 0x46 {
                return "aiff"
            }
        }

        // Default to m4a if format unknown
        print("⚠️ Unknown audio format, defaulting to m4a")
        return "m4a"
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    // Preview not available without proper Entry context
    Text("AudioEntryPlayer Preview")
}
