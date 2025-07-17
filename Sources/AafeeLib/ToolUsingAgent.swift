//
//  ToolUsingAgent.swift
//  AafeeLib
//
//  Created by Peter Liddle on 6/23/25.
//

import Foundation
import SwiftyJsonSchema
import SwiftyPrompts
import SwiftyPrompts_OpenAI
import MCPHelpers

enum AgentToolError: Error {
    case noAPIKey
    case noValidInput
}

//protocol HasEnvironmet {
//    var objects: [String: Any] { get }
//}
//
//@propertyWrapper struct EnviromentObject<T> {
//
//    private let type: T
//    
//    init(type: T) {
//        self.type = type
//    }
//    
//    var wrappedValue: T {
//        get {
//            fatalError("Not implemented, will reach into environment and grab")
//        }
//    }
//}


/// Type that allows a raw json fragment that works with Codable. It's just coded and decoded into a string. Useful for later processing or where the JSON might be dynamic
struct JSONFragment: Codable, DynamicSchema {
    
    static let empty = JSONFragment()
    
    @JSONSchemaExclude
    private var rawJson: Value
    
    private init() {
        rawJson = .null
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawJson = try container.decode(Value.self)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawJson)
    }
}

public class ToolManager {
    
    private var toolConfigs: [LocalMCPServerConfig]
    
    public var availableTools = [ToolInfo: ToolState]()
    
    public enum ToolState {
        case connected(MCPClient)
        case errored(Error)
    }
    
    public struct ToolInfo: Hashable {
        var serverName: String
        var tool: MCPTool? = nil
    }
    
    public init(tools: [LocalMCPServerConfig]) {
        self.toolConfigs = tools
    }
    
    public func unload() async throws {
        let connectedTools = availableTools.reduce(into: [MCPClient](), { partialResult, element in
            guard case let ToolState.connected(client) = element.value else { return }
            partialResult.append(client)
        })
    
        for client in connectedTools {
            await client.disconnect()
        }
    }
    
    public func loadAvailbleTools() async throws {
        
        enum RegisterResult {
            case available(String, [MCPTool: MCPClient])
            case error(String, Error)
        }
        
        let registerResult = await withTaskGroup(of: RegisterResult.self) { group in
//            var toolAccumulator = [MCPTool: MCPClient]()
//            var errors: [String: Error] = [:]

            var availableTools = [ToolInfo: ToolState]()
            
            for toolConfig in toolConfigs {
                group.addTask {
                    do {
                        let process = LocalMCProcess(config: toolConfig)
                        let client = try await process.start()
                        let toolResponse = try await client.listTools()
                        let toolDictionary = Dictionary(uniqueKeysWithValues: toolResponse.tools.map { ($0, client) })
                        return .available(toolConfig.name, toolDictionary)
                    } catch {
                        return .error(toolConfig.name, error)
                    }
                }
            }

            for await result in group {
                switch result {
                case let .available(serverName, toolDictionary):
                    toolDictionary.forEach { toolInfo, client in
                        availableTools[.init(serverName: serverName, tool: toolInfo)] = .connected(client)
                    }
                case let .error(serverName, error):
                    availableTools[.init(serverName: serverName)] = .errored(error)
                }
            }

            return availableTools
        }
        
        self.availableTools = registerResult
    }
    
    public func call(tool: ToolInfo, with args: [String: Value]) async throws -> (content: String, isError: Bool)? {
        if let toolState = availableTools[tool], case let ToolState.connected(client) = toolState {
            guard let name = tool.tool?.name else {
                throw NSError(domain: "No tool name", code: 0)
            }
            
            let result = try await client.callTool(name: name, arguments: args)
            
            return ("\(result.content)", result.isError ?? false)
        }
        return nil
    }
}

/// Agent capable of calling tools, this is a generic component that will work with any LLM
/// for more advanced and consistent calling use the advanced version which uses LLMs specific tool calling capability
public struct GenericToolCapableAgent: FlowStage {
    
    public var environmentStore = EnvironmentValues()
    
    let outputActionSchema = """
    {
      "type": "object",
      "oneOf": [
        {
          "properties": {
            "useTool": {
              "type": "object",
              "additionalProperties": true
            }
          },
          "required": ["useTool"],
          "additionalProperties": false
        },
        {
          "properties": {
            "userInput": {
              "type": "string"
            }
          },
          "required": ["userInput"],
          "additionalProperties": false
        },
        {
          "properties": {
            "end": {
              "type": "null"
            }
          },
          "required": ["end"],
          "additionalProperties": false
        }
      ]
    }
    """
    
    #warning("Add ability to handle enums to JSONSchema")
//    enum OutputAction: ProducesJSONSchema {
//        static let exampleValue = GenericToolCapableAgent.OutputAction.toolUse("")
//
//        case toolUse(String)
//        case userInput(String)
//        case end
//    }
    
  
    enum OutputAction: Codable, ProducesUnionJSONSchema, HasCustomJSONSchemaDescriptions {
        static var schemaDescriptions: [String : String] {["useTool": "Indicates to the caller you wish to use a tool along with the JSON to call the tool",
                                                    "userInput": "Indicates you need more input from the user, along with any instructions",
                                                    "end": "You're done processing, hand control back to user" ]}
        
      
        struct ToolID: Codable, ProducesJSONSchema {
            static var exampleValue = ToolID(serverName: "MCP Server Name", toolName: "Name of the tool")
            
