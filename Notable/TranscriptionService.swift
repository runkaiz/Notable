//
//  TranscriptionService.swift
//  Notable
//
//  Created by Runkai Zhang
//

import Foundation
import AVFoundation
import Speech
import WhisperKit
import Combine

// MARK: - TranscriptionProvider

public enum TranscriptionProvider: String, CaseIterable {
    case whisperKit = "WhisperKit"
    case appleSpeech = "Apple Speech"
}

// MARK: - TranscriptionResult

public struct TranscriptionResult {
    let text: String
    let provider: TranscriptionProvider
    let duration: TimeInterval
    let error: Error?

    var isSuccess: Bool {
        error == nil && !text.isEmpty
    }
}

// MARK: - TranscriptionError

public enum TranscriptionError: LocalizedError {
    case noAudioData
    case permissionDenied
    case whisperKitInitFailed
    case whisperKitTranscriptionFailed(Error)
    case appleSpeechNotAvailable
    case appleSpeechTranscriptionFailed(Error)
    case allProvidersFailed
    case audioFileWriteFailed

    public var errorDescription: String? {
        switch self {
        case .noAudioData:
            return "No audio data available for transcription"
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .whisperKitInitFailed:
            return "Failed to initialize WhisperKit"
        case .whisperKitTranscriptionFailed(let error):
            return "WhisperKit transcription failed: \(error.localizedDescription)"
        case .appleSpeechNotAvailable:
            return "Apple Speech recognition not available"
        case .appleSpeechTranscriptionFailed(let error):
            return "Apple Speech transcription failed: \(error.localizedDescription)"
        case .allProvidersFailed:
            return "All transcription providers failed"
        case .audioFileWriteFailed:
            return "Failed to write audio file for transcription"
        }
    }
}

// MARK: - TranscriptionModelStatus

public enum TranscriptionModelStatus: Equatable {
    case notStarted
    case downloading(progress: Double)
    case ready
    case failed(String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .notStarted:
            return "Initializing..."
        case .downloading(let progress):
            return "Downloading model... \(Int(progress * 100))%"
        case .ready:
            return "Ready"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }

