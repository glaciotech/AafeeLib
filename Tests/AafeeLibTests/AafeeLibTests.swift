import XCTest
@testable import AafeeLib
import SwiftyJsonSchema

final class AafeeLibTests: XCTestCase {

    func testOutputActionDecoding() async throws {
        
        let jsonFragment = """
            {
              "useTool": {
                "_0": {
                  "serverName": "SwiftMCPServerExample",
                  "toolName": "echo"
                },
                "_1": {}
              }
            }
            """
        
        let decoded = try JSONDecoder().decode(GenericToolCapableAgent.OutputAction.self, from: jsonFragment.data(using: .ascii)!)
        print(decoded)
    }
    
    func testOutputActionSchemaGeneration() async throws {
        let schemas = JsonSchemaCreator.createJSONSchema(from: GenericToolCapableAgent.OutputAction.self)
        print(schemas)
    }
    
    func testBasicStringEnumSchemaGeneration() async throws {
        
        enum TestEnumAsString: ProducesUnionJSONSchema {
            case x
            case y
            case z
        }
        
        let schemas = JsonSchemaCreator.createJSONSchema(from: TestEnumAsString.self)
        print(schemas)
    }
    
    func testBasicIntEnumSchemaGeneration() async throws {
        
        enum TestEnumAsInt: Int, ProducesUnionJSONSchema {
            case x = 0
            case y
            case z
        }
        
        let schemas = try JSONSchemaGenerator().generateSchema(from: TestEnumAsInt.self)
        print(schemas)
    }
    
    func testOutputActionSchemaGenerationWithNewBuilder() async throws {
        let schemas = try JSONSchemaGenerator().generateSchema(from: GenericToolCapableAgent.OutputAction.self)
        
        print(schemas)
    }
    
    
    func testFlowStageHasInjectedEnvironmentValue() async throws {
        
        ProcessInfo.processInfo.environment[OneShotAgentTool.AGENT_API_KEY] = "TestKey"
        let agent = try OneShotAgentTool(model: "gpt4o", prompt: "")
        
        
    }
    
    func testFlowStagePicksUpEnvironmentValueFromProcessEnvironment() async throws {
        
    }
}