            @JSONSchemaMetadata(description: "The MCP server hosting the tool")
            var serverName: String = ""
            
            @JSONSchemaMetadata(description: "The name of the tool to invoke")
            var toolName: String = ""
        }
        
        static var allCases: [Self] = [.end, .useTool(ToolID.exampleValue, .empty), .userInput("Example user input")]
        
//        @JSONSchemaMetadata(description: "Indicates to the caller you wish to use a tool along with the JSON to call the tool")
        case useTool(ToolID, JSONFragment)
        
//        @JSONSchemaMetadata(description: "Indicates you need more input from the user, along with any instructions")
        case userInput(String)
        
        case end
        
//        enum CodingKeys: CodingKey {
//            case useTool
//            case userInput
//            case end
//        }
    }
    
//    enum ActionType: CaseIterable, ProducesJSONSchema {
//        var allowedTypes: [any SwiftyJsonSchema.ProducesJSONSchema.Type]
//        
//        static var allCases: [GenericToolCapableAgent.ActionType] = [.end, .useTool(""), userInput("")]
//        
//        @SchemaInfo("Indicates to the caller you wish to use a tool along with the JSON to call the tool")
//        case useTool(JSONSchema)
//        
//        @SchemaInfo("Indicates you need more input from the user, along with any instructions")
//        case userInput(String)
//        
//        @
//        case end
//    }
    
//    struct OutputAction: ProducesJSONSchema {
//        static var exampleValue = GenericToolCapableAgent.OutputAction(toolUse: "", userInput: "", end: false)
//        
//        @SchemaInfo("Use ")
//        var toolUse: String? = nil
//        var userInput: String = ""
//        var end: Bool = false
//    }
    
    public let toolManager: ToolManager
    
    public let AGENT_API_KEY = "AGENT_API_KEY"
    
    public var apiKey: String
    public var model: String
    public var prompt: PromptTemplate
    
    private var toolUsePrompt: String {
    """
        You have the following tools available to you to help fulfill the users request. 
        \(toolManager.availableTools.keys)
    
        You're response should adhere to the following json schema, where the `useTool` property takes a json object that adheres to the json schema associated with the tool that was given to you above.
    
        \(outputActionSchema)
    """
    }
    
    public var preSendMessageModifier: (([Message]) -> [Message]) = { return $0 }
    public var postSendMessageModifier: (([Message]) -> [Message]) = { return $0 }
    
    private let decoder = JSONDecoder()
    
    public init(apiKey: String? = nil, model: String, prompt: PromptTemplate,
                toolManager: ToolManager,
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
        self.toolManager = toolManager
    }

    public func execute(_ input: InOutType?) async throws -> InOutType {
    
        try await toolManager.loadAvailbleTools()
        
        let runner = SwiftyPrompts.JSONSchemaPromptRunner<OutputAction>()
//        let runner = SwiftyPrompts.BasicPromptRunner()
        
        let llm = OpenAILLM(apiKey: self.apiKey)
        
        guard let input = input, let inputTextRep = try? input.text else {
            throw AgentToolError.noValidInput
        }
        
        logger.debug("Agent Tool running with \(input)")
        
        let msgs: [Message] = [.system(.text(toolUsePrompt + prompt.text)), .user(.text(inputTextRep))]
        let msgsToSend = preSendMessageModifier(msgs)
        let output = try await runner.run(with: msgsToSend, on: llm)
        let action = output.output
        
        let extractor = CodeBlockExtractorTool(identifier: "json")
        //just
//        let rawBlocks = try await extractor.execute(.string(action))
        //just
        print(action)
//        print(rawBlocks)
     
        //just
//        guard case let InOutType.array(array) = rawBlocks, let rawJson = array.first, let rawJsonData = rawJson.data(using: .ascii) else {
//            return .none
//        }

//        let rawToolJson = array.first!
//        let tool = try JSONSerialization.jsonObject(with: rawJson.data(using: .ascii)!)
        //just
//        let toolOb = try decoder.decode(OutputAction.self, from: rawJsonData)
  
        //just
//        print(toolOb)
//        
//        switch toolOb {
//        case .end:
//            return .none
//        case let .useTool(name, json):
//            let jsonFrag = try Value(json)
////            toolManager.call(tool: .init(serverName: <#T##String#>, tool: <#T##MCPTool?#>), with: <#T##[String : Value]#>)
//        case .userInput(let text):
//            return .string(text)
//        }
//        
////        if let tool = action.useTool {
////            toolManager.call(tool: tool)
////        }
////
//        
//        try await toolManager.unload()
//        
//        return .structured(OutputAction.self, output.output)
        return .none         //just
    }
    
}
