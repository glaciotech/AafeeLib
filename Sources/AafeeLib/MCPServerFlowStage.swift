//
//  MCPServerFlowStage.swift
//
//
//  Created by Cascade on 5/15/25.
//

import Foundation

/// Errors that can occur when using the MCPServerFlowStage
public enum MCPServerError: Error {
    case invalidServerName
    case invalidInput
    case invalidParameters
    case serverError(String)
    case decodingError(Error)
}

/// A FlowStage that can invoke MCP server functions
public struct MCPServerFlowStage: FlowStage {
    /// The name of the MCP server to invoke
    public let serverName: String
    
    /// The function name to call on the MCP server
    public let functionName: String
    
    /// Optional parameters to pass to the function
    public let parameters: [String: Any]?
    
    /// Initializes a new MCPServerFlowStage
    /// - Parameters:
    ///   - serverName: The name of the MCP server to invoke
    ///   - functionName: The function name to call on the MCP server
    ///   - parameters: Optional parameters to pass to the function
    public init(serverName: String, functionName: String, parameters: [String: Any]? = nil) {
        self.serverName = serverName
        self.functionName = functionName
        self.parameters = parameters
    }
    
    /// Executes the MCP server function
    /// - Parameter input: Optional input from previous FlowStage
    /// - Returns: The result of the MCP server function call as InOutType
    public func execute(_ input: InOutType?) async throws -> InOutType {
        // Validate server name
        guard !serverName.isEmpty else {
            throw MCPServerError.invalidServerName
        }
        
        // Create the MCP request
        let mcpRequest = try createMCPRequest(input)
        
        // Execute the MCP request
        let result = try await executeMCPRequest(mcpRequest)
        
        return .string(result)
    }
    
    /// Creates an MCP request based on the function name and parameters
    /// - Parameter input: Optional input from previous FlowStage
    /// - Returns: Dictionary representing the MCP request
    private func createMCPRequest(_ input: InOutType?) throws -> [String: Any] {
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
        
        return mcpRequest
    }
    
    /// Executes the MCP request by sending it to the MCP server
    /// - Parameter request: The MCP request to execute
    /// - Returns: The result of the MCP server function call as a String
    private func executeMCPRequest(_ request: [String: Any]) async throws -> String {
        // Convert request to JSON data
        guard let requestData = try? JSONSerialization.data(withJSONObject: request) else {
            throw MCPServerError.invalidParameters
        }
        
        // Create URL for MCP server endpoint
        // This is a placeholder URL - in a real implementation, you would configure this properly
        guard let url = URL(string: "http://localhost:8080/mcp/\(serverName)/\(functionName)") else {
            throw MCPServerError.invalidServerName
        }
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Execute the request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPServerError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MCPServerError.serverError("HTTP error \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Convert response data to string
        guard let resultString = String(data: data, encoding: .utf8) else {
            throw MCPServerError.serverError("Could not decode response")
        }
        
        return resultString
    }
}

/// A builder for creating MCPServerFlowStage instances with a fluent API
public struct MCPServerBuilder {
    private let serverName: String
    
    /// Initializes a new MCPServerBuilder
    /// - Parameter serverName: The name of the MCP server to invoke
    public init(serverName: String) {
        self.serverName = serverName
    }
    
    /// Creates an MCPServerFlowStage for the specified function
    /// - Parameters:
    ///   - functionName: The function name to call on the MCP server
    ///   - parameters: Optional parameters to pass to the function
    /// - Returns: An MCPServerFlowStage instance
    public func function(_ functionName: String, parameters: [String: Any]? = nil) -> MCPServerFlowStage {
        return MCPServerFlowStage(serverName: serverName, functionName: functionName, parameters: parameters)
    }
}

// Extension to make it easier to create MCP server flow stages
public extension LinearFlow {
    /// Creates a new LinearFlow with an MCPServerFlowStage
    /// - Parameters:
    ///   - serverName: The name of the MCP server to invoke
    ///   - functionName: The function name to call on the MCP server
    ///   - parameters: Optional parameters to pass to the function
    /// - Returns: A new LinearFlow instance
    static func withMCPServer(serverName: String, functionName: String, parameters: [String: Any]? = nil) -> LinearFlow {
        return LinearFlow {
            MCPServerFlowStage(serverName: serverName, functionName: functionName, parameters: parameters)
        }
    }
}
