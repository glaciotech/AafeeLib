import Foundation
import SwiftyPrompts
import SwiftyJsonSchema

extension SchemaInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self.wrappedValue)"
    }
}

/// Response from creating a new movie
public struct MovieCreationResponse: Codable {
    /// Whether the request was successful
    @SchemaInfo(description: "Whether the request was successful")
    public var success: Bool = false
    /// The project ID of the created movie
    @SchemaInfo(description: "The project ID of the created movie")
    public var project: String = ""
    /// The timestamp when the movie was created
    @SchemaInfo(description: "The timestamp when the movie was created")
    public var timestamp: String = ""
    
    public init(success: Bool = false, project: String = "", timestamp: String = "") {
        self.success = success
        self.project = project
        self.timestamp = timestamp
    }
}

/// Response from checking the status of a movie
public struct MovieStatusResponse: Codable {
    
    /// Whether the request was successful
    @SchemaInfo(description: "Whether the request was successful")
    public var success: Bool = false
    
    /// Information about the movie
    @SchemaInfo(description: "Information about the movie")
    public var movie: MovieInfo = MovieInfo()
    
    /// Information about the remaining quota
    @SchemaInfo(description: "Information about the remaining quota")
    public var remainingQuota: RemainingQuota = RemainingQuota()
    
    public init(success: Bool = false, movie: MovieInfo = MovieInfo(), remainingQuota: RemainingQuota = RemainingQuota()) {
        self.success = success
        self.movie = movie
        self.remainingQuota = remainingQuota
    }
}


/// Information about a movie
public struct MovieInfo: Codable {
    
    /// Whether the movie rendering was successful
    @SchemaInfo(description: "Whether the movie rendering was successful")
    public var success: Bool = false
    
    /// The current status of the movie rendering job
    @SchemaInfo(description: "The current status of the movie rendering job (e.g., 'done', 'processing')")
    public var status: String = ""
    
    /// Error message, if any
    @SchemaInfo(description: "Error message, if any")
    public var message: String = ""
    
    /// The project ID of the movie
    @SchemaInfo(description: "The project ID of the movie")
    public var project: String = ""
    
    /// The URL where the rendered video can be downloaded
    @SchemaInfo(description: "The URL where the rendered video can be downloaded")
    public var url: String? = nil
    
    /// The URL where the generated subtitles can be downloaded
    @SchemaInfo(description: "The URL where the generated subtitles can be downloaded")
    public var ass: Bool = false
    
    /// The date and time the job was initiated
    @SchemaInfo(description: "The date and time the job was initiated")
    public var createdAt: Date? = nil
    
    /// The date and time the job completed
    @SchemaInfo(description: "The date and time the job completed")
    public var endedAt: Date? = nil
    
    /// The duration of the rendered video in seconds
    @SchemaInfo(description: "The duration of the rendered video in seconds")
    public var duration: Double? = nil
    
    /// The size of the rendered video file in bytes
    @SchemaInfo(description: "The size of the rendered video file in bytes")
    public var size: Int? = nil
    
    /// The width of the rendered video in pixels
    @SchemaInfo(description: "The width of the rendered video in pixels")
    public var width: Int? = nil
    
    /// The height of the rendered video in pixels
    @SchemaInfo(description: "The height of the rendered video in pixels")
    public var height: Int? = nil
    
    @SchemaInfo(description: "Is the video a draft")
    public var draft: Bool = false
    
    /// The time it took to render the video in seconds
    @SchemaInfo(description: "The time it took to render the video in seconds")
    public var renderingTime: Int? = nil
    
    public init(
        success: Bool = false,
        status: String = "",
        message: String = "",
        project: String = "",
        url: String? = nil,
        ass: Bool = false,
        createdAt: Date? = nil,
        endedAt: Date? = nil,
        duration: Double? = nil,
        size: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        draft: Bool = false,
        renderingTime: Int? = nil
    ) {
        self.success = success
        self.status = status
        self.message = message
        self.project = project
        self.url = url
        self.ass = ass
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.duration = duration
        self.size = size
        self.width = width
        self.height = height
        self.draft = draft
        self.renderingTime = renderingTime
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.status = try container.decode(String.self, forKey: .status)
        self.message = try container.decode(String.self, forKey: .message)
        self.project = try container.decode(String.self, forKey: .project)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.ass = try container.decode(Bool.self, forKey: .ass)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
        self.width = try container.decodeIfPresent(Int.self, forKey: .width)
        self.height = try container.decodeIfPresent(Int.self, forKey: .height)
        self.draft = try container.decode(Bool.self, forKey: .draft)
        self.renderingTime = try container.decodeIfPresent(Int.self, forKey: .renderingTime)
    }
}




