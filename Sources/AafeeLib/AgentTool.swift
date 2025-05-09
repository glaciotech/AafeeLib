//
//  AgentTool.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation
import SwiftyPrompts
import SwiftyPrompts_OpenAI


public enum InOutType {
    case string(String)
    case JSON(String)
    case md(String)
    case none
    
    var text: String? {
        switch self {
        case let .string(string), let .JSON(string), let .md(string):
            return string
        case .none:
            return nil
        }
    }
}

public protocol FlowStage {
    func execute(_ input: InOutType?) async throws -> InOutType
}

enum AgentToolError: Error {
    case noAPIKey
    case noValidInput
}

public struct AgentTool: FlowStage {
    
    public static let AGENT_API_KEY = "AGENT_API_KEY"
    
    public var apiKey: String
    public var model: String
    public var prompt: PromptTemplate
    
    public init(apiKey: String? = nil, model: String, prompt: PromptTemplate) throws {
        guard let apiKey = apiKey ?? UserDefaults.standard.string(forKey: Self.AGENT_API_KEY) else {
            throw AgentToolError.noAPIKey
        }
        self.apiKey = apiKey
        self.model = model
        self.prompt = prompt
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        let runner = SwiftyPrompts.BasicPromptRunner()
        let llm = OpenAILLM(apiKey: self.apiKey)
        
        guard let input = input, let inputTextRep = input.text else {
            throw AgentToolError.noValidInput
        }
        
        logger.debug("Agent Tool running with \(input)")
        
        let output = try await runner.run(with: [.system(.text(prompt.text)), .user(.text(inputTextRep))], on: llm)
        
        return .string(output.output)
    }
}
