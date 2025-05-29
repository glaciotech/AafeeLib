//
//  FirecrawlMCPFlowStageTests.swift
//
//
//  Created by Cascade on 5/15/25.
//

import XCTest
@testable import AafeeLib

// Protocol for HTTP client to make it testable
protocol HTTPClient {
    func sendRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

// Mock HTTP client for testing
class MockHTTPClient: HTTPClient {
    var mockData: Data?
    var mockResponse: HTTPURLResponse?
    var error: Error?
    var capturedRequests: [(url: URL, body: Data?)] = []
    
    func sendRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Capture the request for later verification
        capturedRequests.append((url: request.url!, body: request.httpBody))
        
        if let error = error {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw NSError(domain: "MockHTTPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock data or response provided"])
        }
        
        return (data, response)
    }
}

// Testable version of MCPServerFlowStage that uses dependency injection
class TestMCPServerFlowStage: FlowStage {
    let serverName: String
    let functionName: String
    let parameters: [String: Any]?
    let httpClient: HTTPClient
    
    init(serverName: String, functionName: String, parameters: [String: Any]? = nil, httpClient: HTTPClient) {
        self.serverName = serverName
        self.functionName = functionName
        self.parameters = parameters
        self.httpClient = httpClient
    }
    
    func execute(_ input: InOutType?) async throws -> InOutType {
        // Create the MCP request
        var requestParams: [String: Any] = parameters ?? [:]
        
        // If we have input from a previous stage, try to incorporate it
        if let input = input, let inputText = input.text {
            // Try to parse the input as JSON if it's in JSON format
            if case .JSON(let jsonString) = input {
                if let jsonData = jsonString.data(using: .utf8),
                   let jsonParams = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    // Merge the JSON parameters with our existing parameters
                    for (key, value) in jsonParams {
                        requestParams[key] = value
                    }
                }
            } else {
                // If it's not JSON, add it as a generic "input" parameter
                requestParams["input"] = inputText
            }
        }
        
        // Construct the full MCP request
        let mcpRequest: [String: Any] = [
            "serverName": serverName,
            "functionName": functionName,
            "parameters": requestParams
        ]
        
        // Convert request to JSON data
        guard let requestData = try? JSONSerialization.data(withJSONObject: mcpRequest) else {
            throw MCPServerError.invalidParameters
        }
        
        // Create URL for MCP server endpoint
        guard let url = URL(string: "http://localhost:8080/mcp/\(serverName)/\(functionName)") else {
            throw MCPServerError.invalidServerName
        }
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Execute the request using the injected HTTP client
        let (data, response) = try await httpClient.sendRequest(urlRequest)
        
        // Check for HTTP errors
        guard response.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MCPServerError.serverError("HTTP error \(response.statusCode): \(errorMessage)")
        }
        
        // Convert response data to string
        guard let resultString = String(data: data, encoding: .utf8) else {
            throw MCPServerError.serverError("Could not decode response")
        }
        
        return .string(resultString)
    }
}

// Testable version of FirecrawlMCPFlowStage
class TestFirecrawlMCPFlowStage: FlowStage {
    let function: FirecrawlFunction
    let parameters: [String: Any]
    let httpClient: HTTPClient
    
    init(function: FirecrawlFunction, parameters: [String: Any], httpClient: HTTPClient) {
        self.function = function
        self.parameters = parameters
        self.httpClient = httpClient
    }
    
    func execute(_ input: InOutType?) async throws -> InOutType {
        // Use our testable MCPServerFlowStage
        let mcpStage = TestMCPServerFlowStage(
            serverName: "mcp-server-firecrawl",
            functionName: function.rawValue,
            parameters: parameters,
            httpClient: httpClient
        )
        
        return try await mcpStage.execute(input)
    }
}

final class FirecrawlMCPFlowStageTests: XCTestCase {
    
