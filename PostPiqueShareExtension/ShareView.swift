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
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading) {
                    Text("Save to PostPique")
                        .font(.headline)
                    Text(pageTitle.isEmpty ? "Loading..." : pageTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            // Quotation field
            VStack(alignment: .leading, spacing: 8) {
                Label("Quotation", systemImage: "text.quote")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $quotation)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Thoughts field
            VStack(alignment: .leading, spacing: 8) {
                Label("Your Thoughts", systemImage: "bubble.left")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $thoughts)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: { Task { await postContent() } }) {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Post to GitHub")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(thoughts.isEmpty || quotation.isEmpty || isPosting)
            }
        }
        .padding()
        .frame(width: 500, height: 520)
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
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Repository Not Configured")
                .font(.title2)
                .bold()
            
            Text("Please open PostPique and select a repository before sharing content.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("OK") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ShareView(onPost: {}, onCancel: {})
}

#Preview("Error View") {
    ShareErrorView(onClose: {})
}