import Foundation

class GitHubAPIService {
    static let shared = GitHubAPIService()
    
    private let baseURL = "https://api.github.com"
    private let keychainService = KeychainService.shared
    
    private init() {}
    
    // MARK: - Private Helper Methods
    private func createRequest(for endpoint: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw PostPiqueError.invalidURL
        }
        
        let accessToken = try keychainService.getAccessToken()
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("PostPique/1.0", forHTTPHeaderField: "User-Agent")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        return request
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, expectedType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostPiqueError.requestFailed("Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostPiqueError.requestFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PostPiqueError.decodingError
        }
    }
    
    // MARK: - User API
    func getCurrentUser() async throws -> GitHubUser {
        let request = try createRequest(for: "/user")
        return try await performRequest(request, expectedType: GitHubUser.self)
    }
    
    // MARK: - Repository API
    func getUserRepositories() async throws -> [GitHubRepository] {
        let request = try createRequest(for: "/user/repos?type=all&sort=updated&per_page=100")
        return try await performRequest(request, expectedType: [GitHubRepository].self)
    }
    
    // MARK: - Post Creation
    func createPost(_ postContent: PostContent, in repository: GitHubRepository) async throws {
        let path = "_posts/\(postContent.filename)"
        let endpoint = "/repos/\(repository.fullName)/contents/\(path)"
        
        let fileContent: [String: Any] = [
            "message": "Add new post: \(postContent.pageTitle)",
            "content": Data(postContent.markdownContent.utf8).base64EncodedString(),
            "branch": repository.defaultBranch
        ]
        
        let body = try JSONSerialization.data(withJSONObject: fileContent)
        let request = try createRequest(for: endpoint, method: "PUT", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostPiqueError.requestFailed("Invalid response from GitHub")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostPiqueError.requestFailed("Failed to create post: \(errorMessage)")
        }
    }
}