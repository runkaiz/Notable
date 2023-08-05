//
//  EntryItem.swift
//  Notable
//
//  Created by Runkai Zhang on 7/5/23.
//

import SwiftUI
import CoreData

enum EntryType: String {
    case text
    case image
    case recording
}

struct EntryItem: View {
    @ObservedObject var entry: Entry
    var type: EntryType

    @State var image: UIImage

    init(entry: Entry) {
        self.entry = entry
        self.type = EntryType(rawValue: entry.type ?? "text")!

        image = UIImage(data: entry.image ?? Data()) ?? UIImage()
    }

    @State var isImagePopoverPresented = false

    var body: some View {
        switch type {
        case .recording:
            // To be implemented
            EmptyView()
        case .image:
            Section {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    HStack {
                        Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                            .font(.subheadline)
                        Spacer()
                        Button(action: {
                            isImagePopoverPresented.toggle()
                        }, label: {
                            Image(systemName: "info.circle")
                        })
                        .popover(isPresented: $isImagePopoverPresented) {
                            let width = Int(image.size.width * image.scale)
                            let height = Int(image.size.height * image.scale)
                            Text(
                                "Image resolution: \(width) * \(height)"
                            )
                            .frame(minWidth: 200, maxHeight: 400)
                            .presentationCompactAdaptation(.popover)
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .listRowInsets(EdgeInsets())
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.word.spacing")
                    Text(entry.title ?? "")
                }
                Text(entry.content?.replacingOccurrences(of: "\n", with: " ") ?? "")
                    .lineLimit(3)
                    .font(.body)
                Text(entry.timestamp ?? Date(), formatter: entryFormatter)
                    .font(.footnote)
            }
            .padding(.vertical, 6)
        }
    }
}

private let entryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
