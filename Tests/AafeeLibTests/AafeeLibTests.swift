import XCTest
@testable import AafeeLib
import SwiftyJsonSchema

final class AafeeLibTests: XCTestCase {

    
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
}

