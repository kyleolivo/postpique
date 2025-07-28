import Foundation
@testable import PostPique

struct MockData {
    // MARK: - GitHub User Mock Data
    static let mockUser = GitHubUser(
        id: 12345,
        login: "testuser",
        avatarUrl: "https://avatars.githubusercontent.com/u/12345?v=4",
        name: "Test User",
        email: "test@example.com"
    )
    
    static let mockUserWithoutEmail = GitHubUser(
        id: 67890,
        login: "noemailuser",
        avatarUrl: "https://avatars.githubusercontent.com/u/67890?v=4",
        name: "No Email User",
        email: nil
    )
    
    // MARK: - GitHub Repository Mock Data
    static let mockRepository = GitHubRepository(
        id: 98765,
        name: "test-repo",
        fullName: "testuser/test-repo",
        owner: GitHubOwner(login: "testuser", avatarUrl: "https://avatars.githubusercontent.com/u/12345?v=4"),
        defaultBranch: "main",
        htmlUrl: "https://github.com/testuser/test-repo",
        isPrivate: false
    )
    
    static let mockPrivateRepository = GitHubRepository(
        id: 54321,
        name: "private-repo",
        fullName: "testuser/private-repo",
        owner: GitHubOwner(login: "testuser", avatarUrl: "https://avatars.githubusercontent.com/u/12345?v=4"),
        defaultBranch: "main",
        htmlUrl: "https://github.com/testuser/private-repo",
        isPrivate: true
    )
    
    static let mockRepositories = [mockRepository, mockPrivateRepository]
    
    // MARK: - Post Content Mock Data
    static let mockPostContent = PostContent(
        quotation: "This is a test quotation from an article.",
        pageTitle: "Test Article - Example News",
        thoughts: "This is my thoughtful commentary on the article.",
        timestamp: Date(timeIntervalSince1970: 1640995200), // Jan 1, 2022
        sourceURL: "https://example.com/article"
    )
    
    static let mockPostContentWithoutURL = PostContent(
        quotation: "Another test quotation.",
        pageTitle: "Simple Title",
        thoughts: "Simple thoughts.",
        timestamp: Date(timeIntervalSince1970: 1640995200),
        sourceURL: nil
    )
    
    static let mockPostContentWithSpecialChars = PostContent(
        quotation: "Quote with \"special\" characters & symbols.",
        pageTitle: "Article with Special Characters! @#$%",
        thoughts: "Thoughts about special characters.",
        timestamp: Date(timeIntervalSince1970: 1640995200),
        sourceURL: "https://example.com/special-chars"
    )
    
    // MARK: - Device Flow Mock Data
    static let mockDeviceCodeResponse = DeviceCodeResponse(
        deviceCode: "device_code_123",
        userCode: "ABCD-1234",
        verificationURI: "https://github.com/login/device",
        verificationURIComplete: "https://github.com/login/device/continue",
        expiresIn: 900,
        interval: 5
    )
    
    // MARK: - JSON Response Mock Data
    static let mockUserJSON = """
    {
        "id": 12345,
        "login": "testuser",
        "avatar_url": "https://avatars.githubusercontent.com/u/12345?v=4",
        "name": "Test User",
        "email": "test@example.com"
    }
    """.data(using: .utf8)!
    
    static let mockRepositoriesJSON = """
    [
        {
            "id": 98765,
            "name": "test-repo",
            "full_name": "testuser/test-repo",
            "owner": {
                "login": "testuser",
                "avatar_url": "https://avatars.githubusercontent.com/u/12345?v=4"
            },
            "default_branch": "main",
            "html_url": "https://github.com/testuser/test-repo",
            "private": false
        }
    ]
    """.data(using: .utf8)!
    
    static let mockDeviceCodeJSON = """
    {
        "device_code": "device_code_123",
        "user_code": "ABCD-1234",
        "verification_uri": "https://github.com/login/device",
        "verification_uri_complete": "https://github.com/login/device/continue",
        "expires_in": 900,
        "interval": 5
    }
    """.data(using: .utf8)!
    
    // MARK: - HTML Mock Data
    static let mockHTML = """
    <html>
    <head>
        <title>Test Article - Example News</title>
    </head>
    <body>
        <p>This is a test article.</p>
    </body>
    </html>
    """
    
    static let mockHTMLWithEntities = """
    <html>
    <head>
        <title>Article with &quot;quotes&quot; &amp; entities &#8211; Test</title>
    </head>
    <body>
        <p>Test content.</p>
    </body>
    </html>
    """
}