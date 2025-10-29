//
//  AudioRecorderView.swift
//  Notable
//
//  Created by Runkai Zhang
//

import SwiftUI
import AVFoundation
import AVFAudio
import DSWaveformImage
import DSWaveformImageViews

class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var audioURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var currentPower: Float = 0
    @Published var powerLevels: [Float] = []

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var audioSession: AVAudioSession?
    private let maxPowerLevels = 50 // Keep last 50 samples for waveform

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.hasPermission = allowed
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.hasPermission = allowed
                }
            }
        }
    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            guard let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get document directory")
                return
            }
            let audioFilename = documentPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            self.audioURL = audioFilename
            self.isRecording = true
            self.recordingDuration = 0
            self.powerLevels = [] // Reset power levels for new recording

            // Start timer for duration and metering - add to common modes so it continues during scrolling
            let newTimer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateMetering()
            }
            timer = newTimer
            RunLoop.current.add(newTimer, forMode: .common)

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func pauseRecording() {
        guard isRecording, !isPaused, let recorder = audioRecorder else {
            print("Cannot pause: isRecording=\(isRecording), isPaused=\(isPaused), recorder=\(audioRecorder != nil)")
            return
        }

        // Pause recording
        recorder.pause()
        isPaused = true
        timer?.invalidate()
        print("Recording paused successfully")
    }

    func resumeRecording() {
        guard isRecording, isPaused, let recorder = audioRecorder else {
            print("Cannot resume: isRecording=\(isRecording), isPaused=\(isPaused), recorder=\(audioRecorder != nil)")
            return
        }

        // Resume recording from paused state
        let resumed = recorder.record()
        if resumed {
            isPaused = false

            // Restart timer for duration and metering - add to common modes so it continues during scrolling
            let newTimer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateMetering()
            }
            timer = newTimer
            RunLoop.current.add(newTimer, forMode: .common)
            print("Recording resumed successfully")
        } else {
            print("Failed to resume recording")
        }
    }

    func stopRecording() {
        guard isRecording else {
            print("Cannot stop: not currently recording")
            return
        }

        print("Stopping recording (was paused: \(isPaused))")
        audioRecorder?.stop()
        timer?.invalidate()
        isRecording = false
        isPaused = false

        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("Recording stopped successfully")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    func deleteRecording() {
        if let url = audioURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioURL = nil
        recordingDuration = 0
    }

    private func updateMetering() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        recordingDuration = recorder.currentTime

        // Get average power for visualization (-160 to 0 dB)
        let power = recorder.averagePower(forChannel: 0)

        // Normalize to 0-1 range with better sensitivity
        // Use a smaller range (-50 to 0) for more responsive visualization
        // Clamp at 0 for silence and scale more aggressively for audible sound
        let normalizedPower = max(0, min(1, (power + 50) / 50))
        currentPower = normalizedPower

        // Add to power levels array for waveform visualization
        powerLevels.append(currentPower)

        // Keep only the last N samples to prevent memory growth
        if powerLevels.count > maxPowerLevels {
            powerLevels.removeFirst()
        }
    }
}