    var statusIcon: String {
        switch self {
        case .notStarted:
            return "ellipsis.circle"
        case .downloading:
            return "arrow.down.circle"
        case .ready:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    var statusColor: String {
        switch self {
        case .notStarted:
            return "gray"
        case .downloading:
            return "blue"
        case .ready:
            return "green"
        case .failed:
            return "orange"
        }
    }
}

// MARK: - TranscriptionService

public class TranscriptionService: ObservableObject, @unchecked Sendable {
    @Published var isTranscribing = false
    @Published var progress: Double = 0.0
    @Published var currentProvider: TranscriptionProvider?

    // WhisperKit model status
    @Published var modelStatus: TranscriptionModelStatus = .notStarted

    private var whisperKit: WhisperKit?
    private var progressTimer: Timer?

    // MARK: - Initialization

    public init() {
        // Initialize WhisperKit asynchronously
        Task {
            await initializeWhisperKit()
        }
    }

    deinit {
        progressTimer?.invalidate()
    }

    // MARK: - WhisperKit Initialization

    private func initializeWhisperKit() async {
        guard case .notStarted = modelStatus else { return }

        print("📥 Initializing WhisperKit with automatic model selection...")

        // Start simulated progress updates
        await startProgressSimulation()

        do {
            // Let WhisperKit automatically choose the most optimal model
            // Note: WhisperKit doesn't expose download progress, so we simulate it
            whisperKit = try await WhisperKit(verbose: false)

            // Stop progress simulation and mark as ready
            await stopProgressSimulation()
            await MainActor.run {
                modelStatus = .ready
            }
            print("✅ WhisperKit initialized successfully with automatic model selection")

        } catch {
            print("⚠️ Failed to initialize WhisperKit: \(error.localizedDescription)")
            print("Will fall back to Apple Speech for transcription")

            await stopProgressSimulation()
            await MainActor.run {
                modelStatus = .failed("Model download failed")
            }
        }
    }

    // Simulate download progress since WhisperKit doesn't expose it
    private func startProgressSimulation() async {
        await MainActor.run {
            modelStatus = .downloading(progress: 0.1)

            // Create a timer that updates progress
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                Task { @MainActor in
                    if case .downloading(let currentProgress) = self.modelStatus {
                        // Gradually increase progress from 0.1 to 0.9
                        let newProgress = min(currentProgress + 0.05, 0.9)
                        self.modelStatus = .downloading(progress: newProgress)
                    }
                }
            }
        }
    }

    private func stopProgressSimulation() async {
        await MainActor.run {
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }

    // MARK: - Public Transcription Methods

    /// Transcribe audio data using WhisperKit (primary) with Apple Speech fallback
    public func transcribe(audioData: Data) async -> TranscriptionResult {
        await MainActor.run {
            isTranscribing = true
            progress = 0.0
            currentProvider = .whisperKit
        }

        // Try WhisperKit first
        print("🎙️ Starting transcription with WhisperKit...")

        let whisperResult = await transcribeWithWhisperKit(audioData: audioData)

        if whisperResult.isSuccess {
            await MainActor.run {
                isTranscribing = false
                progress = 1.0
            }
            return whisperResult
        }

        // Fall back to Apple Speech
        print("⚠️ WhisperKit failed, falling back to Apple Speech...")
        await MainActor.run {
            currentProvider = .appleSpeech
            progress = 0.0
        }

        let speechResult = await transcribeWithAppleSpeech(audioData: audioData)

        await MainActor.run {
            isTranscribing = false
            progress = 1.0
        }
        return speechResult
    }

    /// Transcribe with a specific provider (for manual retry)
    public func transcribe(audioData: Data, using provider: TranscriptionProvider) async -> TranscriptionResult {
        await MainActor.run {
            isTranscribing = true
            progress = 0.0
            currentProvider = provider
        }

        let result: TranscriptionResult

        switch provider {
        case .whisperKit:
            result = await transcribeWithWhisperKit(audioData: audioData)
        case .appleSpeech:
            result = await transcribeWithAppleSpeech(audioData: audioData)
        }

        await MainActor.run {
            isTranscribing = false
            progress = 1.0
        }
        return result
    }

    // MARK: - WhisperKit Transcription

    private func transcribeWithWhisperKit(audioData: Data) async -> TranscriptionResult {
        let startTime = Date()

        // Ensure WhisperKit is initialized
        if !modelStatus.isReady {
            await initializeWhisperKit()
        }

        guard let whisperKit = whisperKit, modelStatus.isReady else {
            return TranscriptionResult(
                text: "",
                provider: .whisperKit,
                duration: Date().timeIntervalSince(startTime),
                error: TranscriptionError.whisperKitInitFailed
            )
        }

        do {
            // Write audio data to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")

            try audioData.write(to: tempURL)

            // Update progress
            await MainActor.run { progress = 0.2 }

            // Transcribe with WhisperKit
            let transcriptionResults = try await whisperKit.transcribe(audioPath: tempURL.path)

            await MainActor.run { progress = 0.9 }

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)

            // Extract text from segments
            let text = transcriptionResults.map { $0.text }.joined(separator: " ")

            let duration = Date().timeIntervalSince(startTime)
            print("✅ WhisperKit transcription completed in \(String(format: "%.2f", duration))s")

            return TranscriptionResult(
                text: text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                provider: .whisperKit,
                duration: duration,
                error: nil
            )

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ WhisperKit transcription error: \(error.localizedDescription)")

            return TranscriptionResult(
                text: "",
                provider: .whisperKit,
                duration: duration,
                error: TranscriptionError.whisperKitTranscriptionFailed(error)
            )
        }
    }

    // MARK: - Apple Speech Transcription

    private func transcribeWithAppleSpeech(audioData: Data) async -> TranscriptionResult {
        let startTime = Date()

        // Check authorization
        let authStatus = SFSpeechRecognizer.authorizationStatus()

        if authStatus == .denied || authStatus == .restricted {
            return TranscriptionResult(
                text: "",
                provider: .appleSpeech,
                duration: Date().timeIntervalSince(startTime),
                error: TranscriptionError.permissionDenied
            )
        }

        // Request authorization if needed
        if authStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume()
                }
            }
        }

        // Create recognizer
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            return TranscriptionResult(
                text: "",
                provider: .appleSpeech,
                duration: Date().timeIntervalSince(startTime),
                error: TranscriptionError.appleSpeechNotAvailable
            )
        }

        do {
            // Write audio data to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")

            try audioData.write(to: tempURL)

            await MainActor.run { progress = 0.2 }

            // Create recognition request
            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // Force on-device recognition

            // Perform recognition
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
                recognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: result)
                    }
                }
            }

            await MainActor.run { progress = 0.9 }

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)

            let text = result.bestTranscription.formattedString
            let duration = Date().timeIntervalSince(startTime)

            print("✅ Apple Speech transcription completed in \(String(format: "%.2f", duration))s")

            return TranscriptionResult(
                text: text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                provider: .appleSpeech,
                duration: duration,
                error: nil
            )

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ Apple Speech transcription error: \(error.localizedDescription)")

            return TranscriptionResult(
                text: "",
                provider: .appleSpeech,
                duration: duration,
                error: TranscriptionError.appleSpeechTranscriptionFailed(error)
            )
        }
    }

    // MARK: - Permission Check

    public func checkSpeechRecognitionPermission() -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        return status == .authorized
    }

    public func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
