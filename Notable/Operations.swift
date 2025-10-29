//
//  Operations.swift
//  Notable
//
//  Created by Runkai Zhang on 8/11/23.
//

import CoreData
import SwiftUI
import SVDB
import NaturalLanguage
import os.log
import AVFoundation

public func addEntry(_ viewContext: NSManagedObjectContext, pile: Pile?) {
    withAnimation {
        let newEntry = Entry(context: viewContext)
        newEntry.timestamp = Date()
        newEntry.id = UUID()
        newEntry.title = "Untitled"
        newEntry.content = ""
        newEntry.isMarkdown = true
        newEntry.language = "markdown"
        newEntry.type = EntryType.text.rawValue
        
        if let pile = pile {
            pile.addToEntries(newEntry)
        }
        
        save(viewContext)
    }
}

public func addPicture(_ viewContext: NSManagedObjectContext, image: Data, pile: Pile?) {
    withAnimation {
        let newEntry = Entry(context: viewContext)
        newEntry.timestamp = Date()
        newEntry.id = UUID()
        newEntry.type = EntryType.image.rawValue

        // Validate and compress image if needed (CloudKit has 10MB limit per attribute)
        let validatedImage = validateAndCompressImage(image)
        newEntry.image = validatedImage

        if let pile = pile {
            pile.addToEntries(newEntry)
        }

        save(viewContext)
    }
}

/// Validates image size and compresses if necessary to stay under CloudKit's 10MB limit
/// - Parameter imageData: Original image data
/// - Returns: Validated and potentially compressed image data
private func validateAndCompressImage(_ imageData: Data) -> Data {
    // Target 8MB to leave headroom under CloudKit's 10MB limit
    let targetSize = 8_000_000

    // If already under limit, return as-is
    if imageData.count <= targetSize {
        os_log("📸 Image size OK: %{public}@ bytes", log: .default, type: .info, ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))
        return imageData
    }

    os_log("⚠️ Image size %{public}@ exceeds recommended limit, compressing...",
           log: .default,
           type: .info,
           ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))

    // Try to compress the image
    guard let image = UIImage(data: imageData) else {
        os_log("❌ Failed to create UIImage from data, returning original", log: .default, type: .error)
        return imageData
    }

    // Start with high quality and reduce if needed
    var compressionQuality: CGFloat = 0.8
    var compressedData = image.jpegData(compressionQuality: compressionQuality)

    // Iteratively reduce quality until we're under target size
    while let data = compressedData, data.count > targetSize && compressionQuality > 0.1 {
        compressionQuality -= 0.1
        compressedData = image.jpegData(compressionQuality: compressionQuality)
    }

    if let finalData = compressedData {
        os_log("✅ Image compressed to %{public}@ (quality: %.1f)",
               log: .default,
               type: .info,
               ByteCountFormatter.string(fromByteCount: Int64(finalData.count), countStyle: .file),
               compressionQuality)
        return finalData
    }

    // If compression failed, return original and log warning
    os_log("⚠️ Compression failed, using original image", log: .default, type: .error)
    return imageData
}

public func addLink(_ viewContext: NSManagedObjectContext, newLink: String, pile: Pile?) {
    withAnimation {
        if verifyUrl(urlString: newLink) {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.link.rawValue
            newEntry.link = URL(string: newLink)

            if let pile = pile {
                pile.addToEntries(newEntry)
            }

            save(viewContext)
        } else {
            os_log("⚠️ Invalid URL provided: %{public}@", log: .default, type: .error, newLink)

            // Post notification so UI can show an alert to the user
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("InvalidURLError"),
                    object: nil,
                    userInfo: ["url": newLink]
                )
            }
        }
    }
}

