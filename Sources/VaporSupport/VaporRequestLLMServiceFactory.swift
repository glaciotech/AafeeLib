//
//  VaporRequestLLMServiceFactory.swift
//  AafeeLib
//
//  Created by Peter Liddle on 7/25/25.
//

import AafeeLib

import OpenAIKit
import SwiftAnthropic
import SwiftyPrompts
import SwiftyPrompts_OpenAI
import SwiftyPrompts_Anthropic
import SwiftyPrompts_xAI

import Vapor
import SwiftyPrompts_VaporSupport


/// Service factory that creates an LLM but using a Delegated Request handler that lets Vapor handle the lifecycle of the web calls
public class VaporRequestLLMServiceFactory: LLMServiceFactory {
    
    var requestHandler: DelegatedRequestHandler
    
    public init(client: Vapor.Client, apiKey: String, model: AnyProviderModel) throws {
        self.requestHandler = VaporDelegatedRequestHandler(apiKey: apiKey, client: client)
        try super.init(apiKey: apiKey, model: model)
    }
    
    public override func create() -> LLM {
        switch llmModel {
        case .anthropic(let model):
            return AnthropicLLM(apiKey: apiKey, model: model)
        case .openai(let modelID):
            return OpenAILLM(with: requestHandler, apiKey: apiKey, model: modelID)
        case .xai(let xaiModel):
            return xAILLM(apiKey: apiKey, model: xaiModel)
        }
    }
}