/// Information about the remaining quota
public struct RemainingQuota: Codable {
    /// The number of credits remaining in the account
    @SchemaInfo(description: "The number of credits remaining in the account")
    public var time: Int = 0
    
    public init(time: Int = 0) {
        self.time = time
    }
}

/// Movie object for creating a new movie
/// This is the top level object to start with when creating a movie
public struct Movie: Codable, ProducesJSONSchema {
    
    public static var exampleValue: Movie = Movie(scenes: [Scene.exampleValue], resolution: "full-hd", quality: "high")
    
    /// Whether to use caching (default: true)
    @SchemaInfo(description: "Whether to use caching (default: true)")
    public var cache: Bool? = true
    
    /// Custom key-value pairs for client data
    @SchemaInfo(description: "Custom key-value pairs for client data")
    public var clientData: [String: String]? = nil
    
    /// Comment or notes about the movie
    @SchemaInfo(description: "Comment or notes about the movie")
    public var comment: String? = nil
    
    /// Global elements available to all scenes
    @SchemaInfo(description: "Global elements available to all scenes")
    public var elements: [AnySceneElement]? = nil
    
    /// Export configurations
    @SchemaInfo(description: "Export configurations")
    public var exports: [Export]? = nil
    
    /// Height in pixels (required when resolution is 'custom')
    @SchemaInfo(description: "Height in pixels (required when resolution is 'custom', range: 50-3840)")
    public var height: Int? = nil
    
    /// Movie ID (default: random string)
    @SchemaInfo(description: "Movie ID (default: random string)")
    public var id: String? = nil
    
    /// Quality of the rendering (low, medium, high)
    @SchemaInfo(description: "Quality of the rendering (low, medium, high)")
    public var quality: String? = "high"
    
    /// Resolution of the movie
    @SchemaInfo(description: "Resolution of the movie (presets or 'custom')")
    public var resolution: String? = nil
    
    /// Width in pixels (required when resolution is 'custom')
    @SchemaInfo(description: "Width in pixels (required when resolution is 'custom', range: 50-3840)")
    public var width: Int? = nil
    
    /// Scenes in the movie (required)
    @SchemaInfo(description: "Scenes in the movie (required)")
    public var scenes: [Scene] = []
    
    private enum CodingKeys: String, CodingKey {
        case cache, clientData, comment, elements, exports, height, id, quality, resolution, width, scenes
    }
    
    public init(scenes: [Scene] = [], resolution: String? = nil, quality: String? = "high") {
        self.scenes = scenes
        self.resolution = resolution
        self.quality = quality
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cache = try container.decodeIfPresent(Bool.self, forKey: .cache)
        clientData = try container.decodeIfPresent([String: String].self, forKey: .clientData)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        exports = try container.decodeIfPresent([Export].self, forKey: .exports)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        quality = try container.decodeIfPresent(String.self, forKey: .quality)
        resolution = try container.decodeIfPresent(String.self, forKey: .resolution)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        scenes = try container.decode([Scene].self, forKey: .scenes)
        elements = try container.decode([AnySceneElement].self, forKey: .elements)
        
//        // Handle elements array - decode each element based on its type
//        if let elementsContainer = try? container.nestedUnkeyedContainer(forKey: .elements) {
//            var elements: [SceneElement] = []
//            var elementsIterator = elementsContainer
//            
//            while !elementsIterator.isAtEnd {
//                // First decode as a generic dictionary to get the type
//                if let elementDict = try? elementsIterator.decode([String: Any].self),
//                   let type = elementDict["type"] as? String {
//                    
//                    // Based on type, decode to the appropriate concrete element type
//                    switch type {
//                    case "image":
//                        if let element = try? elementsIterator.decode(ImageElement.self) {
//                            elements.append(element)
//                        }
//                    case "video":
//                        if let element = try? elementsIterator.decode(VideoElement.self) {
//                            elements.append(element)
//                        }
//                    case "text":
//                        if let element = try? elementsIterator.decode(TextElement.self) {
//                            elements.append(element)
//                        }
//                    case "audio":
//                        if let element = try? elementsIterator.decode(AudioElement.self) {
//                            elements.append(element)
//                        }
//                    case "voice":
//                        if let element = try? elementsIterator.decode(VoiceElement.self) {
//                            elements.append(element)
//                        }
//                    case "subtitles":
//                        if let element = try? elementsIterator.decode(SubtitlesElement.self) {
//                            elements.append(element)
//                        }
//                    default:
//                        // Skip unknown element types
//                        break
//                    }
//                } else {
//                    // If we can't decode the type, skip this element
//                    _ = try? elementsIterator.decode(EmptyDecodable.self)
//                }
//            }
//            
//            self.elements = elements
//        } else {
//            self.elements = nil
//        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(cache, forKey: .cache)
        try container.encodeIfPresent(clientData, forKey: .clientData)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(exports, forKey: .exports)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(quality, forKey: .quality)
        try container.encodeIfPresent(resolution, forKey: .resolution)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encode(scenes, forKey: .scenes)
        
        // Encode elements array if present
        if let elements = elements, !elements.isEmpty {
            var elementsContainer = container.nestedUnkeyedContainer(forKey: .elements)
            for element in elements {
                try elementsContainer.encode(element)
            }
        }
    }
}

