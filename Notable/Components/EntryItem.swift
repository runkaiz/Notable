//
//  EntryItem.swift
//  Notable
//
//  Created by Runkai Zhang on 7/5/23.
//

import CoreData
import LinkPresentation
import SwiftUI

// MARK: - EntryType

enum EntryType: String {
    case text
    case image
    case recording
    case link
}

// MARK: - LinkMetadata

class LinkMetadataLoader: ObservableObject {
    @Published var metadata: LPLinkMetadata?
    @Published var image: UIImage?

    private var metadataProvider: LPMetadataProvider?
    private var hasStartedFetching = false
    private var currentURL: URL?

    func loadMetadata(for url: URL) {
        // Don't fetch if we've already started fetching for this URL
        guard !hasStartedFetching || currentURL != url else { return }

        // Cancel any existing fetch before starting a new one
        if metadataProvider != nil {
            metadataProvider?.cancel()
        }

        // Create a new provider for this fetch
        metadataProvider = LPMetadataProvider()
        hasStartedFetching = true
        currentURL = url

        metadataProvider?.startFetchingMetadata(for: url) { [weak self] metadata, error in
            guard let self = self else { return }

            if let error = error {
                print("Link metadata error: \(error)")
                return
            }

            DispatchQueue.main.async {
                self.metadata = metadata

                // Extract image from metadata
                if let imageProvider = metadata?.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.image = image
                            }
                        }
                    }
                }
            }
        }
    }

    func cancel() {
        metadataProvider?.cancel()
        metadataProvider = nil
    }
}

// MARK: - EntryItem

struct EntryItem: View {
    @ObservedObject var entry: Entry

    @State var image: UIImage
    @StateObject private var linkLoader = LinkMetadataLoader()

    var type: EntryType

    init(entry: Entry) {
        self.entry = entry
        type = EntryType(rawValue: entry.type ?? EntryType.text.rawValue) ?? .text

        _image = State(initialValue: UIImage(data: entry.image ?? Data()) ?? UIImage())
    }

    @State var isSafariPresented = false

    var body: some View {
        switch type {
        case .link:
            Button(action: {
                isSafariPresented = true
            }) {
                HStack(spacing: 12) {
                    // Preview image
                    Group {
                        if let previewImage = linkLoader.image {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                Color(UIColor.tertiarySystemFill)
                                Image(systemName: "link")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(width: 70, height: 70)
                    .cornerRadius(8)
                    .clipped()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(linkLoader.metadata?.title ?? entry.title ?? "Link")
                            .fontDesign(.monospaced)
                            .lineLimit(2)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if let description = linkLoader.metadata?.url?.host {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text(entry.link?.SLD ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .onAppear {
                if let link = entry.link {
                    linkLoader.loadMetadata(for: link)
                }
            }
            .onDisappear {
                linkLoader.cancel()
            }
            .fullScreenCover(isPresented: $isSafariPresented) {
                if let link = entry.link {
                    SafariView(url: link)
                        .ignoresSafeArea()
                }
            }
        case .recording:
            if let audioData = entry.audio {
                AudioEntryPlayer(
                    entry: entry,
                    audioData: audioData,
                    timestamp: entry.timestamp ?? Date()
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            } else {
                EmptyView()
            }
        case .image:
            VStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                HStack {
                    Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()

                    let width = Int(image.size.width * image.scale)
                    let height = Int(image.size.height * image.scale)
                    Text("\(width) × \(height)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        case .text:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if entry.isMarkdown {
                        Image(systemName: "text.word.spacing")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "apple.terminal.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    Text(entry.title ?? "")
                        .font(.subheadline)
                }
                Text(entry.content?.replacingOccurrences(of: "\n", with: " ") ?? "")
                    .lineLimit(3)
                    .font(.body)
                    .fontWeight(.light)
                    .fontDesign(.monospaced)
                Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                    .font(.footnote)
            }
            .padding(.vertical, 4)
        }
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

extension URL {
    /// second-level domain [SLD]
    ///
    /// i.e. `msk.ru, spb.ru`
    var SLD: String? {
        return host?.components(separatedBy: ".").suffix(2).joined(separator: ".")
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
