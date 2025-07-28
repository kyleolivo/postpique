import SwiftUI

struct ShareView: View {
    @State private var pageTitle = ""
    @State private var sourceURL = ""
    @State private var thoughts = ""
    @State private var quotation = ""
    @State private var isPosting = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    let onPost: () -> Void
    let onCancel: () -> Void
    
    private let keychainService = KeychainService.shared
    private let githubAPI = GitHubAPIService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Beautiful header with gradient background
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                    }
                    
                    Text("PostPique")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.windowBackgroundColor)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Main content area
            VStack(spacing: 24) {
                // Elegant quotation section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Quotation")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                            )
                            .frame(height: 85)
                        
                        TextEditor(text: $quotation)
                            .font(.system(size: 13, design: .default))
                            .padding(14)
                            .frame(height: 85)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                        
                        if quotation.isEmpty {
                            Text("Enter a meaningful quote from the article...")
                                .font(.system(size: 13))
                                .foregroundColor(Color(NSColor.placeholderTextColor))
                                .padding(.top, 18)
                                .padding(.leading, 18)
                                .allowsHitTesting(false)
                        }
                    }
                }
                
                // Elegant thoughts section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("Your Thoughts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                            )
                            .frame(height: 85)
                        
                        TextEditor(text: $thoughts)
                            .font(.system(size: 13, design: .default))
                            .padding(14)
                            .frame(height: 85)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                        
                        if thoughts.isEmpty {
                            Text("Share your insights and reflections...")
                                .font(.system(size: 13))
                                .foregroundColor(Color(NSColor.placeholderTextColor))
                                .padding(.top, 18)
                                .padding(.leading, 18)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            
            // Beautiful button area
            VStack(spacing: 0) {
                Divider()
                    .background(Color(NSColor.separatorColor).opacity(0.6))
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.escape)
                    
                    if canPost {
                        Button(action: { Task { await postContent() } }) {
                            HStack(spacing: 8) {
                                if isPosting {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                Text(isPosting ? "Posting..." : "Post")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.return)
                    } else {
                        Button(action: { Task { await postContent() } }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Post")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(true)
                        .keyboardShortcut(.return)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .shareDataReceived)) { notification in
            if let url = notification.userInfo?["url"] as? String {
                sourceURL = url
            }
            if let title = notification.userInfo?["title"] as? String {
                pageTitle = title
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .shareError)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                errorMessage = error
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canPost: Bool {
        !thoughts.isEmpty && !quotation.isEmpty && !isPosting
    }
    
    private func postContent() async {
        guard let repository = keychainService.getSelectedRepository(),
              !thoughts.isEmpty && !quotation.isEmpty else {
            errorMessage = "Please provide both a quotation and your thoughts."
            showError = true
            return
        }
        
        isPosting = true
        
        let content = PostContent(
            quotation: quotation,
            pageTitle: pageTitle,
            thoughts: thoughts,
            timestamp: Date(),
            sourceURL: sourceURL.isEmpty ? nil : sourceURL
        )
        
        do {
            try await githubAPI.createPost(content, in: repository)
            isPosting = false
            onPost()
        } catch {
            isPosting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct ShareErrorView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                
                VStack(spacing: 8) {
                    Text("Repository Not Configured")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Please open PostPique and select a repository before sharing content.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Button("OK") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding(32)
        .frame(width: 320, height: 220)
        .background(Color(NSColor.windowBackgroundColor))
    }
}