/// Scene object for a movie
public struct Scene: Codable, ProducesJSONSchema {
    
    public static var exampleValue: Scene = Scene(duration: 10, background: "", elements: [AnySceneElement(type: "text", wrappedSceneElement: TextElement.exampleValue)], variables: [:])
    
    /// Background color of the scene (default: "#000000")
    @SchemaInfo(description: "Background color of the scene (default: '#000000')")
    public var background: String? = "#000000"
    
    /// Whether to use caching (default: true)
    @SchemaInfo(description: "Whether to use caching (default: true)")
    public var cache: Bool? = true
    
    /// Comment or notes about the scene
    @SchemaInfo(description: "Comment or notes about the scene")
    public var comment: String? = nil
    
    /// Conditional expression for scene display
    @SchemaInfo(description: "Conditional expression for scene display")
    public var condition: String? = nil
    
    /// Duration of the scene in seconds (-1 for auto-duration)
    @SchemaInfo(description: "Duration of the scene in seconds (-1 for auto-duration)")
    public var duration: Double? = -1
    
    /// Elements in the scene
    @SchemaInfo(description: "Elements in the scene")
    public var elements: [AnySceneElement]? = nil
    
    /// Scene ID (default: random string)
    @SchemaInfo(description: "Scene ID (default: random string)")
    public var id: String? = nil
    
    /// Custom variables for the scene
    @SchemaInfo(description: "Custom variables for the scene")
    public var variables: [String: String]? = nil
    
    // Private coding keys for custom Codable implementation
    private enum CodingKeys: String, CodingKey {
        case duration, background, elements, id, cache, comment, condition, variables
    }
    
    public init(duration: Double? = -1, background: String? = "#000000", elements: [AnySceneElement]? = nil, variables: [String: String]? = nil) {
        self.duration = duration
        self.background = background
        self.elements = elements
        self.variables = variables
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        background = try container.decodeIfPresent(String.self, forKey: .background)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        cache = try container.decodeIfPresent(Bool.self, forKey: .cache)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
        variables = try container.decodeIfPresent([String: String].self, forKey: .variables)
        elements = try container.decodeIfPresent([AnySceneElement].self, forKey: .elements)
        
//        // Handle elements array - decode each element based on its type
//        if let elementsContainer = try? container.nestedUnkeyedContainer(forKey: .elements) {
//            var elements: [SceneElement] = []
//            var elementsIterator = elementsContainer
//            
//            while !elementsIterator.isAtEnd {
//                // First decode as a generic dictionary to get the type
//                if let elementDict = try? elementsIterator.decode([String: Any].self),
//                   let type = elementDict["type"] as? String {
//                    
//                    // Based on type, decode to the appropriate concrete element type
//                    switch type {
//                    case "image":
//                        if let element = try? elementsIterator.decode(ImageElement.self) {
//                            elements.append(element)
//                        }
//                    case "video":
//                        if let element = try? elementsIterator.decode(VideoElement.self) {
//                            elements.append(element)
//                        }
//                    case "text":
//                        if let element = try? elementsIterator.decode(TextElement.self) {
//                            elements.append(element)
//                        }
//                    case "audio":
//                        if let element = try? elementsIterator.decode(AudioElement.self) {
//                            elements.append(element)
//                        }
//                    case "voice":
//                        if let element = try? elementsIterator.decode(VoiceElement.self) {
//                            elements.append(element)
//                        }
//                    case "subtitles":
//                        if let element = try? elementsIterator.decode(SubtitlesElement.self) {
//                            elements.append(element)
//                        }
//                    default:
//                        // Skip unknown element types
//                        break
//                    }
//                } else {
//                    // If we can't decode the type, skip this element
//                    _ = try? elementsIterator.decode(EmptyDecodable.self)
//                }
//            }
//            
//            self.elements = elements
//        } else {
//            self.elements = nil
//        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(background, forKey: .background)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(cache, forKey: .cache)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(condition, forKey: .condition)
        try container.encodeIfPresent(variables, forKey: .variables)
        
        // Encode elements array if present
        if let elements = elements, !elements.isEmpty {
            var elementsContainer = container.nestedUnkeyedContainer(forKey: .elements)
            for element in elements {
                try elementsContainer.encode(element)
            }
        }
    }
}

