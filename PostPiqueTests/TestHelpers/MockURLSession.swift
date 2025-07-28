import Foundation

class MockURLSession: URLSession {
    var mockResponse: (Data?, URLResponse?, Error?)?
    var capturedRequest: URLRequest?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequest = request
        
        if let error = mockResponse?.2 {
            throw error
        }
        
        let data = mockResponse?.0 ?? Data()
        let response = mockResponse?.1 ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    func setMockResponse(data: Data?, response: URLResponse?, error: Error?) {
        mockResponse = (data, response, error)
    }
    
    func setMockHTTPResponse(data: Data?, statusCode: Int, url: URL? = nil) {
        let response = HTTPURLResponse(
            url: url ?? URL(string: "https://api.github.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        mockResponse = (data, response, nil)
    }
}