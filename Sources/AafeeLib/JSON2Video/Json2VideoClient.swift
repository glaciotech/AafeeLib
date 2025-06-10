#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Foundation


/// A client for interacting with the Json2Video API
public class Json2VideoClient {
    
    
    /// Base URL for the Json2Video API
    private let baseURL = "https://api.json2video.com/v2"
    /// API key for authentication
    private let apiKey: String
    /// URLSession for making network requests
    private let session: URLSession
    
    
    private lazy var decoder = {
        var decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    private let encoder = JSONEncoder()
    
    /// Initializes a new Json2Video API client
    /// - Parameter apiKey: Your Json2Video API key
    /// - Parameter session: URLSession to use for network requests (defaults to shared session)
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    /// Creates a new movie rendering job using a strongly-typed Movie model
    /// - Parameter movie: Movie model defining the movie structure
    /// - Returns: The movie creation response
    /// - Throws: Json2VideoError if the request fails
    @available(iOS 13.0, macOS 10.15, *)
    public func createMovie(movie: Movie) async throws -> MovieCreationResponse {
        guard let url = URL(string: "\(baseURL)/movies") else {
            throw Json2VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(movie)
        } catch {
            throw Json2VideoError.invalidJSON(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Json2VideoError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Json2VideoError.httpError(httpResponse.statusCode, data)
        }
        
        do {
            return try decoder.decode(MovieCreationResponse.self, from: data)
        } catch {
            throw Json2VideoError.decodingError(error)
        }
    }
    
    /// Creates a new movie rendering job using a strongly-typed Movie model (callback version for backward compatibility)
    /// - Parameters:
    ///   - movie: Movie model defining the movie structure
    ///   - completion: Callback with the result of the operation
    public func createMovie(movie: Movie, completion: @escaping (Result<MovieCreationResponse, Json2VideoError>) -> Void) {
        guard #available(iOS 13.0, macOS 10.15, *) else {
            completion(.failure(.invalidURL)) // Cannot use async/await on earlier versions
            return
        }
        
        Task {
            do {
                let result = try await createMovie(movie: movie)
                completion(.success(result))
            } catch {
                if let error = error as? Json2VideoError {
                    completion(.failure(error))
                } else {
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }
    
    /// Creates a new movie rendering job
    /// - Parameter movieJSON: JSON object defining the movie structure
    /// - Returns: The movie creation response
    /// - Throws: Json2VideoError if the request fails
    @available(iOS 13.0, macOS 10.15, *)
    public func createMovie(movieJSON: [String: Any]) async throws -> MovieCreationResponse {
        guard let url = URL(string: "\(baseURL)/movies") else {
            throw Json2VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: movieJSON)
        } catch {
            throw Json2VideoError.invalidJSON(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Json2VideoError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Json2VideoError.httpError(httpResponse.statusCode, data)
        }
        
        do {
            return try decoder.decode(MovieCreationResponse.self, from: data)
        } catch {
            throw Json2VideoError.decodingError(error)
        }
    }
    
    /// Checks the status of a movie rendering job
    /// - Parameter projectId: The project ID of the movie rendering job
    /// - Returns: The movie status response
    /// - Throws: Json2VideoError if the request fails
    @available(iOS 13.0, macOS 10.15, *)
    public func checkMovieStatus(projectId: String) async throws -> MovieStatusResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/movies") else {
            throw Json2VideoError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "project", value: projectId)]
        
        guard let url = urlComponents.url else {
            throw Json2VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Json2VideoError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Json2VideoError.httpError(httpResponse.statusCode, data)
        }
        
        do {
            return try decoder.decode(MovieStatusResponse.self, from: data)
        } catch {
            throw Json2VideoError.decodingError(error)
        }
    }
    
    /// Checks the status of a movie rendering job (callback version for backward compatibility)
    /// - Parameter projectId: The project ID of the movie rendering job
    /// - Parameter completion: Callback with the result of the operation
    public func checkMovieStatus(projectId: String, completion: @escaping (Result<MovieStatusResponse, Json2VideoError>) -> Void) {
        guard #available(iOS 13.0, macOS 10.15, *) else {
            completion(.failure(.invalidURL)) // Cannot use async/await on earlier versions
            return
        }
        
        Task {
            do {
                let result = try await checkMovieStatus(projectId: projectId)
                completion(.success(result))
            } catch {
                if let error = error as? Json2VideoError {
                    completion(.failure(error))
                } else {
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }
    
//    /// Helper method to create a simple movie with a single scene and element using strongly-typed models
//    /// - Parameters:
//    ///   - element: The strongly-typed element to include in the movie (image, video, text, etc.)
//    ///   - resolution: The resolution of the movie (default: "full-hd")
//    ///   - quality: The quality of the movie (default: "high")
//    ///   - duration: The duration of the scene in seconds (-1 for auto-duration)
//    /// - Returns: The movie creation response
//    /// - Throws: Json2VideoError if the request fails
//    @available(iOS 13.0, macOS 10.15, *)
//    public func createSimpleMovie<T: Element>(
//        element: T,
//        resolution: String = "full-hd",
//        quality: String = "high",
//        duration: Double = -1
//    ) async throws -> MovieCreationResponse {
//        // Create a movie model with a single scene containing the element
//        var scene = Scene(duration: duration)
//        scene.elements = [element]
//        
//        var movie = Movie(scenes: [scene])
//        movie.resolution = resolution
//        movie.quality = quality
//        
//        return try await createMovie(movie: movie)
//    }
//    
//    /// Helper method to create a simple movie with a single scene and element
//    /// - Parameters:
//    ///   - element: The element to include in the movie (image, video, text, etc.)
//    ///   - resolution: The resolution of the movie (default: "full-hd")
//    ///   - quality: The quality of the movie (default: "high")
//    ///   - duration: The duration of the scene in seconds (-1 for auto-duration)
//    /// - Returns: The movie creation response
//    /// - Throws: Json2VideoError if the request fails
//    @available(iOS 13.0, macOS 10.15, *)
//    public func createSimpleMovie(
//        element: [String: String],
//        resolution: String = "full-hd",
//        quality: String = "high",
//        duration: Double = -1
//    ) async throws -> MovieCreationResponse {
//        var movieJSON: [String: Any] = [
//            "resolution": resolution,
//            "quality": quality,
//            "scenes": [
//                [
//                    "duration": duration,
//                    "elements": [element]
//                ]
//            ]
//        ]
//        
//        return try await createMovie(movieJSON: movieJSON)
//    }
//    
//    /// Helper method to create a simple movie with a single scene and element using strongly-typed models (callback version for backward compatibility)
//    /// - Parameters:
//    ///   - element: The strongly-typed element to include in the movie (image, video, text, etc.)
//    ///   - resolution: The resolution of the movie (default: "full-hd")
//    ///   - quality: The quality of the movie (default: "high")
//    ///   - duration: The duration of the scene in seconds (-1 for auto-duration)
//    ///   - completion: Callback with the result of the operation
//    public func createSimpleMovie<T: Element>(
//        element: T,
//        resolution: String = "full-hd",
//        quality: String = "high",
//        duration: Double = -1,
//        completion: @escaping (Result<MovieCreationResponse, Json2VideoError>) -> Void
//    ) {
//        guard #available(iOS 13.0, macOS 10.15, *) else {
//            completion(.failure(.invalidURL)) // Cannot use async/await on earlier versions
//            return
//        }
//        
//        Task {
//            do {
//                let result = try await createSimpleMovie(
//                    element: element,
//                    resolution: resolution,
//                    quality: quality,
//                    duration: duration
//                )
//                completion(.success(result))
//            } catch {
//                if let error = error as? Json2VideoError {
//                    completion(.failure(error))
//                } else {
//                    completion(.failure(.networkError(error)))
//                }
//            }
//        }
//    }
    
//    /// Helper method to create a simple movie with a single scene and element (callback version for backward compatibility)
//    /// - Parameters:
//    ///   - element: The element to include in the movie (image, video, text, etc.)
//    ///   - resolution: The resolution of the movie (default: "full-hd")
//    ///   - quality: The quality of the movie (default: "high")
//    ///   - duration: The duration of the scene in seconds (-1 for auto-duration)
//    ///   - completion: Callback with the result of the operation
//    public func createSimpleMovie(
//        element: [String: String],
//        resolution: String = "full-hd",
//        quality: String = "high",
//        duration: Double = -1,
//        completion: @escaping (Result<MovieCreationResponse, Json2VideoError>) -> Void
//    ) {
//        guard #available(iOS 13.0, macOS 10.15, *) else {
//            completion(.failure(.invalidURL)) // Cannot use async/await on earlier versions
//            return
//        }
//        
//        Task {
//            do {
//                let result = try await createSimpleMovie(
//                    element: element,
//                    resolution: resolution,
//                    quality: quality,
//                    duration: duration
//                )
//                completion(.success(result))
//            } catch {
//                if let error = error as? Json2VideoError {
//                    completion(.failure(error))
//                } else {
//                    completion(.failure(.networkError(error)))
//                }
//            }
//        }
//    }
}