struct AudioRecorderView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @Environment(\.dismiss) var dismiss

    let onSave: (URL) -> Void

    @State private var waveformScale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Waveform visualization area
                    VStack(spacing: 16) {
                        if recorder.isRecording {
                            // Live recording indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                                    .opacity(recorder.isPaused ? 0.3 : 1.0)
                                    .scaleEffect(recorder.isPaused ? 1.0 : waveformScale)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: waveformScale)

                                Text(recorder.isPaused ? "Paused" : "Recording")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                        }

                        // Duration display
                        Text(formatDuration(recorder.recordingDuration))
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        // Waveform visualization
                        if let audioURL = recorder.audioURL {
                            WaveformView(
                                audioURL: audioURL,
                                isRecording: recorder.isRecording,
                                powerLevels: recorder.powerLevels
                            )
                            .frame(height: 80)
                            .padding(.horizontal, 40)
                        } else {
                            // Placeholder waveform
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(height: 80)
                                .padding(.horizontal, 40)
                                .overlay(
                                    Image(systemName: "waveform")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.tertiary)
                                )
                        }
                    }

                    Spacer()

                    // Control buttons
                    VStack(spacing: 24) {
                        if !recorder.isRecording && recorder.audioURL == nil {
                            // Initial state: Start recording button
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    recorder.startRecording()
                                    waveformScale = 1.2
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 80, height: 80)

                                    Circle()
                                        .fill(.white)
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .accessibilityLabel("Start recording")
                            .accessibilityHint("Begins voice recording")
                            .disabled(!recorder.hasPermission)

                            if !recorder.hasPermission {
                                Text("Microphone permission required")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if !recorder.isRecording && recorder.audioURL != nil {
                            // Recording stopped: Show review options
                            VStack(spacing: 20) {
                                Text("Recording complete!")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text("Tap Save to keep, or Cancel to discard")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)

                                // Re-record button
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()

                                    withAnimation(.spring(response: 0.3)) {
                                        recorder.deleteRecording()
                                        recorder.startRecording()
                                        waveformScale = 1.2
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 14))
                                        Text("Record Again")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [.red, .red.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    )
                                }
                                .accessibilityLabel("Record again")
                                .accessibilityHint("Discards current recording and starts a new one")
                            }
                        } else {
                            // Recording controls
                            VStack(spacing: 24) {
                                // Pause/Resume button (primary action) - centered
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    withAnimation(.spring(response: 0.3)) {
                                        if recorder.isPaused {
                                            recorder.resumeRecording()
                                            waveformScale = 1.2
                                        } else {
                                            recorder.pauseRecording()
                                            waveformScale = 1.0
                                        }
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(
                                                    colors: recorder.isPaused ? [.green, .green.opacity(0.8)] : [.orange, .orange.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 80, height: 80)

                                            Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(.white)
                                                .offset(x: recorder.isPaused ? 2 : 0)
                                        }

                                        Text(recorder.isPaused ? "Resume" : "Pause")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .accessibilityLabel(recorder.isPaused ? "Resume recording" : "Pause recording")
                                .accessibilityHint(recorder.isPaused ? "Continues recording from where you paused" : "Pauses recording temporarily")

                                // Stop button (secondary action) - below
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()

                                    withAnimation(.spring(response: 0.3)) {
                                        recorder.stopRecording()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 14))
                                        Text("Stop Recording")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color(UIColor.tertiarySystemBackground))
                                    )
                                }
                                .accessibilityLabel("Stop recording")
                                .accessibilityHint("Finishes recording and allows you to save or discard")
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if recorder.isRecording {
                            recorder.stopRecording()
                        }
                        recorder.deleteRecording()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if recorder.isRecording {
                            recorder.stopRecording()
                        }
                        if let url = recorder.audioURL {
                            onSave(url)
                        }
                        dismiss()
                    }
                    .disabled(recorder.audioURL == nil || recorder.isRecording)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if !recorder.hasPermission {
                recorder.checkPermission()
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Waveform visualization component
struct WaveformView: View {
    let audioURL: URL
    let isRecording: Bool
    let powerLevels: [Float]

    @State private var waveformImage: UIImage?

    var body: some View {
        ZStack {
            if let image = waveformImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Live waveform visualization during recording
                HStack(alignment: .center, spacing: 4) {
                    ForEach(0..<30) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                            .frame(width: 3)
                            .frame(height: heightForBar(at: index))
                            .animation(.easeInOut(duration: 0.1), value: powerLevels)
                    }
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if !newValue {
                generateWaveform()
            }
        }
    }

    private func heightForBar(at index: Int) -> CGFloat {
        // Map the 30 bars to the available power levels
        // If we have fewer power levels than bars, use the last available or a default
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 60

        guard !powerLevels.isEmpty else {
            return minHeight
        }

        // Sample from the power levels array
        // Spread the samples evenly across the available power levels
        let sampleIndex = Int(Float(index) / 30.0 * Float(powerLevels.count))
        let clampedIndex = min(sampleIndex, powerLevels.count - 1)

        let power = powerLevels[clampedIndex]

        // Apply exponential scaling for more sensitivity
        // This makes small sounds more visible while still allowing large peaks
        let scaledPower = pow(power, 0.5)

        // Map power (0-1) to height range
        return minHeight + CGFloat(scaledPower) * (maxHeight - minHeight)
    }

    private func generateWaveform() {
        Task {
            // Analyze audio to determine optimal scaling
            var scalingFactor: Float = 1.0
            if let audioFile = try? AVAudioFile(forReading: audioURL) {
                scalingFactor = analyzePeakAmplitude(audioFile: audioFile)
                print("🎚️ Recorder waveform scaling factor: \(scalingFactor)")
            }

            let configuration = Waveform.Configuration(
                size: CGSize(width: 300, height: 80),
                backgroundColor: .clear,
                style: .filled(UIColor.systemBlue),
                verticalScalingFactor: CGFloat(scalingFactor),
                shouldAntialias: true
            )

            let renderer = WaveformImageDrawer()
            if let image = try? await renderer.waveformImage(
                fromAudioAt: audioURL,
                with: configuration
            ) {
                await MainActor.run {
                    waveformImage = image
                }
            }
        }
    }

    /// Analyzes audio file to calculate optimal scaling factor for waveform normalization
    private func analyzePeakAmplitude(audioFile: AVAudioFile) -> Float {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
            return 1.0
        }

        do {
            try audioFile.read(into: buffer)
        } catch {
            return 1.0
        }

        guard let channelData = buffer.floatChannelData else {
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

        // Calculate scaling factor
        if peakAmplitude < 0.01 {
            return 1.0
        } else if peakAmplitude > 0.95 {
            return 0.85
        } else {
            let targetPeak: Float = 0.95
            return targetPeak / peakAmplitude
        }
    }
}

