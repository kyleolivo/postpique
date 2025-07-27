import Foundation

// MARK: - Post Content Model
struct PostContent: Codable {
    let quotation: String
    let pageTitle: String
    let thoughts: String
    let timestamp: Date
    let sourceURL: String?
    
    var markdownContent: String {
        let titleWithEmoji = "🔗 \(pageTitle.replacingOccurrences(of: "\"", with: "\\\""))"
        
        var content = """
        ---
        title: "\(titleWithEmoji)"
        excerpt_separator: "<!--more-->"
        tags:
          - quotes
        ---
        > \(quotation)
        
        \(thoughts)
        """
        
        // Add link to original article if we have a source URL
        if let sourceURL = sourceURL, !sourceURL.isEmpty {
            content += "\n\n[Full article](\(sourceURL))"
        }
        
        return content
    }
    
    var filename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: timestamp)
        let safeTitle = pageTitle
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            .prefix(50) // Limit length
        return "\(dateString)-\(safeTitle).md"
    }
}

// MARK: - GitHub Models
struct GitHubUser: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let name: String?
    let email: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, login, name, email
        case avatarUrl = "avatar_url"
    }
}

struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let owner: GitHubOwner
    let defaultBranch: String
    let htmlUrl: String
    let isPrivate: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, owner
        case fullName = "full_name"
        case defaultBranch = "default_branch"
        case htmlUrl = "html_url"
        case isPrivate = "private"
    }
}

struct GitHubOwner: Codable {
    let login: String
    let avatarUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Device Flow Response
struct DeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    let verificationURIComplete: String?
    let expiresIn: Int
    let interval: Int
    
    private enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURI = "verification_uri"
        case verificationURIComplete = "verification_uri_complete"
        case expiresIn = "expires_in"
        case interval
    }
}

// MARK: - API Errors
enum PostPiqueError: Error, LocalizedError {
    case noAccessToken
    case invalidURL
    case requestFailed(String)
    case decodingError
    case keychainError(String)
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "Please sign in again"
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .keychainError(let message):
            return message
        case .authenticationFailed(let message):
            return message
        }
    }
}