public func addRecording(_ viewContext: NSManagedObjectContext, audioURL: URL, pile: Pile?, transcriptionService: TranscriptionService? = nil) {
    withAnimation {
        do {
            let audioData = try Data(contentsOf: audioURL)

            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.type = EntryType.recording.rawValue
            newEntry.audio = audioData
            newEntry.title = "Voice Memo"

            if let pile = pile {
                pile.addToEntries(newEntry)
            }

            save(viewContext)

            // Clean up the temporary recording file
            try? FileManager.default.removeItem(at: audioURL)

            // Transcribe audio in the background (only for recordings < 2 minutes)
            if let transcriptionService = transcriptionService {
                // Check audio duration
                let audioDuration = getAudioDuration(from: audioData)
                let maxAutoTranscribeDuration: TimeInterval = 120 // 2 minutes

                // Only auto-transcribe if duration is under threshold
                if audioDuration > 0 && audioDuration < maxAutoTranscribeDuration {
                    print("📝 Auto-transcribing audio (\(String(format: "%.1f", audioDuration))s)")

                    // Mark entry as transcribing
                    newEntry.transcribing = true
                    save(viewContext)

                    // Check if user wants to force Apple Speech
                    let forceAppleSpeech = UserDefaults.standard.bool(forKey: "forceAppleSpeech")

                    // Capture objectID to avoid Sendable warning
                    let entryObjectID = newEntry.objectID

                    Task { @MainActor in
                        let result: TranscriptionResult
                        if forceAppleSpeech {
                            result = await transcriptionService.transcribe(audioData: audioData, using: .appleSpeech)
                        } else {
                            result = await transcriptionService.transcribe(audioData: audioData)
                        }

                        // Fetch entry from objectID
                        guard let entry = try? viewContext.existingObject(with: entryObjectID) as? Entry else {
                            print("❌ Failed to fetch entry for transcription update")
                            return
                        }

                        if result.isSuccess {
                            entry.transcript = result.text
                            print("✅ Transcription saved: \(result.text.prefix(50))... (via \(result.provider.rawValue))")
                        } else if let error = result.error {
                            print("❌ Transcription failed: \(error.localizedDescription)")
                        }

                        // Mark transcription as complete
                        entry.transcribing = false
                        save(viewContext)
                    }
                } else {
                    print("⏭️ Skipping auto-transcription for long recording (\(String(format: "%.1f", audioDuration))s). User can manually transcribe.")
                }
            }
        } catch {
            os_log("❌ Failed to save recording: %{public}@", log: .default, type: .error, error.localizedDescription)

            // Post notification so UI can show an alert to the user
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RecordingSaveError"),
                    object: nil,
                    userInfo: ["error": error]
                )
            }
        }
    }
}

public func retranscribeEntry(_ viewContext: NSManagedObjectContext, entry: Entry, transcriptionService: TranscriptionService, provider: TranscriptionProvider? = nil) async {
    guard let audioData = entry.audio else {
        print("❌ No audio data available for transcription")
        return
    }

    // Capture objectID to avoid Sendable warning
    let entryObjectID = entry.objectID

    // Mark entry as transcribing
    await MainActor.run {
        guard let entry = try? viewContext.existingObject(with: entryObjectID) as? Entry else {
            print("❌ Failed to fetch entry for transcription start")
            return
        }
        entry.transcribing = true
        save(viewContext)
    }

    let result: TranscriptionResult
    if let provider = provider {
        result = await transcriptionService.transcribe(audioData: audioData, using: provider)
    } else {
        result = await transcriptionService.transcribe(audioData: audioData)
    }

    await MainActor.run {
        // Fetch entry from objectID
        guard let entry = try? viewContext.existingObject(with: entryObjectID) as? Entry else {
            print("❌ Failed to fetch entry for re-transcription update")
            return
        }

        if result.isSuccess {
            entry.transcript = result.text
            print("✅ Re-transcription successful: \(result.text.prefix(50))... (via \(result.provider.rawValue))")
        } else if let error = result.error {
            print("❌ Re-transcription failed: \(error.localizedDescription)")
        }

        // Mark transcription as complete
        entry.transcribing = false
        save(viewContext)
    }
}

public func verifyUrl (urlString: String?) -> Bool {
   if let urlString = urlString {
       if let url  = URL(string: urlString) {
           return UIApplication.shared.canOpenURL(url)
       }
   }
   return false
}

public func deleteEntry(_ viewContext: NSManagedObjectContext, entries: [Entry], selection: Entry?) {
    guard let entry = selection,
          let index = entries.firstIndex(of: entry) else {
        return
    }

    withAnimation {
        viewContext.delete(entries[index])
        save(viewContext)
    }
}

public func save(_ viewContext: NSManagedObjectContext) {
    viewContext.perform {
        // Check if there are changes to save
        guard viewContext.hasChanges else {
            os_log("💾 No changes to save", log: .cloudKitSync, type: .debug)
            return
        }

        let insertedCount = viewContext.insertedObjects.count
        let updatedCount = viewContext.updatedObjects.count
        let deletedCount = viewContext.deletedObjects.count

        os_log("💾 Saving changes - Inserted: %d, Updated: %d, Deleted: %d",
               log: .cloudKitSync,
               type: .info,
               insertedCount,
               updatedCount,
               deletedCount)

        do {
            try viewContext.save()
            os_log("✅ Context saved successfully, CloudKit will sync changes",
                   log: .cloudKitSync,
                   type: .info)
        } catch {
            let nsError = error as NSError
            os_log("❌ Failed to save context: %{public}@",
                   log: .cloudKitSync,
                   type: .error,
                   nsError.localizedDescription)

            // Rollback changes instead of crashing
            viewContext.rollback()
            os_log("⚠️ Changes rolled back due to save failure",
                   log: .cloudKitSync,
                   type: .error)

            // Post notification to inform the user
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveError"),
                    object: nil,
                    userInfo: ["error": nsError]
                )
            }
        }
    }
}

