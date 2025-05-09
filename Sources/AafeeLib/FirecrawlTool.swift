//
//  FirecrawlTool.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation
import SwiftFirecrawl
import Logging

public enum FirecrawlToolError: Error {
    case invalidUrl
    case noAPIKey
}

public struct FirecrawlTool: FlowStage {

    static let FIRECRAWL_API_KEY = "FIRECRAWL_API_KEY"
    
    public var url: String
    
    public var apiKey: String
    
    public init(apiKey: String? = nil, url: String) throws {
        guard let apiKey = apiKey ?? UserDefaults.standard.string(forKey: Self.FIRECRAWL_API_KEY) else {
            throw FirecrawlToolError.noAPIKey
        }
        
        self.apiKey = apiKey
        self.url = url
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        
        if let input = input {
            logger.info("Firecrawl Tool does not take input. \(input) ignored")
        }
        
        guard let validUrl = URL(string: url) else {
            throw FirecrawlToolError.invalidUrl
        }
        
        let firecrawl = SwiftFirecrawl.init(apiKey: self.apiKey)
        let md = try await firecrawl.scrape(url: validUrl)
        
        logger.debug("Pulling MD from \(url)")
        return .md(md)
    }
}
