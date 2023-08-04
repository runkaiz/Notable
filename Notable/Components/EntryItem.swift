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
        case .image:
            Section {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .listRowInsets(EdgeInsets())
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
                            Text("Image resolution: \(Int(image.size.width * image.scale)) * \(Int(image.size.height * image.scale))")
                                .frame(minWidth: 200, maxHeight: 400)
                                .presentationCompactAdaptation(.popover)
                                .padding()
                        }
                }
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
