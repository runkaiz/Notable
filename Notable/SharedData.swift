//
//  SharedData.swift
//  Notable
//
//  Created by Runkai Zhang on 9/24/23.
//

import Foundation
import CLIPKit
import SVDB

public class SharedData: ObservableObject {
    @Published var clip: CLIPKit = CLIPKit()
    @Published var textModelLoaded: Bool = false
    @Published var database: Collection? = nil
        
    init() {
        self.database = try? SVDB.shared.collection("entries")
    }
}
