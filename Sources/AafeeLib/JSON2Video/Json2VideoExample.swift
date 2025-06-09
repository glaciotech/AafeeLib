import Foundation
//
///// Examples of using the Json2Video API client
//public class Json2VideoExample {
//    
//    /// Example of creating a simple movie with a text element
//    public static func createSimpleTextMovie(apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Create a simple movie with a text element using strongly-typed model
//        let textElement = TextElement(
//            text: "Hello, Json2Video!",
//            position: "center",
//            fontSize: 48,
//            fontFamily: "Arial",
//            color: "#FFFFFF"
//        )
//        
//        // For backward compatibility, we still use the callback-based API
//        client.createSimpleMovie(element: textElement) { result in
//            switch result {
//            case .success(let response):
//                print("Movie created successfully!")
//                print("Project ID: \(response.project)")
//                
//                // Check the status of the movie
//                client.checkMovieStatus(projectId: response.project) { statusResult in
//                    switch statusResult {
//                    case .success(let statusResponse):
//                        if statusResponse.movie.status == "done" {
//                            if let url = statusResponse.movie.url {
//                                completion(.success(url))
//                            } else {
//                                completion(.failure(Json2VideoError.apiError("Movie URL not available")))
//                            }
//                        } else {
//                            completion(.success("Movie is being processed. Status: \(statusResponse.movie.status)"))
//                        }
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    /// Example of creating a movie with multiple scenes using the builder
//    public static func createMultiSceneMovie(apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Use the builder to create a movie with multiple scenes using strongly-typed models
//        let builder = Json2VideoBuilder(resolution: "full-hd", quality: "high")
//        
//        // Add first scene with text
//        builder.addScene(duration: 5, background: "#000000")
//            .addText(text: "Scene 1", position: "center", fontSize: 48, fontFamily: "Arial", color: "#FFFFFF")
//        
//        // Add second scene with image
//        builder.addScene(duration: 5, background: "#333333")
//            .addImage(src: "https://example.com/image.jpg", position: "center")
//            .addText(text: "Scene 2", position: "bottom", fontSize: 36, fontFamily: "Arial", color: "#FFFFFF")
//        
//        // Add third scene with video
//        builder.addScene(duration: -1, background: "#666666")
//            .addVideo(src: "https://example.com/video.mp4", position: "center")
//            .addText(text: "Scene 3", position: "top", fontSize: 36, fontFamily: "Arial", color: "#FFFFFF")
//        
//        // Build the movie model and convert to JSON
//        let movie = builder.build()
//        let movieJSON = builder.toJSON()
//        
//        // Create the movie (using callback API for backward compatibility)
//        client.createMovie(movieJSON: movieJSON) { result in
//            switch result {
//            case .success(let response):
//                print("Movie created successfully!")
//                print("Project ID: \(response.project)")
//                
//                // Check the status of the movie
//                client.checkMovieStatus(projectId: response.project) { statusResult in
//                    switch statusResult {
//                    case .success(let statusResponse):
//                        if statusResponse.movie.status == "done" {
//                            if let url = statusResponse.movie.url {
//                                completion(.success(url))
//                            } else {
//                                completion(.failure(Json2VideoError.apiError("Movie URL not available")))
//                            }
//                        } else {
//                            completion(.success("Movie is being processed. Status: \(statusResponse.movie.status)"))
//                        }
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    /// Example of creating a movie with async/await (iOS 13+, macOS 10.15+)
//    @available(iOS 13.0, macOS 10.15, *)
//    public static func createMovieAsync(apiKey: String) async throws -> String {
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Use the builder to create a movie with strongly-typed models
//        let builder = Json2VideoBuilder(resolution: "full-hd")
//        
//        // Add a scene with text and audio
//        builder.addScene(duration: -1, background: "#000000")
//            .addText(text: "Hello, Json2Video!", position: "center", fontSize: 48)
//            .addAudio(src: "https://example.com/audio.mp3")
//        
//        // Build the movie model
//        let movie = builder.build()
//        
//        // Create the movie using async/await API
//        // The builder's build() method now returns a Movie model, which we can pass directly
//        let response = try await client.createMovie(movie: movie)
//        print("Movie created successfully!")
//        print("Project ID: \(response.project)")
//        
//        // Check the status of the movie using async/await API
//        let statusResponse = try await client.checkMovieStatus(projectId: response.project)
//        
//        if statusResponse.movie.status == "done" {
//            if let url = statusResponse.movie.url {
//                return url
//            } else {
//                throw Json2VideoError.apiError("Movie URL not available")
//            }
//        } else {
//            return "Movie is being processed. Status: \(statusResponse.movie.status)"
//        }
//    }
//    
//    /// Example of creating a slideshow with images
//    public static func createSlideshow(apiKey: String, imageUrls: [String], completion: @escaping (Result<String, Error>) -> Void) {
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Use the builder to create a slideshow with strongly-typed models
//        let builder = Json2VideoBuilder(resolution: "full-hd")
//        
//        // Add a scene for each image
//        for (index, imageUrl) in imageUrls.enumerated() {
//            builder.addScene(duration: 3, background: "#000000")
//                .addImage(src: imageUrl, position: "center")
//                .addText(text: "Image \(index + 1)", position: "bottom", fontSize: 36)
//        }
//        
//        // Build the movie model and convert to JSON
//        let movie = builder.build()
//        let movieJSON = builder.toJSON()
//        
//        // Create the movie (using callback API for backward compatibility)
//        client.createMovie(movieJSON: movieJSON) { result in
//            switch result {
//            case .success(let response):
//                print("Slideshow created successfully!")
//                print("Project ID: \(response.project)")
//                
//                // Check the status of the movie
//                client.checkMovieStatus(projectId: response.project) { statusResult in
//                    switch statusResult {
//                    case .success(let statusResponse):
//                        if statusResponse.movie.status == "done" {
//                            if let url = statusResponse.movie.url {
//                                completion(.success(url))
//                            } else {
//                                completion(.failure(Json2VideoError.apiError("Movie URL not available")))
//                            }
//                        } else {
//                            completion(.success("Slideshow is being processed. Status: \(statusResponse.movie.status)"))
//                        }
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    /// A comprehensive example showcasing the modern async/await API with strongly-typed models
//    /// - Parameters:
//    ///   - apiKey: Your Json2Video API key
//    ///   - title: The title for the movie
//    ///   - imageUrls: URLs of images to include in the movie
//    ///   - audioUrl: URL of background audio to include
//    /// - Returns: The URL of the rendered movie or a status message
//    @available(iOS 13.0, macOS 10.15, *)
//    public static func createComprehensiveMovieAsync(
//        apiKey: String,
//        title: String,
//        imageUrls: [String],
//        audioUrl: String
//    ) async throws -> String {
//        let client = Json2VideoClient(apiKey: apiKey)
//        
//        // Create a new movie with strongly-typed models
//        let builder = Json2VideoBuilder(resolution: "full-hd", quality: "high")
//        
//        // Set movie-level properties
//        builder.setExport(format: "mp4", fps: 30)
//        
//        // Add an intro scene with title
//        builder.addScene(duration: 3, background: "#1A1A1A")
//            .addText(
//                text: title,
//                position: "center",
//                fontSize: 64,
//                fontFamily: "Montserrat",
//                color: "#FFFFFF"
//            )
//        
//        // Add scenes for each image with transitions
//        for (index, imageUrl) in imageUrls.enumerated() {
//            let scene = builder.addScene(duration: 4, background: "#000000")
//            
//            // Add the image
//            scene.addImage(src: imageUrl, position: "center")
//            
//            // Add caption
//            scene.addText(
//                text: "Image \(index + 1)",
//                position: "bottom",
//                fontSize: 36,
//                fontFamily: "Roboto",
//                color: "#FFFFFF"
//            )
//            
//            // Add voice narration for this image
//            scene.addVoice(
//                text: "This is image number \(index + 1) in our presentation.",
//                voice: "en-US-Standard-B"
//            )
//        }
//        
//        // Add an outro scene
//        builder.addScene(duration: 3, background: "#1A1A1A")
//            .addText(
//                text: "Thank You",
//                position: "center",
//                fontSize: 64,
//                fontFamily: "Montserrat",
//                color: "#FFFFFF"
//            )
//        
//        // Add background audio across all scenes
//        builder.addScene(duration: 0)
//            .addAudio(src: audioUrl)
//        
//        // Build the movie model
//        let movie = builder.build()
//        
//        // Create the movie using async/await API
//        let response = try await client.createMovie(movie: movie)
//        print("Movie created successfully!")
//        print("Project ID: \(response.project)")
//        
//        // Poll for movie status until complete or timeout
//        var attempts = 0
//        let maxAttempts = 10
//        
//        while attempts < maxAttempts {
//            let statusResponse = try await client.checkMovieStatus(projectId: response.project)
//            
//            if statusResponse.movie.status == "done" {
//                if let url = statusResponse.movie.url {
//                    return url
//                } else {
//                    throw Json2VideoError.apiError("Movie URL not available")
//                }
//            } else if statusResponse.movie.status == "error" {
//                throw Json2VideoError.apiError("Movie rendering failed: \(statusResponse.movie.message ?? "Unknown error")")
//            }
//            
//            // Wait before checking again
//            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
//            attempts += 1
//        }
//        
//        return "Movie is still processing after \(maxAttempts) status checks. Project ID: \(response.project)"
//    }
//}
