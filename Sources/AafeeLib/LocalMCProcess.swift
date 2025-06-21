//
//  MCPClient.swift
//  AafeeLib
//
//  Created by Peter Liddle on 6/20/25.
//

import MCP
import Foundation

public struct LocalMCPServerConfig: Codable {
    public var name: String
    public var executablePath: String
    public var arguments: [String]
    public var environment: [String: String]
}

public class LocalMCProcess {
    
    let config: LocalMCPServerConfig
    private let process: MCPProcess
    
    public init(config: LocalMCPServerConfig) {
        self.config = config
        self.process = MCPProcess(executablePath: config.executablePath, arguments: config.arguments)
    }
    
    public func start() async throws -> Client {
        // Start up the process
        let stdio = try self.process.start()
        let client = Client(name: self.config.name, version: "1.0.0", configuration: .default)
        _ = try await client.connect(transport: stdio)
        return client
    }
    
//    // Initialize the client
//    let client = Client(name: "MyApp", version: "1.0.0")
//
//    // Create a transport and connect
//    let transport = StdioTransport()
//    let result = try await client.connect(transport: transport)
//
//    // Check server capabilities
//    if result.capabilities.tools != nil {
//        // Server supports tools (implicitly including tool calling if the 'tools' capability object is present)
//    }
}
