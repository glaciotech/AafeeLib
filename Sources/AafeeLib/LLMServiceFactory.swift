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

public class LLMServiceFactory {
    
    public enum AnyProviderModel {
        case anthropic(SwiftAnthropic.Model)
        case openai(OpenAIKit.ModelID)
        case xai(xAIModel)
    }
    
    private var apiKey: String
    private var llmModel: AnyProviderModel
    
    public init(apiKey: String, model: AnyProviderModel) throws {
        self.apiKey = apiKey
        self.llmModel = model
    }
    
    public init(apiKey: String, provider: String, model: String) throws {
        self.apiKey = apiKey
        
        switch provider.lowercased() {
        case "openai":
            switch model.lowercased()[model.startIndex..<model.index(model.startIndex, offsetBy: 3)] {
            case "gpt4":
                llmModel = .openai(OpenAIKit.Model.GPT4(rawValue: model) ?? Model.GPT4.gpt4o)
            case "gpt3":
                llmModel = .openai(OpenAIKit.Model.GPT3(rawValue: model) ?? Model.GPT3.gpt3_5Turbo16K)
            default:
                throw LLMServiceFactoryError.unknownModel(model)
            }
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
    
    func create() -> LLM {
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