/// Element in a scene
public protocol SceneElement: Codable {
    /// Type of the element
    var type: String { get }
}

public struct AnySceneElement: Codable {
    
    var type: String
    var wrappedSceneElement: Any
    
    init(type: String, wrappedSceneElement: Any) {
        self.type = type
        self.wrappedSceneElement = wrappedSceneElement
    }
    
    public init(from decoder: any Decoder) throws {
        
        var container = try decoder.container(keyedBy: CodingKeys.self)
        guard let type = try container.decodeIfPresent(String.self, forKey: .type) else {
            throw NSError(domain: "Invalid scene type in response", code: 0)
        }
        
        switch type {
        case "image":
            guard let element = try container.decodeIfPresent(ImageElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        case "video":
            guard let element = try container.decodeIfPresent(VideoElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        case "text":
            guard let element = try container.decodeIfPresent(TextElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        case "audio":
            guard let element = try container.decodeIfPresent(AudioElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        case "voice":
            guard let element = try container.decodeIfPresent(VoiceElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        case "subtitles":
            guard let element = try container.decodeIfPresent(SubtitlesElement.self, forKey: .sceneElement) else {
                throw NSError(domain: "Couldn't decode element", code: 0)
            }
            self.wrappedSceneElement = element
        default:
            // Skip unknown element types
            throw NSError(domain: "Unknown scene element", code: 0)
        }
        
        self.type = type
    }
    
    enum CodingKeys: CodingKey {
        case type
        case sceneElement
    }
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        // Based on type, decode to the appropriate concrete element type
        switch type {
        case "image":
            let element = wrappedSceneElement as! ImageElement
            try container.encode(element, forKey: .sceneElement)
        case "video":
            let element = wrappedSceneElement as! VideoElement
            try container.encode(element, forKey: .sceneElement)
        case "text":
            let element = wrappedSceneElement as! TextElement
            try container.encode(element, forKey: .sceneElement)
        case "audio":
            let element = wrappedSceneElement as! AudioElement
            try container.encode(element, forKey: .sceneElement)
        case "voice":
            let element = wrappedSceneElement as! VoiceElement
            try container.encode(element, forKey: .sceneElement)
        case "subtitles":
            let element = wrappedSceneElement as! SubtitlesElement
            try container.encode(element, forKey: .sceneElement)
        default:
            // Skip unknown element types
            break
        }
    }
}

/// Image element
public struct ImageElement: SceneElement {
    /// Type of the element (always "image")
    @SchemaInfo(description: "Type of the element (always 'image')")
    public var type: String = "image"
    
    /// URL of the image
    @SchemaInfo(description: "URL of the image")
    public var src: String = ""
    
    /// Position of the image
    @SchemaInfo(description: "Position of the image (center, top, bottom, left, right, etc.)")
    public var position: String? = "center"
    
    /// Width of the image in pixels
    @SchemaInfo(description: "Width of the image in pixels")
    public var width: Int? = nil
    
    /// Height of the image in pixels
    @SchemaInfo(description: "Height of the image in pixels")
    public var height: Int? = nil
    
    public init(src: String = "", position: String? = "center", width: Int? = nil, height: Int? = nil) {
        self.src = src
        self.position = position
        self.width = width
        self.height = height
    }
}

/// Video element
public struct VideoElement: SceneElement, ProducesJSONSchema {
    
    public static var exampleValue: VideoElement = VideoElement(src: "https://google.con/videobucket/244234.,p4", position: "center", width: 1024, height: 800)
    
    /// Type of the element (always "video")
    @SchemaInfo(description: "Type of the element (always 'video')")
    public var type: String = "video"
    
    /// URL of the video
    @SchemaInfo(description: "URL of the video")
    public var src: String = ""
    
    /// Position of the video
    @SchemaInfo(description: "Position of the video (center, top, bottom, left, right, etc.)")
    public var position: String? = "center"
    
    /// Width of the video in pixels
    @SchemaInfo(description: "Width of the video in pixels")
    public var width: Int? = nil
    
    /// Height of the video in pixels
    @SchemaInfo(description: "Height of the video in pixels")
    public var height: Int? = nil
    
    public init(src: String = "", position: String? = "center", width: Int? = nil, height: Int? = nil) {
        self.src = src
        self.position = position
        self.width = width
        self.height = height
    }
}

/// Text element
public struct TextElement: SceneElement, ProducesJSONSchema {
    
    public static var exampleValue: TextElement = TextElement(text: "Hello World", position: "center", fontSize: 18, fontFamily: "Arial", color: "green")
    
    /// Type of the element (always "text")
    @SchemaInfo(description: "Type of the element (always 'text')")
    public var type: String = "text"
    
    /// Text content
    @SchemaInfo(description: "Text content")
    public var text: String = ""
    
    /// Position of the text
    @SchemaInfo(description: "Position of the text (center, top, bottom, left, right, etc.)")
    public var position: String? = "center"
    
    /// Font size in pixels
    @SchemaInfo(description: "Font size in pixels")
    public var fontSize: Int? = 24
    
    /// Font family
    @SchemaInfo(description: "Font family")
    public var fontFamily: String? = "Arial"
    
    /// Text color (hexadecimal)
    @SchemaInfo(description: "Text color (hexadecimal)")
    public var color: String? = "#FFFFFF"
    
    public init(text: String = "", position: String? = "center", fontSize: Int? = 24, fontFamily: String? = "Arial", color: String? = "#FFFFFF") {
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.color = color
    }
}

/// Audio element
public struct AudioElement: SceneElement {
    /// Type of the element (always "audio")
    @SchemaInfo(description: "Type of the element (always 'audio')")
    public var type: String = "audio"
    
    /// URL of the audio file
    @SchemaInfo(description: "URL of the audio file")
    public var src: String = ""
    
    public init(src: String = "") {
        self.src = src
    }
}

/// Voice element for AI-generated speech
public struct VoiceElement: SceneElement {
    /// Type of the element (always "voice")
    @SchemaInfo(description: "Type of the element (always 'voice')")
    public var type: String = "voice"
    
    /// Text to convert to speech
    @SchemaInfo(description: "Text to convert to speech")
    public var text: String = ""
    
    /// Voice to use
    @SchemaInfo(description: "Voice to use")
    public var voice: String = ""
    
    public init(text: String = "", voice: String = "") {
        self.text = text
        self.voice = voice
    }
}

/// Subtitles element
public struct SubtitlesElement: SceneElement {
    /// Type of the element (always "subtitles")
    @SchemaInfo(description: "Type of the element (always 'subtitles')")
    public var type: String = "subtitles"
    
    /// URL of the subtitles file
    @SchemaInfo(description: "URL of the subtitles file")
    public var src: String = ""
    
    public init(src: String = "") {
        self.src = src
    }
}

/// Export configuration
public struct Export: Codable {
    /// Format of the export
    @SchemaInfo(description: "Format of the export (e.g., 'mp4', 'gif')")
    public var format: String = "mp4"
    
    /// Quality of the export
    @SchemaInfo(description: "Quality of the export")
    public var quality: String? = nil
    
    /// Frames per second for the export
    @SchemaInfo(description: "Frames per second for the export")
    public var fps: Int? = nil
    
    public init(format: String = "mp4", quality: String? = nil, fps: Int? = nil) {
        self.format = format
        self.quality = quality
        self.fps = fps
    }
}

/// Empty decodable struct for skipping unknown elements
private struct EmptyDecodable: Decodable {}

/// Errors that can occur when interacting with the Json2Video API
public enum Json2VideoError: Error {
    /// The URL is invalid
    case invalidURL
    /// The JSON is invalid
    case invalidJSON(Error)
    /// A network error occurred
    case networkError(Error)
    /// The response is invalid
    case invalidResponse
    /// An HTTP error occurred
    case httpError(Int, Data?)
    /// No data was returned
    case noData
    /// An error occurred while decoding the response
    case decodingError(Error)
    /// The API key is invalid
    case invalidAPIKey
    /// The API returned an error message
    case apiError(String)
}

extension Json2VideoError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidJSON(let error):
            return "The JSON is invalid: \(error.localizedDescription)"
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .invalidResponse:
            return "The response is invalid."
        case .httpError(let statusCode, _):
            return "An HTTP error occurred: \(statusCode)"
        case .noData:
            return "No data was returned."
        case .decodingError(let error):
            return "An error occurred while decoding the response: \(error.localizedDescription)"
        case .invalidAPIKey:
            return "The API key is invalid."
        case .apiError(let message):
            return "The API returned an error: \(message)"
        }
    }
}
