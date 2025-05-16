import Foundation
import AafeeLib
import ArgumentParser
import Logging


import SwiftyPrompts
import SwiftyPrompts_OpenAI
import SwiftyJsonSchema

// Configure the logging system
LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .info // Default log level
    return handler
}

// Define the root command
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct AafeeCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "aafee",
        abstract: "AafeeLib Demo Application",
        subcommands: [TestFlowCommand.self, TestToolUsingAgentCommand.self],//, LogLevelCommand.self],
        defaultSubcommand: TestFlowCommand.self
    )
}


@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct TestFlowCommand: AsyncParsableCommand {
    
    
    func run() async throws {

        let fc = try FirecrawlTool(url: "https://platform.openai.com/docs/pricing")
        let agent = try AgentTool(model: "gpt-4o", prompt: "Extract out the pricing in JSON format")
        let fileWriter = WriteToFileTool(fileName: "pricing.json")
        let agentToSwift = try AgentTool(model: "gpt-4o", prompt: """
        Convert the json for the latest models into a dictionary of initalized swift structs with data from the json. The struct should look like this
        ```swift
            struct ModelPricing {
                var modelName: String
                var inputPricePer1M: Double
                var outputPricePer1M: Double
            }
        ```
""")
        
        var afterAgentValue: String = ""

        let flow = LinearFlow {
            fc
            agent
            StagePeekTool(stageInput: CustomBinding(get: {
               return afterAgentValue
            }, set: { newValue in
                afterAgentValue = newValue
            }))
            fileWriter
            agentToSwift
            WriteToFileTool(fileName: "openAIPricing.swift")
        }

        try await flow.run()
        
        print("PEEKED : \(afterAgentValue)")
    }
}

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct TestToolUsingAgentCommand: AsyncParsableCommand {
    
    func run() async throws {
        // No code
    }
    
}

//// Define a command to change log level
//struct LogLevelCommand: ParsableCommand {
//    static var configuration = CommandConfiguration(
//        commandName: "loglevel",
//        abstract: "Set the log level for the application"
//    )
//    
//    @Argument(help: "Log level (trace, debug, info, notice, warning, error, critical)")
//    var level: String
//    
//    func run() throws {
//        guard let logLevel = Logger.Level(rawValue: level.lowercased()) else {
//            print("Invalid log level: \(level)")
//            print("Valid options: trace, debug, info, notice, warning, error, critical")
//            return
//        }
//        
//        // Create a logger with the specified log level
//        var logger = Logger(label: "com.glacio.aafeedemo")
//        logger.logLevel = logLevel
//        
//        // Create an instance of our library with the logger
//        let lib = AafeeLib()
//        
//        // Log a message at the specified level
////        lib.log(level: logLevel, message: "Log level set to \(logLevel)")
//        print("Log level set to \(logLevel)")
//    }
//}

// Run the command
try await TestFlowCommand().run()

