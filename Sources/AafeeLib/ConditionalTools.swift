//
//  ConditionalTools.swift
//  AafeeLib
//
//  Created by Peter Liddle on 5/31/25.
//


public struct RepeatUntilConditionTool: FlowStage {
    
    @CustomBinding public var condition: Bool
    @FlowBuilder public var subflow: LinearFlow
    
    init(condition: CustomBinding<Bool>, subflow: LinearFlow) {
        self._condition = condition
        self.subflow = subflow
    }
    
    // Wrapped flow
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        
        var output: InOutType?
        repeat {
            output = try await subflow.execute(input)
        } while condition
        
        return output ?? .none
    }
}
