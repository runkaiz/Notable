//
//  AcknowledgeView.swift
//  Notable
//
//  Created by Runkai Zhang on 7/14/23.
//

import SwiftUI
import AcknowList

struct AcknowledgeView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AcknowListViewController
    
    func makeUIViewController(context: Context) -> AcknowListViewController {
        let vc = AcknowListViewController(acknowledgements: AcknowParser.defaultAcknowList()!.acknowledgements, style: .insetGrouped)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AcknowListViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

struct AcknowledgeView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowledgeView()
    }
}
