//
//  FlowExecutor.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation

protocol Flow {
    func run() async throws
    func runWithOutput(with input: InOutType?) async throws -> InOutType?
}

public struct LinearFlow: FlowStage {

    
    let stages: [any FlowStage]

    // Use the result builder in the initializer
    public init(@FlowBuilder _ stages: () -> [any FlowStage]) {
        self.stages = stages()
    }
    
    public func execute(_ input: InOutType? = nil) async throws -> InOutType {
        return try await runWithOutput(with: input) ?? .none
    }
    
    private func run() async throws {
        _ = try await self.runWithOutput(with: nil)
    }
    
    private func runWithOutput(with input: InOutType? = nil) async throws -> InOutType? {
        var previousOutput: InOutType? = input
        for stage in stages {
            previousOutput = try await stage.execute(previousOutput)
        }
        
        return previousOutput
    }
}

public struct LoopedStageFlow: FlowStage {
    
    public enum ProcessInstruction {
        case stop
        case proceed(with: InOutType? = nil)
    }
    
    let stages: [any FlowStage]
    var executeNextStep: (_ prevOutput: InOutType?) -> ProcessInstruction
    
    public init(@FlowBuilder _ stages: () -> [any FlowStage], executeNextStep: @escaping (InOutType?) -> ProcessInstruction = {_ in return .stop} ) {
        self.stages = stages()
        self.executeNextStep = executeNextStep
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        return try await runWithOutput(with: input) ?? .none
    }
    
    private func run() async throws {
        _ = try await self.runWithOutput(with: nil)
    }
    
    private func runWithOutput(with input: InOutType? = nil) async throws -> InOutType? {
        var previousOutput: InOutType? = input
        for stage in stages {
            previousOutput = try await stage.execute(previousOutput)
        }
        
        // Call execute next step which allows modification before running whole stage again
        guard case let ProcessInstruction.proceed(modifiedInput) = executeNextStep(previousOutput) else {
            return previousOutput
        }
        
        return try await runWithOutput(with: modifiedInput)
    }
}
