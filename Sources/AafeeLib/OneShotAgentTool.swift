//
//  AgentTool.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation
import SwiftyPrompts

import SwiftyPrompts_OpenAI
import SwiftyPrompts_Anthropic

import SwiftyJsonSchema
import OpenAIKit

import Vapor
import SwiftyPrompts_VaporSupport

public enum NextStep {
    case `continue`
    case end
}

public struct InstructionOutput {
    
    public var text: String = ""
    
    public var instruction: NextStep = .end
}

public enum InOutTypeError: Error {
    case notTextRepresentable
}

public enum InOutType {
    case string(String)
    case JSON(String)
    case md(String)
    case none
    case instruction(InstructionOutput)
    case structured(Codable.Type, Codable)
    case array([String])
    
    public var text: String {
        get throws {
            switch self {
            case let .string(string), let .JSON(string), let .md(string):
                return string
            case let .instruction(output):
                return output.text
            case .none:
                throw InOutTypeError.notTextRepresentable
            case .array(let texts):
                return "[\(texts.joined(separator: ", "))]"
            default:
                throw InOutTypeError.notTextRepresentable
            }
        }
    }
}

public protocol FlowStage {
    func execute(_ input: InOutType?) async throws -> InOutType
}

public struct LLMModelConfig {
    var apiKey: String
    var name: String
    var provider: String
}


public struct StructuredOutputOneShotAgentTool<O>: FlowStage where O: ProducesJSONSchema {
    
    public let AGENT_API_KEY = "AGENT_API_KEY"
    
    public var apiKey: String
    public var model: String
    public var prompt: PromptTemplate
    
    public var preSendMessageModifier: (([Message]) -> [Message]) = { return $0 }
    public var postSendMessageModifier: (([Message]) -> [Message]) = { return $0 }
    
    public init(apiKey: String? = nil, model: String, prompt: PromptTemplate,
                preSendMessageModifier: @escaping ([Message]) -> [Message] = { return $0 },
                postSendMessageModifier: @escaping ([Message]) -> [Message] = { return $0 } ) throws {
        
        guard let apiKey = apiKey ?? UserDefaults.standard.string(forKey: AGENT_API_KEY) else {
            throw AgentToolError.noAPIKey
        }
 
        self.apiKey = apiKey
        self.model = model
        self.prompt = prompt
        self.preSendMessageModifier = preSendMessageModifier
        self.postSendMessageModifier = postSendMessageModifier
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        let runner = SwiftyPrompts.JSONSchemaPromptRunner<O>()
        
        let llm = OpenAILLM(apiKey: self.apiKey)
        
        guard let input = input, let inputTextRep = try? input.text else {
            throw AgentToolError.noValidInput
        }
        
        logger.debug("Agent Tool running with \(input)")
        
        let msgs: [Message] = [.system(.text(prompt.text)), .user(.text(inputTextRep))]
        let msgsToSend = preSendMessageModifier(msgs)
        let output = try await runner.run(with: msgsToSend, on: llm)
        
        return .structured(O.self, output.output)
    }
}

public struct OneShotAgentTool: FlowStage, PreSendInterception, PostSendInterception {
    
    public static let AGENT_API_KEY = "AGENT_API_KEY"
    
    public let serviceFactory: LLMServiceFactory
    public var prompt: PromptTemplate
    
    public var preSendMessageModifier: ([Message], [Message]) -> [Message]
    public var postSendOutputModifier: (String) -> String
    
    public init(serviceFactory: LLMServiceFactory,
                prompt: PromptTemplate,
                preSendMessageModifier: @escaping ([Message], [Message]) -> [Message] = { return $0 + $1 },
                postSendOutputModifier: @escaping (String) -> String = { return $0 } ) throws {
        
        self.serviceFactory = serviceFactory
        
        self.prompt = prompt
        self.preSendMessageModifier = preSendMessageModifier
        self.postSendOutputModifier = postSendOutputModifier
    }
    
    public init(apiKey: String? = nil, model: String, prompt: PromptTemplate,
                preSendMessageModifier: @escaping ([Message], [Message]) -> [Message] = { return $0 + $1 },
                postSendOutputModifier: @escaping (String) -> String = { return $0 } ) throws {
        
        guard let apiKey = apiKey ?? UserDefaults.standard.string(forKey: Self.AGENT_API_KEY) else {
            throw AgentToolError.noAPIKey
        }
        
        self.serviceFactory = try LLMServiceFactory(apiKey: apiKey, model: .openai(.init(OpenAIKit.Model.GPT4.gpt4oLatest)))
        
        self.prompt = prompt
        self.preSendMessageModifier = preSendMessageModifier
        self.postSendOutputModifier = postSendOutputModifier
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        let runner = SwiftyPrompts.BasicPromptRunner(apiType: .standard)
        
        let llm = serviceFactory.create() // OpenAILLM(apiKey: self.apiKey)
        
        guard let input = input, let inputTextRep = try? input.text else {
            throw AgentToolError.noValidInput
        }
        
        logger.debug("Agent Tool running with \(input)")
        
        let msgs: [Message] = [.system(.text(prompt.text)), .user(.text(inputTextRep))]
        let msgsToSend = preSendMessageModifier([], msgs)
        let output = try await runner.run(with: msgsToSend, on: llm)
        let modifiedOutput = postSendOutputModifier(output.output)
        
        return .string(modifiedOutput)
    }
}

