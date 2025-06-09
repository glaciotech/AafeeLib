import XCTest
@testable import AafeeLib
import SwiftyJsonSchema

final class Json2VideoTests: XCTestCase {
    
    // Replace with your actual API key for testing
    private let apiKey = Environment.get("J2V_API_KEY")!
    
//    func testCreateSimpleMovie() {
//        let expectation = XCTestExpectation(description: "Create simple movie")
//        
//        Json2VideoExample.createSimpleTextMovie(apiKey: apiKey) { result in
//            switch result {
//            case .success(let message):
//                print("Success: \(message)")
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to create movie: \(error.localizedDescription)")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    func testCreateMultiSceneMovie() {
//        let expectation = XCTestExpectation(description: "Create multi-scene movie")
//        
//        Json2VideoExample.createMultiSceneMovie(apiKey: apiKey) { result in
//            switch result {
//            case .success(let message):
//                print("Success: \(message)")
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to create movie: \(error.localizedDescription)")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    func testCreateSlideshow() {
//        let expectation = XCTestExpectation(description: "Create slideshow")
//        
//        let imageUrls = [
//            "https://example.com/image1.jpg",
//            "https://example.com/image2.jpg",
//            "https://example.com/image3.jpg"
//        ]
//        
//        Json2VideoExample.createSlideshow(apiKey: apiKey, imageUrls: imageUrls) { result in
//            switch result {
//            case .success(let message):
//                print("Success: \(message)")
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to create slideshow: \(error.localizedDescription)")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    @available(macOS 10.15, *)
//    func testCreateMovieAsync() async {
//        do {
//            let result = try await Json2VideoExample.createMovieAsync(apiKey: apiKey)
//            print("Success: \(result)")
//        } catch {
//            XCTFail("Failed to create movie asynchronously: \(error.localizedDescription)")
//        }
//    }
    
    // MARK: - Custom Movie Creation Tests
    
    func testCreateCustomMovie() async throws {
        let expectation = XCTestExpectation(description: "Create custom movie")
        
        let client = Json2VideoClient(apiKey: apiKey)
        
        // Create a custom movie JSON
        let movieJSON: [String: Any] = [
            "resolution": "full-hd",
            "quality": "high",
            "scenes": [
                [
                    "duration": 5.0,
                    "elements": [
                        [
                            "type": "text",
                            "text": "Custom Movie Test",
                            "position": "center",
                            "fontSize": 48,
                            "fontFamily": "Arial",
                            "color": "#FFFFFF"
                        ]
                    ]
                ]
            ]
        ]
        
        let result = try await client.createMovie(movieJSON: movieJSON)
        
        print(result)
        
        let status = try await client.checkMovieStatus(projectId: result.project)
        
        print(status)
    }
    
    func testCreateCustomMovieWithClips() async throws {
        
        let client = Json2VideoClient(apiKey: apiKey)
        
        let rawJSON = """
            {
              "resolution": "full-hd",
              "quality": "high",
              "scenes": [
                {
                  "duration": -1,
                  "elements": [
                    {
                      "type": "video",
                      "src": "https://drive.google.com/file/d/1N79_oXdsVqDkz4PEa1GDNtesLuTff_ye/view",
                      "position": "center"
                    },
                    {
                      "type": "text",
                      "text": "Clip 1",
                      "position": "bottom",
                      "fontSize": 48,
                      "fontFamily": "Arial",
                      "color": "#FFFFFF"
                    }
                  ]
                },
                {
                  "duration": 1,
                  "elements": [
                    {
                      "type": "text",
                      "text": "Transitioning...",
                      "position": "center",
                      "fontSize": 36,
                      "fontFamily": "Arial",
                      "color": "#FFFFFF"
                    }
                  ]
                },
                {
                  "duration": -1,
                  "elements": [
                    {
                      "type": "video",
                      "src": "https://drive.google.com/file/d/1dSHu4j_tXEkbSluSaci97WbJADueY6GF/view",
                      "position": "center"
                    },
                    {
                      "type": "text",
                      "text": "Clip 2",
                      "position": "bottom",
                      "fontSize": 48,
                      "fontFamily": "Arial",
                      "color": "#FFFFFF"
                    }
                  ]
                },
                {
                  "duration": 1,
                  "elements": [
                    {
                      "type": "text",
                      "text": "Transitioning...",
                      "position": "center",
                      "fontSize": 36,
                      "fontFamily": "Arial",
                      "color": "#FFFFFF"
                    }
                  ]
                },
                {
                  "duration": -1,
                  "elements": [
                    {
                      "type": "video",
                      "src": "https://drive.google.com/file/d/1aLRa8LYCM-8H1l_TSVC9DBMt2njqkJv7/view",
                      "position": "center"
                    },
                    {
                      "type": "text",
                      "text": "Clip 3",
                      "position": "bottom",
                      "fontSize": 48,
                      "fontFamily": "Arial",
                      "color": "#FFFFFF"
                    }
                  ]
                }
              ]
            }
            """
        
        let asJSONOb = try JSONSerialization.jsonObject(with: rawJSON.data(using: .utf8)!) as! [String: Any]
        let movieJSON = asJSONOb
        
//        // Create a custom movie JSON
//        let movieJSON: [String: Any] = [
//            "resolution": "full-hd",
//            "quality": "high",
//            "scenes": [
//                [
//                    "duration": 5.0,
//                    "elements": [
//                        [
//                            "type": "text",
//                            "text": "Custom Movie Test",
//                            "position": "center",
//                            "fontSize": 48,
//                            "fontFamily": "Arial",
//                            "color": "#FFFFFF"
//                        ]
//                    ]
//                ]
//            ]
//        ]
        
        let result = try await client.createMovie(movieJSON: movieJSON)
        
        print(result)
        
        let status = try await client.checkMovieStatus(projectId: result.project)
        
        print(status)
    }
    
    func testJ2VSchemaGeneration() async throws {
        
        let schema = try JsonSchemaCreator.createJSONSchema(for: Movie.self)
        print(schema)
    }
    
    
    func testGetSpecificMovieStatus() async throws {
        
        let movieId = "dENdvD0uyfuGfpHx" //"BPv7aEEBAEsQYj9h"
        
        let client = Json2VideoClient(apiKey: apiKey)
        let status = try await client.checkMovieStatus(projectId: movieId)
        print(status)
        
    }
//
//    func testCreateMovieWithBuilder() {
//        let expectation = XCTestExpectation(description: "Create movie with builder")
//        
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Use the builder to create a movie
//        let builder = Json2VideoBuilder(resolution: "full-hd")
//            .setQuality("high")
//            .setCache(true)
//            .setClientData(["test": "value"])
//            .setComment("Test movie created with builder")
//        
//        // Add a scene with text
//        builder.addScene(duration: 5, background: "#000000")
//            .setId("scene1")
//            .setComment("First scene")
//            .addText(text: "Built with Json2VideoBuilder", position: "center", fontSize: 48)
//        
//        // Build the movie JSON
//        let movieJSON = builder.build()
//        
//        client.createMovie(movieJSON: movieJSON) { result in
//            switch result {
//            case .success(let response):
//                print("Movie created successfully!")
//                print("Project ID: \(response.project)")
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to create movie with builder: \(error.localizedDescription)")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
}
