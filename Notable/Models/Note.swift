//
//  Note.swift
//  Notable
//
//  Created by Runkai Zhang on 8/5/23.
//

import CoreTransferable

enum TemporaryFileError: Error {
    case creationFailed
}

struct Note: Transferable {
    var title: String
    var body: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .text) { note in
            var url: URL?

            do {
                // Call the function to create the temporary text file and get the URL
                url = try createTemporaryTxtFile(title: note.title, body: note.body)
                print("Temporary text file created at: \(String(describing: url))")

            } catch {
                print("Error creating temporary text file: \(error)")
            }

            return SentTransferredFile(url!)
        } importing: { _ in
            return Self.init(title: "Imported", body: "Imported Nothing")
        }
    }

    private static func createTemporaryTxtFile(title: String, body: String) throws -> URL {
        // Get the app's temporary directory URL
        guard let temporaryDirectoryURL = FileManager.default.temporaryDirectory as URL? else {
            throw TemporaryFileError.creationFailed
        }

        let temporaryTxtURL = temporaryDirectoryURL.appendingPathComponent("\(title).txt")

        do {
            // Content to be written to the temporary file
            let fileContent = body

            // Write the content to the temporary file
            try fileContent.write(to: temporaryTxtURL, atomically: true, encoding: .utf8)

            // Return the URL of the created temporary text file
            return temporaryTxtURL
        } catch {
            throw error
        }
    }
}
