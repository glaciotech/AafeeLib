//
//  LLmServiceFactory.swift
//  AafeeLib
//
//  Created by Peter Liddle on 7/17/25.
//

import OpenAIKit
import SwiftAnthropic
import SwiftyPrompts
import SwiftyPrompts_OpenAI
import SwiftyPrompts_Anthropic
import SwiftyPrompts_xAI


enum LLMServiceFactoryError: Error {
    case unknownProvider
    case unknownModel(String)
}

public typealias OpenAIModel = String

extension OpenAIModel: OpenAIKit.ModelID {
    public var id: String {
        return self
    }
    
    public init(_ from: OpenAIKit.ModelID) {
        self = from.id
    }
    
    public init(_ raw: String) {
        self = raw
    }
}

open class LLMServiceFactory {
    
    public enum AnyProviderModel {
        case anthropic(SwiftAnthropic.Model)
        case openai(OpenAIModel)
        case xai(xAIModel)
    }
    
    public var apiKey: String
    public var llmModel: AnyProviderModel
    
    public init(apiKey: String, model: AnyProviderModel) throws {
        self.apiKey = apiKey
        self.llmModel = model
    }
    
    private static func openAIValidate(model: String) -> OpenAIKit.ModelID? {
        
        if let model = Model.GPT4(rawValue: model) {
            return model
        }
        else if let model = Model.GPT3(rawValue: model) {
            return model
        }
        else if let model = Model.Codex(rawValue: model) {
            return model
        }
        else if let model = Model.Whisper(rawValue: model) {
            return model
        }
        
        return nil
    }
    
    public init(apiKey: String, provider: String, model: String) throws {
        self.apiKey = apiKey
        
        switch provider.lowercased() {
        case "openai":
            
            if Self.openAIValidate(model: model) == nil {
                logger.warning("The model \(model) is not a known model this may cause errors calling OpenAI API. Check it is a valid model with OpenAI, it could be a newer model then the SDK is aware of")
            }
            
            llmModel = .openai(model)

        case "anthropic":
            llmModel = .anthropic(SwiftAnthropic.Model.other(model))
        case "xai":
            guard let xAIModel = xAIModel.init(rawValue: model) else {
                throw LLMServiceFactoryError.unknownModel(model)
            }
            llmModel = .xai(xAIModel)
        default:
            throw LLMServiceFactoryError.unknownProvider
        }
    }
    
    open func create() -> LLM {
        switch llmModel {
        case .anthropic(let model):
            return AnthropicLLM(apiKey: apiKey, model: model)
        case .openai(let modelID):
            return OpenAILLM(apiKey: apiKey, model: modelID)
        case .xai(let xaiModel):
            return xAILLM(apiKey: apiKey, model: xaiModel)
        }
    }
}
