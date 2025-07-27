//
//  ShareViewController.swift
//  PostPiqueShareExtension
//
//  Created by Kyle Olivo on 7/26/25.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: NSViewController {
    private let keychainService = KeychainService.shared
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if repository is configured before showing the share interface
        if keychainService.getSelectedRepository() != nil {
            setupShareView()
            
            // Delay content extraction to ensure ShareView is listening for notifications
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.extractSharedContent()
            }
        } else {
            setupErrorView()
        }
    }
    
    
    private func setupShareView() {
        let shareView = ShareView(
            onPost: { [weak self] in
                self?.completeRequest()
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )
        
        setupHostingController(with: shareView)
    }
    
    private func setupErrorView() {
        let errorView = ShareErrorView {
            self.cancelRequest()
        }
        
        setupHostingController(with: errorView)
    }
    
    private func setupHostingController<T: View>(with view: T) {
        let hostingController = NSHostingController(rootView: view)
        
        addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext,
              let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            sendError("No content to share")
            return
        }
        
        extractURL(from: extensionItems)
    }
    
    private func extractURL(from extensionItems: [NSExtensionItem]) {
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.sendError("Failed to extract URL: \(error.localizedDescription)")
                            }
                            return
                        }
                        
                        guard let url = item as? URL else {
                            DispatchQueue.main.async {
                                self.sendError("Invalid URL format")
                            }
                            return
                        }
                        
                        Task {
                            let title = await self.fetchPageTitle(from: url)
                            DispatchQueue.main.async {
                                self.sendContent(title: title, url: url.absoluteString)
                            }
                        }
                        return
                    }
                }
            }
        }
        
        sendError("No URL found in shared content")
    }
    
    private func fetchPageTitle(from url: URL) async -> String {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            return extractTitleFromHTML(html)
        } catch {
            return url.host ?? "Unknown Title"
        }
    }
    
    private func extractTitleFromHTML(_ html: String) -> String {
        let titlePattern = "<title[^>]*>([^<]+)</title>"
        
        guard let regex = try? NSRegularExpression(pattern: titlePattern, options: [.caseInsensitive]) else {
            return "Untitled"
        }
        
        let range = NSRange(location: 0, length: html.count)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let titleRange = Range(match.range(at: 1), in: html) else {
            return "Untitled"
        }
        
        let title = String(html[titleRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        
        return title.isEmpty ? "Untitled" : title
    }
    
    private func sendContent(title: String, url: String) {
        NotificationCenter.default.post(
            name: .shareDataReceived,
            object: nil,
            userInfo: [
                "url": url,
                "title": title
            ]
        )
    }
    
    private func sendError(_ message: String) {
        NotificationCenter.default.post(
            name: .shareError,
            object: nil,
            userInfo: ["error": message]
        )
    }
    
    
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func cancelRequest() {
        let error = NSError(domain: "com.postpique.shareextension", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "User cancelled sharing"
        ])
        extensionContext?.cancelRequest(withError: error)
    }
}


// MARK: - Notification Extensions
extension Notification.Name {
    static let shareDataReceived = Notification.Name("shareDataReceived")
    static let shareError = Notification.Name("shareError")
}
