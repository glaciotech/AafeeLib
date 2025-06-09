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
import RegexBuilder


public enum OutputType {
    case string
    case JSON(JSONSchema)
    case JSONObject
    case none
}


protocol FlowStageContainer {}


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

public enum CodeBlockExtractorError: Error {
    case noValidContent
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
            case .instruction(let output):
                return output.text
            case .structured(_, _), .array(_):
                fatalError("Not supported by this FileWriterTool use one that supports structured content")
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

public struct ReadFromFileTool: FlowStage {
    
    // Get the shared documents directory URL
    let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    public var basePath: URL
    public var fileName: String
    
    init(basePath: URL? = nil, fileName: String) {
        self.basePath = basePath ?? documentsDirectoryURL
        self.fileName = fileName
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        
        let fullPath = basePath.appending(path: fileName)
        let fileContent = try String(contentsOf: fullPath)
        logger.info("Read data from \(fileContent)")
        
        return .string(fileContent)
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


/// Tool used to add custom one off logic in a flow that isn't supported by existing tools
public struct AdHocFlowStage: FlowStage {
    var logic: (_ input: InOutType?) async throws -> InOutType
    
    public init(logic: @escaping (_: InOutType?) async throws -> InOutType) {
        self.logic = logic
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        return try await logic(input)
    }
}

public struct CodeBlockExtractorTool: FlowStage {
    private let identifier: String?
    
    public init(identifier: String? = nil) {
        self.identifier = identifier
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        guard let input = input else {
            throw CodeBlockExtractorError.noInput
        }
        
        guard let markdownContent: String = {
            switch input {
            case .JSON(let string), .md(let string), .string(let string):
                return string
            case .none:
                return nil
            case .instruction(let output):
                return output.text
            case .structured(_, _):
                return nil
            case .array(_):
                return nil
            }
        }() else {
            throw CodeBlockExtractorError.noInput
        }
        
        let codeBlocks = try extractCodeBlocks(from: markdownContent, withIdentifier: identifier)
        
        if codeBlocks.isEmpty {
            throw CodeBlockExtractorError.noValidContent
        }
        
        return .array(codeBlocks)
    }
    
    private func extractCodeBlocks(from markdown: String, withIdentifier identifier: String?) throws -> [String] {
        var codeBlocks = [String]()
        
        // Define regex pattern for code blocks
        // Matches ```[optional identifier]
        // [code content]
        // ```
        let pattern = #"```(?:\s*(\w+))?\s*\n([\s\S]*?)\n```"#
        
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = markdown as NSString
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            // Extract the language identifier if present
            let blockIdentifier = match.range(at: 1).location != NSNotFound ? nsString.substring(with: match.range(at: 1)) : nil
            
            // Extract the code content
            let codeContent = nsString.substring(with: match.range(at: 2))
            
            // If an identifier is specified, only include blocks with that identifier
            if let requiredIdentifier = identifier {
                if blockIdentifier == requiredIdentifier {
                    codeBlocks.append(codeContent)
                }
            } else {
                // If no identifier is specified, include all code blocks
                codeBlocks.append(codeContent)
            }
        }
        
        // If an identifier was specified but no matching blocks were found, throw an error
        if let _ = identifier, codeBlocks.isEmpty {
            throw CodeBlockExtractorError.noValidContent
        }
        
        return codeBlocks
    }
}
