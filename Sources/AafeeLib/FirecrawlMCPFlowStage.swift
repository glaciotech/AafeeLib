//
//  FirecrawlMCPFlowStage.swift
//
//
//  Created by Cascade on 5/15/25.
//

#if !os(Linux) // Not currently supported on Linux

import Foundation


/// A specialized FlowStage for interacting with the Firecrawl MCP server
public struct FirecrawlMCPFlowStage: FlowStage {
    private let mcpStage: MCPServerFlowStage
    
    /// Initializes a new FirecrawlMCPFlowStage
    /// - Parameters:
    ///   - function: The Firecrawl function to call
    ///   - parameters: Parameters for the function
    public init(function: FirecrawlFunction, parameters: [String: Any]) {
        self.mcpStage = MCPServerFlowStage(
            serverName: "mcp-server-firecrawl",
            functionName: function.rawValue,
            parameters: parameters
        )
    }
    
    /// Executes the Firecrawl MCP function
    /// - Parameter input: Optional input from previous FlowStage
    /// - Returns: The result of the MCP server function call as InOutType
    public func execute(_ input: InOutType?) async throws -> InOutType {
        return try await mcpStage.execute(input)
    }
}

/// Available functions in the Firecrawl MCP server
public enum FirecrawlFunction: String {
    case batchScrape = "batch_scrape"
    case checkBatchStatus = "check_batch_status"
    case checkCrawlStatus = "check_crawl_status"
    case crawl = "crawl"
    case deepResearch = "deep_research"
    case extract = "extract"
    case map = "map"
    case scrape = "scrape"
    case search = "search"
}

/// Builder for creating Firecrawl MCP flow stages
public struct FirecrawlBuilder {
    /// Creates a scrape flow stage
    /// - Parameters:
    ///   - url: The URL to scrape
    ///   - formats: Content formats to extract (default: ['markdown'])
    ///   - onlyMainContent: Extract only the main content (default: true)
    /// - Returns: A FirecrawlMCPFlowStage instance
    public static func scrape(url: String, formats: [String] = ["markdown"], onlyMainContent: Bool = true) -> FirecrawlMCPFlowStage {
        let parameters: [String: Any] = [
            "url": url,
            "formats": formats,
            "onlyMainContent": onlyMainContent
        ]
        
        return FirecrawlMCPFlowStage(function: .scrape, parameters: parameters)
    }
    
    /// Creates a search flow stage
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum number of results to return (default: 5)
    /// - Returns: A FirecrawlMCPFlowStage instance
    public static func search(query: String, limit: Int = 5) -> FirecrawlMCPFlowStage {
        let parameters: [String: Any] = [
            "query": query,
            "limit": limit
        ]
        
        return FirecrawlMCPFlowStage(function: .search, parameters: parameters)
    }
    
    /// Creates a crawl flow stage
    /// - Parameters:
    ///   - url: Starting URL for the crawl
    ///   - maxDepth: Maximum link depth to crawl
    ///   - limit: Maximum number of pages to crawl
    /// - Returns: A FirecrawlMCPFlowStage instance
    public static func crawl(url: String, maxDepth: Int, limit: Int) -> FirecrawlMCPFlowStage {
        let parameters: [String: Any] = [
            "url": url,
            "maxDepth": maxDepth,
            "limit": limit,
            "scrapeOptions": [
                "formats": ["markdown"],
                "onlyMainContent": true
            ]
        ]
        
        return FirecrawlMCPFlowStage(function: .crawl, parameters: parameters)
    }
    
    /// Creates a deep research flow stage
    /// - Parameters:
    ///   - query: The query to research
    ///   - maxDepth: Maximum depth of research iterations (1-10)
    ///   - maxUrls: Maximum number of URLs to analyze (1-1000)
    ///   - timeLimit: Time limit in seconds (30-300)
    /// - Returns: A FirecrawlMCPFlowStage instance
    public static func deepResearch(query: String, maxDepth: Int = 3, maxUrls: Int = 10, timeLimit: Int = 120) -> FirecrawlMCPFlowStage {
        let parameters: [String: Any] = [
            "query": query,
            "maxDepth": maxDepth,
            "maxUrls": maxUrls,
            "timeLimit": timeLimit
        ]
        
        return FirecrawlMCPFlowStage(function: .deepResearch, parameters: parameters)
    }
}

// Extension to make it easier to create Firecrawl flow stages
public extension LinearFlow {
    /// Creates a new LinearFlow with a Firecrawl scrape stage
    /// - Parameters:
    ///   - url: The URL to scrape
    ///   - formats: Content formats to extract (default: ['markdown'])
    ///   - onlyMainContent: Extract only the main content (default: true)
    /// - Returns: A new LinearFlow instance
    static func withFirecrawlScrape(url: String, formats: [String] = ["markdown"], onlyMainContent: Bool = true) -> LinearFlow {
        return LinearFlow {
            FirecrawlBuilder.scrape(url: url, formats: formats, onlyMainContent: onlyMainContent)
        }
    }
    
    /// Creates a new LinearFlow with a Firecrawl search stage
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum number of results to return (default: 5)
    /// - Returns: A new LinearFlow instance
    static func withFirecrawlSearch(query: String, limit: Int = 5) -> LinearFlow {
        return LinearFlow {
            FirecrawlBuilder.search(query: query, limit: limit)
        }
    }
}

#endif