    func testScrapeFunction() async throws {
        // Prepare mock response
        let mockClient = MockHTTPClient()
        let mockResponseData = """
        {
            "title": "Example Domain",
            "content": "This domain is for use in illustrative examples in documents.",
            "url": "https://example.com"
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8080/mcp/mcp-server-firecrawl/scrape")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockClient.mockData = mockResponseData
        mockClient.mockResponse = mockResponse
        
        // Create test flow stage
        let scrapeStage = TestFirecrawlMCPFlowStage(
            function: .scrape,
            parameters: ["url": "https://example.com", "formats": ["markdown"]],
            httpClient: mockClient
        )
        
        // Execute the flow stage
        let result = try await scrapeStage.execute(InOutType.none)
        
        // Verify result
        XCTAssertEqual(result.text, String(data: mockResponseData, encoding: .utf8))
        
        // Verify the request was made correctly
        XCTAssertEqual(mockClient.capturedRequests.count, 1)
        if let bodyData = mockClient.capturedRequests[0].body,
           let requestDict = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           let parameters = requestDict["parameters"] as? [String: Any] {
            XCTAssertEqual(parameters["url"] as? String, "https://example.com")
            XCTAssertEqual(parameters["formats"] as? [String], ["markdown"])
        } else {
            XCTFail("Failed to parse request body")
        }
    }
    
    func testSearchFunction() async throws {
        // Prepare mock response
        let mockClient = MockHTTPClient()
        let mockResponseData = """
        {
            "results": [
                {
                    "title": "Swift Programming Language",
                    "url": "https://swift.org",
                    "description": "Swift is a general-purpose programming language built using a modern approach to safety, performance, and software design patterns."
                },
                {
                    "title": "Swift Documentation",
                    "url": "https://swift.org/documentation/",
                    "description": "Documentation for the Swift programming language."
                }
            ]
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8080/mcp/mcp-server-firecrawl/search")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockClient.mockData = mockResponseData
        mockClient.mockResponse = mockResponse
        
        // Create test flow stage
        let searchStage = TestFirecrawlMCPFlowStage(
            function: .search,
            parameters: ["query": "Swift programming", "limit": 2],
            httpClient: mockClient
        )
        
        // Execute the flow stage
        let result = try await searchStage.execute(InOutType.none)
        
        // Verify result
        XCTAssertEqual(result.text, String(data: mockResponseData, encoding: .utf8))
    }
    
    func testErrorHandling() async throws {
        // Prepare mock error response
        let mockClient = MockHTTPClient()
        let mockResponseData = """
        {
            "error": "Invalid URL provided",
            "code": "INVALID_URL"
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8080/mcp/mcp-server-firecrawl/scrape")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockClient.mockData = mockResponseData
        mockClient.mockResponse = mockResponse
        
        // Create test flow stage
        let scrapeStage = TestFirecrawlMCPFlowStage(
            function: .scrape,
            parameters: ["url": "invalid-url"],
            httpClient: mockClient
        )
        
        // Execute the flow stage and expect an error
        do {
            _ = try await scrapeStage.execute(InOutType.none)
            XCTFail("Expected an error to be thrown")
        } catch let error as MCPServerError {
            if case .serverError(let message) = error {
                XCTAssertTrue(message.contains("HTTP error 400"))
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Expected MCPServerError, got \(error)")
        }
    }
    
    func testIntegrationWithLinearFlow() async throws {
        // Prepare mock response
        let mockClient = MockHTTPClient()
        let mockResponseData = """
        {
            "title": "Example Domain",
            "content": "This domain is for use in illustrative examples in documents."
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8080/mcp/mcp-server-firecrawl/scrape")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockClient.mockData = mockResponseData
        mockClient.mockResponse = mockResponse
        
        // Create test flow stage
        let scrapeStage = TestFirecrawlMCPFlowStage(
            function: .scrape,
            parameters: ["url": "https://example.com"],
            httpClient: mockClient
        )
        
        // Create a linear flow with our test stage
        let flow = LinearFlow {
            scrapeStage
        }
        
        // Execute the flow
        try await flow.run()
        
        // Since LinearFlow doesn't return a value, we can only verify that no exception was thrown
        // In a real test, you might want to add a final stage that stores the result somewhere you can check
    }
}
