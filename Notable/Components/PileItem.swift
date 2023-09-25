//
//  PileItem.swift
//  Notable
//
//  Created by Runkai Zhang on 8/7/23.
//

import SwiftUI

struct PileItem: View {
    
    @State var pile: Pile
    
    @State var numOfTexts = 0
    @State var numOfImages = 0
    @State var numOfLinks = 0
    
    private var colors: [Color] = [
        Color(red: 39/255, green: 39/255, blue: 39/255),
        Color(red: 241/255, green: 113/255, blue: 5/255),
        Color(red: 160/255, green: 210/255, blue: 219/255)
    ]
    
    init(pile: Pile) {
        self.pile = pile
    }
    
    var body: some View {
        VStack {
            HStack {
                if pile.entries!.count == 0 {
                    Image(systemName: "tray.fill")
                } else {
                    Image(systemName: "tray.full.fill")
                }
                Text(pile.name ?? "")
                Spacer()
                if let tagColor = pile.tag {
                    switch tagColor {
                    case "Raisin Black":
                        Circle().fill(colors[0]).frame(width: 10, height: 10)
                    case "Safety Orange":
                        Circle().fill(colors[1]).frame(width: 10, height: 10)
                    case "Non Photo Blue":
                        Circle().fill(colors[2]).frame(width: 10, height: 10)
                    default:
                        EmptyView()
                    }
                }
            }
            HStack {
                Image(systemName: "text.word.spacing")
                Text(numOfTexts.description)
                Spacer()
                Image(systemName: "photo")
                Text(numOfImages.description)
                Spacer()
                Image(systemName: "link")
                Text(numOfLinks.description)
            }
            .onAppear {
                for entry in pile.entries?.allObjects as! [Entry] {
                    switch EntryType(rawValue: entry.type!) {
                    case .image:
                        numOfImages += 1
                    case .text:
                        numOfTexts += 1
                    case .link:
                        numOfLinks += 1
                    default:
                        break
                    }
                }
            }
        }
    }
}
