//
//  ShareViewController.swift
//  PostPiqueShareExtension
//
//  Created by Kyle Olivo on 7/26/25.
//

#if os(macOS)
import Cocoa
typealias PlatformViewController = NSViewController
typealias PlatformNibName = NSNib.Name
typealias PlatformHostingController = NSHostingController
#else
import UIKit
typealias PlatformViewController = UIViewController
typealias PlatformNibName = String
typealias PlatformHostingController = UIHostingController
#endif
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: PlatformViewController {
    private let keychainService = KeychainService.shared
    
    override init(nibName nibNameOrNil: PlatformNibName?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if repository is configured before showing the share interface
        if keychainService.getSelectedRepository() != nil {
            // Check content type before showing share view
            checkContentType()
        } else {
            setupErrorView()
        }
    }
    
#if os(macOS)
    override func viewDidAppear() {
        super.viewDidAppear()
        // Don't re-extract content on macOS - it's already handled in viewDidLoad
    }
#else
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Don't re-extract content on iOS - it's already handled in viewDidLoad
    }
#endif
    
    
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
    
    private func setupTextSelectionErrorView() {
        let errorView = TextSelectionErrorView {
            self.cancelRequest()
        }
        
        setupHostingController(with: errorView)
    }
    
    private func setupHostingController<T: View>(with view: T) {
        let hostingController = PlatformHostingController(rootView: view)
        
        addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
#if os(macOS)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
#else
        hostingController.view.frame = self.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
#endif
    }
    
    private func checkContentType() {
        guard let extensionContext = extensionContext else {
            setupShareView()
            sendError("Extension context not available")
            return
        }
        
        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem],
              !extensionItems.isEmpty else {
            setupShareView()
            sendError("No content to share")
            return
        }
        
        // Check if this is a proper URL share from Safari's share button
        // Safari provides URLs with specific type identifiers when sharing from the share button
        var hasURLAttachment = false
        
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments, !attachments.isEmpty else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    hasURLAttachment = true
                    break
                }
            }
            if hasURLAttachment { break }
        }
        
        if hasURLAttachment {
            // This is a URL share, proceed normally
            setupShareView()
            extractSharedContent()
        } else {
            // This is likely text selection, show error
            setupTextSelectionErrorView()
        }
    }
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext else {
            sendError("Extension context not available")
            return
        }
        
        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem],
              !extensionItems.isEmpty else {
            sendError("No content to share")
            return
        }
        
        extractURL(from: extensionItems)
    }
    
    private func extractURL(from extensionItems: [NSExtensionItem]) {
        var urlFound = false
        
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments, !attachments.isEmpty else { continue }
            
            for attachment in attachments {
                // Try URL first
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    urlFound = true
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            if let error = error {
                                self.sendError("Failed to extract URL: \(error.localizedDescription)")
                                return
                            }
                            
                            // Handle different types of URL items
                            var url: URL?
                            
                            if let directURL = item as? URL {
                                url = directURL
                            } else if let urlString = item as? String {
                                url = URL(string: urlString)
                            } else if let nsString = item as? NSString {
                                url = URL(string: nsString as String)
                            } else if let data = item as? Data {
                                // Sometimes URLs come as data
                                if let urlString = String(data: data, encoding: .utf8) {
                                    url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines))
                                }
                            }
                            
                            guard let finalURL = url else {
                                self.sendError("Could not parse URL from shared content")
                                return
                            }
                            
                            Task {
                                let title = await self.fetchPageTitle(from: finalURL)
                                DispatchQueue.main.async {
                                    self.sendContent(title: title, url: finalURL.absoluteString)
                                }
                            }
                        }
                    }
                    return // Found URL, exit early
                }
                
                // Fallback: try plain text that might contain a URL
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    urlFound = true
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            if let error = error {
                                self.sendError("Failed to extract text: \(error.localizedDescription)")
                                return
                            }
                            
                            var urlString: String?
                            
                            if let text = item as? String {
                                urlString = text
                            } else if let nsString = item as? NSString {
                                urlString = nsString as String
                            }
                            
                            guard let text = urlString else {
                                self.sendError("No text found in shared content")
                                return
                            }
                            
                            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard let url = URL(string: trimmedText) else {
                                // User likely selected text instead of sharing the webpage
                                self.sendError("To share a webpage, please use Safari's share button from the webpage itself, not from selected text.")
                                return
                            }
                            
                            Task {
                                let title = await self.fetchPageTitle(from: url)
                                DispatchQueue.main.async {
                                    self.sendContent(title: title, url: url.absoluteString)
                                }
                            }
                        }
                    }
                    return // Found text, exit early
                }
            }
        }
        
        if !urlFound {
            sendError("No URL found in shared content")
        }
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
            .replacingOccurrences(of: "&#8211;", with: "–")  // en dash
            .replacingOccurrences(of: "&#8212;", with: "—")  // em dash
            .replacingOccurrences(of: "&ndash;", with: "–")   // en dash
            .replacingOccurrences(of: "&mdash;", with: "—")   // em dash
            .replacingOccurrences(of: "&rsquo;", with: "\u{2019}")   // right single quote
            .replacingOccurrences(of: "&lsquo;", with: "\u{2018}")   // left single quote
            .replacingOccurrences(of: "&rdquo;", with: "\u{201D}")   // right double quote
            .replacingOccurrences(of: "&ldquo;", with: "\u{201C}")   // left double quote
        
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
