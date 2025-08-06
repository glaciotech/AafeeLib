//
//  FirecrawlMCPIntegrationTests.swift
//
//
//  Created by Cascade on 5/15/25.
//

import XCTest
@testable import AafeeLib

/// Integration tests for the Firecrawl MCP server
/// These tests actually call the real MCP server and verify the responses
/// Note: These tests require the Firecrawl MCP server to be running and accessible
final class FirecrawlMCPIntegrationTests: XCTestCase {
    
    // Skip these tests if the environment variable is not set
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Skip integration tests if environment variable is not set
        // This allows us to skip these tests in CI environments where the MCP server might not be available
        continueAfterFailure = false
        let runIntegrationTests = ProcessInfo.processInfo.environment["RUN_MCP_INTEGRATION_TESTS"] == "1"
        if !runIntegrationTests {
            throw XCTSkip("Skipping integration tests. Set RUN_MCP_INTEGRATION_TESTS=1 to run them.")
        }
    }
    
    func testFirecrawlScrape() async throws {
        // Create a FirecrawlMCPFlowStage for scraping
        let scrapeStage = FirecrawlMCPFlowStage(
            function: .scrape,
            parameters: [
                "url": "https://example.com",
                "formats": ["markdown"],
                "onlyMainContent": true
            ]
        )
        
        // Execute the flow stage
        let result = try await scrapeStage.execute(InOutType.none)
        
        // Verify we got a non-empty result
        XCTAssertNotNil(try? result.text)
        XCTAssertFalse((try? result.text.isEmpty) ?? true)
        
        // Verify the result contains expected content from example.com
        if let text = try? result.text {
            XCTAssertTrue(text.contains("Example Domain") || text.contains("example"), "Result should contain content from example.com")
        }
    }
    
    func testFirecrawlSearch() async throws {
        // Create a FirecrawlMCPFlowStage for searching
        let searchStage = FirecrawlMCPFlowStage(
            function: .search,
            parameters: [
                "query": "Swift programming language",
                "limit": 3
            ]
        )
        
        // Execute the flow stage
        let result = try await searchStage.execute(InOutType.none)
        
        // Verify we got a non-empty result
        XCTAssertNotNil(try result.text)
        XCTAssertFalse((try? result.text.isEmpty) ?? true)
        
        // Verify the result is valid JSON and contains search results
        if let text = try? result.text, let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                
                // Check if we have results
                let results = json?["results"] as? [[String: Any]]
                XCTAssertNotNil(results)
                XCTAssertFalse(results?.isEmpty ?? true)
                
                // Check if the first result has the expected fields
                if let firstResult = results?.first {
                    XCTAssertNotNil(firstResult["title"])
                    XCTAssertNotNil(firstResult["url"])
                }
            } catch {
                XCTFail("Failed to parse JSON response: \(error)")
            }
        }
    }
    
    func testFirecrawlDeepResearch() async throws {
        // Create a FirecrawlMCPFlowStage for deep research
        let researchStage = FirecrawlMCPFlowStage(
            function: .deepResearch,
            parameters: [
                "query": "Swift programming best practices",
                "maxDepth": 2,
                "maxUrls": 3,
                "timeLimit": 60
            ]
        )
        
        // Execute the flow stage
        let result = try await researchStage.execute(InOutType.none)
        
        // Verify we got a non-empty result
        XCTAssertNotNil(try? result.text)
        XCTAssertFalse((try? result.text.isEmpty) ?? true)
        
        // Verify the result contains meaningful content
        if let text = try? result.text {
            XCTAssertTrue(text.count > 100, "Deep research result should be substantial")
            XCTAssertTrue(text.contains("Swift") || text.contains("programming") || text.contains("practices"), 
                         "Result should be relevant to the query")
        }
    }
    
    func testLinearFlowWithMCPServer() async throws {
        // Create a linear flow with a FirecrawlMCPFlowStage
        let flow = LinearFlow.withFirecrawlScrape(url: "https://example.com")
        
        // Execute the flow
        // This should not throw any exceptions if the MCP server is working correctly
        try await flow.execute(nil)
    }
    
    func testChainedMCPOperations() async throws {
        // Create a flow that chains multiple MCP operations
        let flow = LinearFlow {
            // First, search for content
            FirecrawlBuilder.search(query: "Swift programming", limit: 2)
            
            // Then, take the first result URL and scrape it
            // This demonstrates how to use the output of one MCP operation as input to another
            CustomFlowStage { input in
                guard let inputText = try input?.text,
                      let data = inputText.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let firstResult = results.first,
                      let url = firstResult["url"] as? String else {
                    throw MCPServerError.invalidInput
                }
                
                // Return the URL to scrape
                return .string(url)
            }
            
            // Now scrape the URL from the search result
            CustomFlowStage { input in
                guard let url = try input?.text else {
                    throw MCPServerError.invalidInput
                }
                
                // Create a scrape stage for this URL
                let scrapeStage = FirecrawlBuilder.scrape(url: url)
                
                // Execute the scrape and return the result
                return try await scrapeStage.execute(InOutType.none)
            }
        }
        
        // Execute the flow
        try await flow.execute(nil)
    }
}

/// A simple custom flow stage for transformation operations
struct CustomFlowStage: FlowStage {
    let operation: (InOutType?) async throws -> InOutType
    
    init(operation: @escaping (InOutType?) async throws -> InOutType) {
        self.operation = operation
    }
    
    func execute(_ input: InOutType?) async throws -> InOutType {
        return try await operation(input)
    }
}
