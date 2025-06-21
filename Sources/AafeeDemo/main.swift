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
        let agent = try OneShotAgentTool(model: "gpt-4o", prompt: "Extract out the pricing in JSON format")
        let fileWriter = WriteToFileTool(fileName: "pricing.json")
        let agentToSwift = try OneShotAgentTool(model: "gpt-4o", prompt: """
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

        _ = try await flow.execute()
        
        print("PEEKED : \(afterAgentValue)")
    }
}

struct TestMultiStepCommand: AsyncParsableCommand {
    
    func findInstruction(in text: String) -> String? {
        // Use a refined regex pattern to capture only CONTINUE or END
        let pattern = #"\[INSTRUCTION: (CONTINUE|END)\]"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: wholeRange)
            
            // Find the last match
            if let lastMatch = matches.last {
                if let range = Range(lastMatch.range, in: text) {
                    return String(text[range])
                }
            }
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
        }
        return nil
    }

    
    func run() async throws {
        
        let agent = try OneShotAgentTool(model: "gpt-4o",
                                  prompt: """
You're a helpful conversational agent who knows the capital of all countries. You should ask a user for a country, then return the capital of the country they provide.
After each stage you should include an instruction of whether to CONTINUE or END, depending on whether you need input or the conversation is finished. The instruction should be formatted as
`[INSTRUCTION: {CONTINUE | END}]` an example if you're waiting for the user to input a city would be `[INSTRUCTION: CONTINUE]`
"""
        )
        
        let loopedFlow = LoopedStageFlow {
            agent
        } executeNextStep: { prevOutput in
            
            guard let prevOutput = prevOutput else {
                return .stop
            }
            
            print("Prev: \(prevOutput)")
            
            // Check for instruction
            guard let initialOutputText = try? prevOutput.text else {
                return .stop
            }
            
            // Find instruction
            guard let instruction = findInstruction(in: initialOutputText), instruction.contains("CONTINUE") else {
                return .stop
            }
            
            guard let lineInput = readLine() else {
                return .stop
            }
            
            switch prevOutput {
            case .md(let text), .string(let text):
                print("Input: " + text)
                var newInput = text + "City is: \(lineInput)"
                return .proceed(with: .string(newInput))
            default:
                return .stop
            }
        }
        
        _ = try await loopedFlow.execute(.string(""))
    }
}

struct TestMultiStepCommandWithStopGoAgent: AsyncParsableCommand {
    
    func findInstruction(in text: String) -> String? {
        // Use a refined regex pattern to capture only CONTINUE or END
        let pattern = #"\[INSTRUCTION: (CONTINUE|END)\]"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: wholeRange)
            
            // Find the last match
            if let lastMatch = matches.last {
                if let range = Range(lastMatch.range, in: text) {
                    return String(text[range])
                }
            }
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
        }
        return nil
    }

    
    func run() async throws {
        
        let agent = try StopContinueAgentTool(model: "gpt-40", prompt: """
            You're a helpful conversational agent who knows the capital of all countries. You should ask a user for a country, then return the capital of the country they provide.
            """)
        
        let loopedFlow = LoopedStageFlow {
            agent
        } executeNextStep: { prevOutput in
            
            guard let prevOutput = prevOutput else {
                return .stop
            }
            
            print("Prev: \(prevOutput)")
            
            guard case let InOutType.instruction(io) = prevOutput else {
                print("ERROR NOT RUNNING AS INTENDED")
                return .stop
            }
            
            // Find instruction
            guard case let NextStep.continue = io.instruction else {
                return .stop
            }
            
            guard let lineInput = readLine() else {
                return .stop
            }
            
            print("Input: " + io.text)
            let newInput = io.text + "City is: \(lineInput)"
            return .proceed(with: .string(newInput))
        }
        
        _ = try await loopedFlow.execute(.string(""))
    }
}

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct TestToolUsingAgentCommand: AsyncParsableCommand {
    
    func run() async throws {
        // No code
    }
}

public struct ToolCallWrapper: FlowStage {

    
    var agent: FlowStage
    
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        return InOutType.none
    }
    
}


public struct KeywordSearchContainer: FlowStage {
    
    var bucket = [String: String]()
    
    public init(bucket: [String : String] = [String: String]()) {
        self.bucket = bucket
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        guard let input = input, case let InOutType.JSON(string) = input else {
            return .none
        }

        return InOutType.none
    }
}

//#error("Create component that wraps AIAgent to add history")

struct TestCollabMeGatherInfo: AsyncParsableCommand {
    
//    func findInstruction(in text: String) -> String? {
//        // Use a refined regex pattern to capture only CONTINUE or END
//        let pattern = #"\[INSTRUCTION: (CONTINUE|END)\]"#
//        
//        do {
//            let regex = try NSRegularExpression(pattern: pattern, options: [])
//            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
//            let matches = regex.matches(in: text, options: [], range: wholeRange)
//            
//            // Find the last match
//            if let lastMatch = matches.last {
//                if let range = Range(lastMatch.range, in: text) {
//                    return String(text[range])
//                }
//            }
//        } catch {
//            print("Invalid regex pattern: \(error.localizedDescription)")
//        }
//        return nil
//    }

    
    func run() async throws {
        
        let model = "gpt-40" // doesn't work using default
        
//        var msgHistory = [Message]()
        
        let agent = try StopContinueAgentTool(model: model,
                                              prompt: """
            You're an expert in video creation and editing, your goal is to gather the information specified below by conversing with the user. This information will be summarized and later used to create a video. Once you gather this information and have everything required you should stop the conversation and output a summary of the information in a way that can be fed to an LLM. It should specify the category for the information gathered and the choice made by the user.
            
            1) **Vibe Check**:
            When people watch this, what do you want them to feel? Is it more timeless and emotional… or electric and modern?

            2) **Sentimentality Scale (1–10)**:
            Are we leaning Hallmark tearjerker (10), or keeping it light with some heart (5), or mostly fun and playful (2)?

            3) **Artistic Expression vs. Tradition**:
            Do you want this to feel like a dreamy short film with cinematic cuts, music swells, and non-linear storytelling?
            Or are we honoring the classic timeline—rehearsal to send-off—with clean transitions and heartfelt voiceovers?

            4) **Music Direction**: - Which genre feels right for the emotional undercurrent? Choose more than one if needed. 
               - Indie folk 
               - Cinematic piano 
               - Dream pop 
               - Acoustic soul 
               - Instrumental electronic 
               - Funky retro 
               - Or something else entirely?

            5) **Color & Filter:** - What should the footage look like? 
               - Washed pastel, filmic grain (like Wes Anderson)
               - Warm tones with deep contrast (like wedding film classics)
               - Crisp + minimal (light desaturation, almost Scandi feel)
               - Vintage Super 8 inspired (textured and nostalgic)
               - Something moody and modern?

            6) **Captions + Text:** - How do we want to use on-screen text?
               - Poetic one-liners? (“Love like this…” / “She said yes.”)
               - Light narration? (To explain context or names?)
               - Song lyrics or vows transcribed? 
               - Or just minimal, with maybe a title and ending credit?

            
            When you've gathered a response from a user for all the sections above you should generate a summary of what you gathered in a format easily ingestible by an LLM and then end the conversation. An example is shown below
            
            ```summary example
            Thank you for providing all the details! Here's a summary of your preferences for the video creation:

            1) **Vibe Check**: Electric and modern
            2) **Sentimentality Scale**: 5 (light with some heart)
            3) **Artistic Expression vs. Tradition**: Dreamy short film with cinematic cuts and non-linear storytelling
            4) **Music Direction**: Funky retro
            5) **Color & Filter**: Crisp + minimal (light desaturation, almost Scandi feel)
            6) **Captions + Text**: Light narration to explain context or names
            ```
            """) //,
//        preSendMessageModifier: { templateMsgs, inputMsgs  in
//            
//            // If it's the first run add the template Msgs
////            if msgHistory.isEmpty {
////                msgHistory.append(contentsOf: templateMsgs)
////            }
//            
//            msgHistory.append(contentsOf: inputMsgs)
//            
//            // Add the template msgs then the history then the latest input
//            return templateMsgs + msgHistory + inputMsgs
//        },
//        postSendOutputModifier: { text in
//            msgHistory.append(.ai(.text(text)))
//            return text
//        })
        
//        var history: String = ""
        
        let agentWithHistory = HistoryProvider(wrappedStage: agent)
        
        #warning("This should be changed out for a StopContinueAgent with tool calling capability for RAG")
        let oneShotGVIKeywordAgent = try OneShotAgentTool(model: model, prompt: """
            Here’s a summary for creating a video from a collection of videos. You can assume you have access to an archive of videos and can search for video clips that match the details in this summary. You should identify keywords to search the archive for to find the right type of video. 
            """)
        
        
        var loopedFlowOutput: String = ""
        var GVIKeywordOuput: String = ""
        
        let loopedFlow = LoopedStageFlow {
            agentWithHistory
        } executeNextStep: { prevOutput in
            
            guard let prevOutput = prevOutput else {
                return .stop
            }

            
//            print("PREV FULL OUTPUT: \(prevOutput)")
            
            let outputText = (try? prevOutput.text) ?? "No Output"
            print("OUTPUT: " + outputText)
            
            guard case let InOutType.instruction(io) = prevOutput else {
                print("ERROR NOT RUNNING AS INTENDED")
                return .stop
            }
            
            // Find instruction
            guard case let NextStep.continue = io.instruction else {
                return .stop
            }
            
            guard let lineInput = readLine() else {
                return .stop
            }
            
            print("Input: " + lineInput)
            
//            print("------ \n HISTORY" + msgHistory.map({ $0.content.text }).joined(separator: "\n") + "------\n\n")
            
//            let newInput = msgHistory.map({ $0.content.text }).joined(separator: "\n") + io.text + "\(lineInput)"
            
//            msgHistory.append(.ai(.text))
            let newInput = lineInput
            return .proceed(with: .string(newInput))
        }
        
        let fullLinearFlow = LinearFlow {
            loopedFlow
            StagePeekTool(stageInput: CustomBinding(get: {
               return loopedFlowOutput
            }, set: { newValue in
                loopedFlowOutput = newValue
            }))
            oneShotGVIKeywordAgent
            StagePeekTool(stageInput: CustomBinding(get: {
               return GVIKeywordOuput
            }, set: { newValue in
                GVIKeywordOuput = newValue
            }))
        }
        
//        _ = try await loopedFlow.execute(.string(""))
        
        _ = try await fullLinearFlow.execute(.string(""))
        
        print(loopedFlowOutput)
        print(GVIKeywordOuput)
    }
}

struct TestCollabMeCreateVideoWithJ2V: AsyncParsableCommand {
    
    func run() async throws {
        
        let model = "gpt-40" // doesn't work using default
        
        let agent = try! OneShotAgentTool(model: model, prompt: """
            You're an expert in video creation especially with the JSON2Video API. Your task is to take in a bunch of clips along
            with a description of what the video should be like and output JSON dictating how to edit the video that can be sent to the
            JSON2Video API.
            """)
    }
    
}

struct RandomClipPicker: FlowStage {

    
    let clips = ["https://drive.google.com/file/d/1N79_oXdsVqDkz4PEa1GDNtesLuTff_ye/view?usp=drive_link",
                 "https://drive.google.com/file/d/1wIGXbERN_D9N-6Mx7GUbOfMtjj88_gpF/view?usp=drive_link",
                 "https://drive.google.com/file/d/1dSHu4j_tXEkbSluSaci97WbJADueY6GF/view?usp=drive_link",
                 "https://drive.google.com/file/d/1v_l_4j74mSta0rUumr9g18vcTopXle4I/view?usp=drive_link",
                 "https://drive.google.com/file/d/1aLRa8LYCM-8H1l_TSVC9DBMt2njqkJv7/view?usp=drive_link",
                 "https://drive.google.com/file/d/1LyzBllHXqOsOzmTD3dIu7uPNywhLUOg0/view?usp=drive_link",
                 "https://drive.google.com/file/d/1cCxeWSnC8_G43ga6gf4-0r299aEWgP0c/view?usp=drive_link", 
                 "https://drive.google.com/file/d/1Moq9D9iwfC2YUzCbvxkHPJrdd3zBGpL1/view?usp=drive_link",
                 "https://drive.google.com/file/d/1yKBZRuPUIXpPyFlc-tx0gaok7afTxrXy/view?usp=drive_link",
                 "https://drive.google.com/file/d/1AC4XPTOyFiS3PvbgENC-BGcpvNZke-ju/view?usp=drive_link",
                 "https://drive.google.com/file/d/1qFcyBsamEjSgYG3ketd1FcfiFq0OZT69/view?usp=drive_link"
    ]
    
    func pickRandomElements<T>(from array: [T], count: Int) -> [T] {
        // Ensure that the count doesn't exceed the number of elements in the array
        guard count <= array.count else {
            return array
        }
        
        return Array(array.shuffled().prefix(count))
    }
    
    func execute(_ input: InOutType?) async throws -> InOutType {
        let randomClips = pickRandomElements(from: clips, count: 4)
        let asJSONData = try JSONSerialization.data(withJSONObject: randomClips)
        guard let jsonString = String(data: asJSONData, encoding: .utf8) else {
            throw NSError(domain: "Couldn't turn random clips to JSON string", code: 0)
        }
        return InOutType.JSON(jsonString)
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
//try await TestFlowCommand().run()

//try await TestMultiStepCommand().run()

//try await TestMultiStepCommandWithStopGoAgent().run()

//try await TestCollabMeGatherInfo().run()


// Test MCP

let jsonConfig = """
    {
      "name": "swift-mcp-server-example",
        "executablePath": "/Users/peterliddle/Library/Developer/Xcode/DerivedData/SwiftMCPServerExample-evrhsjumswrkvyfjqxkqjvqvffat/Build/Products/Debug/SwiftMCPServerExample",
        "arguments": [],
        "environment": {}
    }
    """

let decoder = JSONDecoder()
let config = try decoder.decode(LocalMCPServerConfig.self, from: jsonConfig.data(using: .ascii)!)

//let config = LocalMCPServerConfig(name: "SwiftServerTest",
let mcp = LocalMCProcess(config: config)
let client = try await mcp.start()
print(try await client.listTools())

