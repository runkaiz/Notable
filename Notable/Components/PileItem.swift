//
//  PileItem.swift
//  Notable
//
//  Created by Runkai Zhang on 8/7/23.
//

import SwiftUI

struct PileItem: View {

    @State var pile: Pile

    private var colors: [Color] = [
        Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255),
        Color(red: 241 / 255, green: 113 / 255, blue: 5 / 255),
        Color(red: 160 / 255, green: 210 / 255, blue: 219 / 255)
    ]

    init(pile: Pile) {
        self.pile = pile
    }

    // Computed property for entry counts - cached per render cycle
    private var entryCounts: (texts: Int, images: Int, links: Int, recordings: Int) {
        var texts = 0
        var images = 0
        var links = 0
        var recordings = 0

        guard let entries = pile.entries?.allObjects as? [Entry] else {
            return (0, 0, 0, 0)
        }

        for entry in entries {
            switch EntryType(rawValue: entry.type ?? "") {
            case .image:
                images += 1
            case .text:
                texts += 1
            case .link:
                links += 1
            case .recording:
                recordings += 1
            default:
                break
            }
        }

        return (texts, images, links, recordings)
    }

    var body: some View {
        // Calculate counts once for the entire view
        let counts = entryCounts
        let entryCount = counts.texts + counts.images + counts.links + counts.recordings

        return VStack {
            HStack {
                if entryCount == 0 {
                    Image(systemName: "tray.fill")
                        .accessibilityLabel(String(localized: "Empty pile"))
                } else {
                    Image(systemName: "tray.full.fill")
                        .accessibilityLabel(String(localized: "Pile with entries"))
                }
                Text(pile.name ?? "")
                Spacer()
                if let tagColor = pile.tag {
                    switch tagColor {
                    case "Raisin Black":
                        Circle().fill(colors[0]).frame(width: 10, height: 10)
                            .accessibilityLabel(String(localized: "Black tag"))
                    case "Safety Orange":
                        Circle().fill(colors[1]).frame(width: 10, height: 10)
                            .accessibilityLabel(String(localized: "Orange tag"))
                    case "Non Photo Blue":
                        Circle().fill(colors[2]).frame(width: 10, height: 10)
                            .accessibilityLabel(String(localized: "Blue tag"))
                    default:
                        EmptyView()
                    }
                }
            }
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "text.word.spacing")
                    Text(counts.texts.description)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "\(counts.texts) text entries"))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                    Text(counts.images.description)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "\(counts.images) image entries"))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text(counts.recordings.description)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "\(counts.recordings) voice memo entries"))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text(counts.links.description)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "\(counts.links) link entries"))
            }
        }
    }
}
