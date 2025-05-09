//
//  Tools.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation
import SwiftyPrompts
import SwiftyPrompts_OpenAI
import SwiftyJsonSchema


public enum OutputType {
    case string
    case JSON(JSONSchema)
    case JSONObject
    case none
}



public struct CLIAppTool {}

public struct NodeJSTool {}

public struct ToolUsingAgent: FlowStage {
    public func execute(_ input: InOutType?) throws -> InOutType {
        return .string("Use tool")
    }
}

public enum WriteToFileToolError: Error {
    case noInput
}

public struct WriteToFileTool: FlowStage {
    
    // Get the shared documents directory URL
    let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    public var basePath: URL
    public var fileName: String
    
    public init(basePath: URL? = nil, fileName: String) {
        self.basePath = basePath ?? documentsDirectoryURL
        self.fileName = fileName
    }
    
    public func execute(_ input: InOutType?) throws -> InOutType {
        guard let input = input else {
            throw WriteToFileToolError.noInput
        }
        
        guard let fileContent: String = {
            switch input {
            case .JSON(let string), .md(let string), .string(let string):
                    return string
            case .none:
                return nil
            }
        }() else {
            throw WriteToFileToolError.noInput
        }

        let fullPath = basePath.appending(path: fileName)
        try fileContent.write(to: fullPath, atomically: false, encoding: .ascii)
        logger.info("Wrote data to \(fullPath)")
        
        return input
    }
}

@resultBuilder
public struct FlowBuilder {
    
    public static func buildBlock(_ stages: any FlowStage...) -> [any FlowStage] {
        return stages
    }
    
    public static func buildOptional(_ stage: [any FlowStage]?) -> [any FlowStage] {
        stage ?? []
    }
    
//    /// Add support for both single and collections of constraints.
//    static func buildExpression(_ expression:  any Tool) -> [any Tool] {
//        [expression]
//    }
//
//    static func buildExpression(_ expression: [any Tool]) -> [any Tool] {
//        expression
//    }
}