public protocol PreSendMessageModifier {
    func modify(input: [Message]) -> [Message]
}

public class MessageHistoryProvider: PreSendMessageModifier {
    
    private var history = [Message]()
    
    public init() {}
    
    func add(messages: [Message]) {
        history.append(contentsOf: messages)
    }
    
    public func modify(input: [SwiftyPrompts.Message]) -> [SwiftyPrompts.Message] {
        var modifiedMsgs = history
        modifiedMsgs.append(contentsOf: input)
        return modifiedMsgs
    }
}

public protocol PreSendInterception {
    var preSendMessageModifier: (_ template: [Message], _ input: [Message]) -> [Message] { get set }
}

public protocol PostSendInterception {
    var postSendOutputModifier: (String) -> String { get set }
}

public struct StopContinueAgentTool: FlowStage, PreSendInterception, PostSendInterception {
    
    public static let AGENT_API_KEY = "AGENT_API_KEY"
    
    public var apiKey: String
    public var model: String
    public var prompt: PromptTemplate
    
    public var preSendMessageModifier: (_ template: [Message], _ input: [Message]) -> [Message] = { return $0 + $1 }
    public var postSendOutputModifier: (String) -> String = { return $0 }
    
    func findInstruction(in text: String) -> String? {
        // Use a refined regex pattern to capture only CONTINUE or END
        let pattern = #"\[INSTRUCTION: (CONTINUE|END)\]"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: wholeRange)
            
            // Find the last match
            if let lastMatch = matches.last {
                if let range = Range(lastMatch.range, in: text) {
                    return String(text[range])
                }
            }
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
        }
        return nil
    }

    
    let systemStopContinuePrompt = """
You're a helpful agent that should do what is requested in your prompt, but you may take input in order to satisfy that prompt, in order to cater to that after each stage you should include an instruction 
of whether to CONTINUE or END, depending on whether you need input or the conversation is finished. The instruction should be formatted as
`[INSTRUCTION: {CONTINUE | END}]` an example if you're waiting for the user to input a city would be `[INSTRUCTION: CONTINUE]`
"""
        
  
    public init(apiKey: String? = nil, model: String, prompt: PromptTemplate,
                preSendMessageModifier: @escaping ([Message], [Message]) -> [Message] = { return $0 + $1 },
                postSendOutputModifier: @escaping (String) -> String = { return $0 }) throws {
        
        guard let apiKey = apiKey ?? UserDefaults.standard.string(forKey: Self.AGENT_API_KEY) else {
            throw AgentToolError.noAPIKey
        }
        
        self.apiKey = apiKey
        self.model = model
        self.prompt = prompt
        self.preSendMessageModifier = preSendMessageModifier
        self.postSendOutputModifier = postSendOutputModifier
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        let runner = SwiftyPrompts.BasicPromptRunner()
        let llm = OpenAILLM(apiKey: self.apiKey)
        
        guard let input = input, let inputTextRep = try? input.text else {
            throw AgentToolError.noValidInput
        }
        
        logger.debug("Agent Tool running with \(input)")
        
        let templateMsgs: [Message] = [.system(.text(systemStopContinuePrompt)), .system(.text(prompt.text))]
        let inputMsg: [Message] = [.user(.text(inputTextRep))]
        let finalMsgsToSend  = preSendMessageModifier(templateMsgs, inputMsg) // Standard modifier combines template and input
        let output = try await runner.run(with: finalMsgsToSend, on: llm)
        _ = postSendOutputModifier(output.output.text)
        
        
        // Check for instruction
        if let instruction = findInstruction(in: output.output.text) {
            switch instruction {
            case "[INSTRUCTION: END]":
                return InOutType.instruction(.init(text: output.output.text, instruction: .end))
            case "[INSTRUCTION: CONTINUE]":
                return InOutType.instruction(.init(text: output.output.text, instruction: .continue))
            default:
                return .string(output.output.text)
            }
        }
        
        return .string(output.output.text)
    }
}