public func processDatabase(sharedData: SharedData, entries: [Entry]) {
    Task { @MainActor in
        // Guard against nil database
        guard let database = sharedData.database else {
            print("Warning: SVDB database not initialized. Skipping database processing.")
            return
        }

        // Mark as indexing and reset progress
        sharedData.isIndexing = true
        sharedData.indexingProgress = 0.0
        sharedData.indexedCount = 0

        // Filter text entries
        let textEntries = entries.filter { $0.type == EntryType.text.rawValue }
        sharedData.totalToIndex = textEntries.count

        os_log("🔍 Starting SVDB indexing of %d text entries", log: .default, type: .info, textEntries.count)

        database.clear()

        // Guard against nil embedding
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            print("Warning: NLEmbedding not available. Skipping database processing.")
            sharedData.isIndexing = false
            return
        }

        // Process in background
        await Task.detached(priority: .userInitiated) {
            var processedCount = 0

            for entry in textEntries {
                if let text = entry.content {
                    let embedded = embedding.vector(for: cleanText(text))

                    if let wordEmbedding = embedded {
                        database.addDocument(text: text, embedding: wordEmbedding)
                    }
                }

                processedCount += 1

                // Update progress every 10 entries or on last entry
                if processedCount % 10 == 0 || processedCount == textEntries.count {
                    let count = processedCount
                    let total = textEntries.count
                    await MainActor.run {
                        sharedData.indexedCount = count
                        sharedData.indexingProgress = Double(count) / Double(total)
                    }
                }
            }

            // Mark as complete
            let finalCount = processedCount
            await MainActor.run {
                sharedData.isIndexing = false
                sharedData.indexingProgress = 1.0
                os_log("✅ SVDB indexing complete: %d entries indexed", log: .default, type: .info, finalCount)
            }
        }.value
    }
}

func cleanText(_ text: String) -> String {
    var cleanText = text.replacingOccurrences(of: "\n", with: " ") // Replace newline characters with a space
    cleanText = cleanText.replacingOccurrences(of: "\r", with: " ") // Replace carriage return characters with a space
    cleanText = cleanText.replacingOccurrences(of: "#", with: "") // Remove markdown heading characters
    cleanText = cleanText.replacingOccurrences(of: "*", with: "") // Remove markdown emphasis characters
    cleanText = cleanText.replacingOccurrences(of: "_", with: "") // Remove markdown emphasis characters
    cleanText = cleanText.replacingOccurrences(of: "`", with: "") // Remove markdown code characters

    // Replace multiple spaces with a single space
    while cleanText.contains("  ") {
        cleanText = cleanText.replacingOccurrences(of: "  ", with: " ")
    }

    return cleanText.trimmingCharacters(in: .whitespacesAndNewlines) // Trim leading and trailing white spaces
}

func getAudioDuration(from audioData: Data) -> TimeInterval {
    do {
        let audioPlayer = try AVAudioPlayer(data: audioData)
        return audioPlayer.duration
    } catch {
        print("Failed to get audio duration: \(error.localizedDescription)")
        return 0
    }
}

/// Clears stuck transcribing state from entries that were interrupted during transcription
/// This can happen when the app is backgrounded or terminated before transcription completes
public func recoverStuckTranscribingEntries(_ viewContext: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "transcribing == YES")

    do {
        let stuckEntries = try viewContext.fetch(fetchRequest)

        if !stuckEntries.isEmpty {
            os_log("🔧 Found %d entries stuck in transcribing state, clearing...",
                   log: .default, type: .info, stuckEntries.count)

            for entry in stuckEntries {
                entry.transcribing = false
            }

            save(viewContext)
            os_log("✅ Cleared transcribing state from %d entries",
                   log: .default, type: .info, stuckEntries.count)
        }
    } catch {
        os_log("❌ Failed to recover stuck transcribing entries: %{public}@",
               log: .default, type: .error, error.localizedDescription)
    }
}
