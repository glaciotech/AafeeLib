//
//  FlowExecutor.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation

public struct LinearFlow {
    let stages: [any FlowStage]

    // Use the result builder in the initializer
    public init(@FlowBuilder _ stages: () -> [any FlowStage]) {
        self.stages = stages()
    }
    
    public func run() async throws {
        var previousOutput: InOutType?
        for stage in stages {
            previousOutput = try await stage.execute(previousOutput)
        }
    }
}
