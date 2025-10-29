//
//  Persistence.swift
//  Notable
//
//  Created by Runkai Zhang on 6/29/23.
//

import CoreData
import os.log

// CloudKit sync logger
extension OSLog {
    static let cloudKitSync = OSLog(subsystem: "xyz.runkaizhang.notable", category: "CloudKitSync")
}

// Observable sync state tracker
class CloudKitSyncState: ObservableObject {
    static let shared = CloudKitSyncState()

    @Published var lastSuccessfulSync: Date?
    @Published var lastSyncError: Error?
    @Published var isCurrentlySyncing = false

    private init() {}

    func recordSuccess(type: String) {
        DispatchQueue.main.async {
            self.lastSuccessfulSync = Date()
            self.lastSyncError = nil
            self.isCurrentlySyncing = false
        }
    }

    func recordError(_ error: Error) {
        DispatchQueue.main.async {
            self.lastSyncError = error
            self.isCurrentlySyncing = false
        }
    }

    func recordSyncStart() {
        DispatchQueue.main.async {
            self.isCurrentlySyncing = true
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let newPile = Pile(context: viewContext)
        newPile.id = UUID()
        newPile.name = "Example Pile"
        newPile.desc = "Example description for an example pile"
        newPile.tag = "Non Photo Blue"

        for _ in 0..<10 {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.id = UUID()
            newEntry.title = "Test"
            newEntry.content = "# lalala\nlalalal"
            newEntry.isMarkdown = true
            newEntry.language = "markdown"
            newEntry.type = EntryType.text.rawValue

//            newPile.addToEntries(newEntry)
        }
        do {
            try viewContext.save()
        } catch {
            // Log preview save error but don't crash - preview data is not critical
            let nsError = error as NSError
            os_log("⚠️ Preview save failed: %{public}@", log: .cloudKitSync, type: .error, nsError.localizedDescription)
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Notable")
        if inMemory {
            guard let description = container.persistentStoreDescriptions.first else {
                os_log("⚠️ No persistent store description found for in-memory setup", log: .cloudKitSync, type: .error)
                return
            }
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            os_log("❌ CRITICAL: No persistent store description found in container", log: .cloudKitSync, type: .fault)
            fatalError("Failed to retrieve persistent store description. This indicates a CoreData configuration error.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        os_log("🔧 Setting up CloudKit sync...", log: .cloudKitSync, type: .info)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                os_log("❌ CRITICAL: Failed to load persistent stores: %{public}@", log: .cloudKitSync, type: .fault, error.localizedDescription)
                os_log("❌ Error domain: %{public}@, code: %d", log: .cloudKitSync, type: .fault, error.domain, error.code)
                os_log("❌ User info: %{public}@", log: .cloudKitSync, type: .fault, String(describing: error.userInfo))

                // Post notification so the app can show an error UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PersistentStoreLoadError"),
                        object: nil,
                        userInfo: ["error": error]
                    )
                }

                // This is a critical error - app cannot function without persistent store
                // Keep fatalError but with improved logging above
                fatalError("Failed to load CoreData persistent stores. Error: \(error.localizedDescription)")
            } else {
                os_log("✅ Persistent stores loaded successfully", log: .cloudKitSync, type: .info)
                os_log("📍 Store URL: %{public}@", log: .cloudKitSync, type: .debug, storeDescription.url?.absoluteString ?? "unknown")
            }
        })

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Set up CloudKit event notifications
        setupCloudKitNotifications()

        os_log("🔄 CloudKit sync configured with merge policy: NSMergeByPropertyObjectTrumpMergePolicy", log: .cloudKitSync, type: .info)
    }

    private func setupCloudKitNotifications() {
        // Listen for CloudKit import events
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                logCloudKitEvent(event)
            }
        }

        os_log("👂 CloudKit event notifications registered", log: .cloudKitSync, type: .info)
    }
}

// CloudKit event logging
private func logCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
    let eventType: String
    switch event.type {
    case .setup:
        eventType = "Setup"
    case .import:
        eventType = "Import"
    case .export:
        eventType = "Export"
    @unknown default:
        eventType = "Unknown"
    }

    // Record sync start
    if event.endDate == nil {
        CloudKitSyncState.shared.recordSyncStart()
    }

    os_log("☁️ CloudKit Event: %{public}@ - Started: %{public}@",
           log: .cloudKitSync,
           type: .info,
           eventType,
           event.startDate.description)

    if let endDate = event.endDate {
        let duration = endDate.timeIntervalSince(event.startDate)
        os_log("⏱️ Event completed in %.2f seconds", log: .cloudKitSync, type: .debug, duration)
    }

    if event.succeeded {
        os_log("✅ %{public}@ succeeded", log: .cloudKitSync, type: .info, eventType)
        CloudKitSyncState.shared.recordSuccess(type: eventType)
    } else if let error = event.error {
        os_log("❌ %{public}@ failed: %{public}@",
               log: .cloudKitSync,
               type: .error,
               eventType,
               error.localizedDescription)
        CloudKitSyncState.shared.recordError(error)
    }
}
