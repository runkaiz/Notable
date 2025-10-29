//
//  SafariView.swift
//  Notable
//
//  Created by Runkai Zhang on 10/27/25.
//

import SafariServices
import SwiftUI

/// SwiftUI wrapper for SFSafariViewController with reader mode enabled by default
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredBarTintColor = UIColor.systemBackground
        controller.preferredControlTintColor = UIColor.tintColor
        controller.dismissButtonStyle = .close

        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
