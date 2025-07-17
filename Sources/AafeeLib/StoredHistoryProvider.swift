//
//  HistoryProvider.swift
//  AafeeLib
//
//  Created by Peter Liddle on 6/2/25.
//
import Foundation
import SwiftyPrompts
import Logging

public class StoredHistoryProvider<F>: FlowStage where F: FlowStage, F: PreSendInterception, F: PostSendInterception {

    var wrappedStage: F
    
    private var msgHistory = [Message]()
    
    public init(wrappedStage: F) {
        self.wrappedStage = wrappedStage
        self.wrappedStage.preSendMessageModifier = preSendMessageModifier
        self.wrappedStage.postSendOutputModifier = postSendOutputModifier

    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        dumpHistory()
        return try await wrappedStage.execute(input)
    }
    
    
    func preSendMessageModifier(templateMsgs: [Message], inputMsgs: [Message]) -> [Message] {
        
        let oldHistory = msgHistory
        
        msgHistory.append(contentsOf: inputMsgs)
        
        // Add the template msgs then the history then the latest input
        return templateMsgs + oldHistory + inputMsgs
    }
    
    func postSendOutputModifier(text: String) -> String {
        msgHistory.append(.ai(.text(text)))
        return text
    }
    
    private func dumpHistory() {
        let msg = "------ \n HISTORY" + msgHistory.map({ $0.content.text }).joined(separator: "\n") + "------\n\n"
        logger.debug("\(msg)")
    }
}



