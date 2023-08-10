//
//  Action.swift
//  Notable
//
//  Created by Runkai Zhang on 8/10/23.
//

import UIKit

enum ActionType: String {
    case newEntry = "NewEntry"
}

enum Action: Equatable {
    case newEntry
    
    init?(shortcutItem: UIApplicationShortcutItem) {
        guard let type = ActionType(rawValue: shortcutItem.type) else {
            return nil
        }
        
        switch type {
        case .newEntry:
            self = .newEntry
        }
    }
}

class ActionService: ObservableObject {
    static let shared = ActionService()
    
    @Published var action: Action?
}
