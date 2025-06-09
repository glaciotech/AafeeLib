import Foundation
import SwiftyJsonSchema
//
///// A builder for creating Json2Video movie structures
//public class Json2VideoBuilder {
//    /// The movie structure
//    private var movie: Movie
//    /// The scenes in the movie
//    private var scenes: [Scene] = []
//    
//    /// Initializes a new Json2Video movie builder
//    /// - Parameters:
//    ///   - resolution: The resolution of the movie (default: "full-hd")
//    ///   - quality: The quality of the movie (default: "high")
//    public init(resolution: String = "full-hd", quality: String = "high") {
//        self.movie = Movie(scenes: [], resolution: resolution, quality: quality)
//    }
//    
//    /// Sets the resolution of the movie
//    /// - Parameter resolution: The resolution to set
//    /// - Returns: The builder for chaining
//    public func setResolution(_ resolution: String) -> Json2VideoBuilder {
//        movie.resolution = resolution
//        return self
//    }
//    
//    /// Sets the quality of the movie
//    /// - Parameter quality: The quality to set ("low", "medium", "high")
//    /// - Returns: The builder for chaining
//    public func setQuality(_ quality: String) -> Json2VideoBuilder {
//        movie.quality = quality
//        return self
//    }
//    
//    /// Sets custom dimensions for the movie
//    /// - Parameters:
//    ///   - width: The width of the movie in pixels
//    ///   - height: The height of the movie in pixels
//    /// - Returns: The builder for chaining
//    public func setCustomDimensions(width: Int, height: Int) -> Json2VideoBuilder {
//        movie.resolution = "custom"
//        movie.width = width
//        movie.height = height
//        return self
//    }
//    
//    /// Sets whether to use caching for the movie
//    /// - Parameter useCache: Whether to use caching
//    /// - Returns: The builder for chaining
//    public func setCache(_ useCache: Bool) -> Json2VideoBuilder {
//        movie.cache = useCache
//        return self
//    }
//    
//    /// Sets client data for the movie
//    /// - Parameter clientData: Custom key-value pairs
//    /// - Returns: The builder for chaining
//    public func setClientData(_ clientData: [String: String]) -> Json2VideoBuilder {
//        movie.clientData = clientData
//        return self
//    }
//    
//    /// Sets a comment for the movie
//    /// - Parameter comment: The comment to set
//    /// - Returns: The builder for chaining
//    public func setComment(_ comment: String) -> Json2VideoBuilder {
//        movie.comment = comment
//        return self
//    }
//    
//    /// Sets export configuration for the movie
//    /// - Parameters:
//    ///   - format: The export format (e.g., "mp4", "webm")
//    ///   - fps: The frames per second
//    /// - Returns: The builder for chaining
//    public func setExport(format: String, fps: Int? = nil) -> Json2VideoBuilder {
//        var exportConfig = Export(format: format)
//        exportConfig.fps = fps
//        movie.exports = [exportConfig]
//        return self
//    }
//    
//    /// Adds a new scene to the movie
//    /// - Parameters:
//    ///   - duration: The duration of the scene in seconds (-1 for auto-duration)
//    ///   - background: The background color of the scene (default: "#000000")
//    /// - Returns: A scene builder for adding elements to the scene
//    public func addScene(duration: Double = -1, background: String = "#000000") -> SceneBuilder {
//        let scene = Scene(duration: duration, background: background, elements: [])
//        let sceneBuilder = SceneBuilder(scene: scene)
//        scenes.append(scene)
//        return sceneBuilder
//    }
//    
//    /// Builds the final movie structure
//    /// - Returns: The movie structure
//    public func build() -> Movie {
//        movie.scenes = scenes
//        return movie
//    }
//    
//    /// Converts the movie to a JSON dictionary
//    /// - Returns: The movie as a JSON dictionary
//    public func toJSON() -> [String: Any] {
//        let encoder = JSONEncoder()
//        do {
//            let data = try encoder.encode(build())
//            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                return json
//            }
//        } catch {
//            print("Error converting Movie to JSON: \(error)")
//        }
//        return [:]
//    }
//    
//    /// A builder for creating scene structures
//    public class SceneBuilder {
//        /// The scene structure
//        public var scene: Scene
//        /// The elements in the scene
//        private var elements: [SceneElement] = []
//        
//        /// Initializes a new scene builder
//        /// - Parameter scene: The scene to build
//        fileprivate init(scene: Scene) {
//            self.scene = scene
//            if let elements = scene.elements {
//                self.elements = elements
//            }
//        }
//        
//        /// Sets the duration of the scene
//        /// - Parameter duration: The duration in seconds (-1 for auto-duration)
//        /// - Returns: The scene builder for chaining
//        public func setDuration(_ duration: Double) -> SceneBuilder {
//            scene.duration = duration
//            return self
//        }
//        
//        /// Sets the background color of the scene
//        /// - Parameter background: The background color (hexadecimal)
//        /// - Returns: The scene builder for chaining
//        public func setBackground(_ background: String) -> SceneBuilder {
//            scene.background = background
//            return self
//        }
//        
//        /// Sets whether to use caching for the scene
//        /// - Parameter useCache: Whether to use caching
//        /// - Returns: The scene builder for chaining
//        public func setCache(_ useCache: Bool) -> SceneBuilder {
//            scene.cache = useCache
//            return self
//        }
//        
//        /// Sets a comment for the scene
//        /// - Parameter comment: The comment to set
//        /// - Returns: The scene builder for chaining
//        public func setComment(_ comment: String) -> SceneBuilder {
//            scene.comment = comment
//            return self
//        }
//        
//        /// Sets a condition for the scene
//        /// - Parameter condition: The condition expression
//        /// - Returns: The scene builder for chaining
//        public func setCondition(_ condition: String) -> SceneBuilder {
//            scene.condition = condition
//            return self
//        }
//        
//        /// Sets an ID for the scene
//        /// - Parameter id: The ID to set
//        /// - Returns: The scene builder for chaining
//        public func setId(_ id: String) -> SceneBuilder {
//            scene.id = id
//            return self
//        }
//        
//        /// Sets variables for the scene
//        /// - Parameter variables: The variables to set
//        /// - Returns: The scene builder for chaining
//        public func setVariables(_ variables: [String: String]) -> SceneBuilder {
//            scene.variables = variables
//            return self
//        }
//        
//        /// Adds an image element to the scene
//        /// - Parameters:
//        ///   - src: The URL of the image
//        ///   - position: The position of the image ("center", "top", "bottom", "left", "right", etc.)
//        ///   - width: The width of the image (optional)
//        ///   - height: The height of the image (optional)
//        /// - Returns: The scene builder for chaining
//        public func addImage(src: String, position: String = "center", width: Int? = nil, height: Int? = nil) -> SceneBuilder {
//            var imageElement = ImageElement(src: src, position: position)
//            imageElement.width = width
//            imageElement.height = height
//            
//            elements.append(imageElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds a video element to the scene
//        /// - Parameters:
//        ///   - src: The URL of the video
//        ///   - position: The position of the video ("center", "top", "bottom", "left", "right", etc.)
//        ///   - width: The width of the video (optional)
//        ///   - height: The height of the video (optional)
//        /// - Returns: The scene builder for chaining
//        public func addVideo(src: String, position: String = "center", width: Int? = nil, height: Int? = nil) -> SceneBuilder {
//            var videoElement = VideoElement(src: src, position: position)
//            videoElement.width = width
//            videoElement.height = height
//            
//            elements.append(videoElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds a text element to the scene
//        /// - Parameters:
//        ///   - text: The text content
//        ///   - position: The position of the text ("center", "top", "bottom", "left", "right", etc.)
//        ///   - fontSize: The font size in pixels
//        ///   - fontFamily: The font family
//        ///   - color: The text color (hexadecimal)
//        /// - Returns: The scene builder for chaining
//        public func addText(text: String, position: String = "center", fontSize: Int = 24, fontFamily: String = "Arial", color: String = "#FFFFFF") -> SceneBuilder {
//            let textElement = TextElement(
//                text: text,
//                position: position,
//                fontSize: fontSize,
//                fontFamily: fontFamily,
//                color: color
//            )
//            
//            elements.append(textElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds an audio element to the scene
//        /// - Parameter src: The URL of the audio file
//        /// - Returns: The scene builder for chaining
//        public func addAudio(src: String) -> SceneBuilder {
//            let audioElement = AudioElement(src: src)
//            
//            elements.append(audioElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds a voice element to the scene
//        /// - Parameters:
//        ///   - text: The text to convert to speech
//        ///   - voice: The voice to use
//        /// - Returns: The scene builder for chaining
//        public func addVoice(text: String, voice: String) -> SceneBuilder {
//            let voiceElement = VoiceElement(text: text, voice: voice)
//            
//            elements.append(voiceElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds a subtitles element to the scene
//        /// - Parameter src: The URL of the subtitles file
//        /// - Returns: The scene builder for chaining
//        public func addSubtitles(src: String) -> SceneBuilder {
//            let subtitlesElement = SubtitlesElement(src: src)
//            
//            elements.append(subtitlesElement)
//            scene.elements = elements
//            return self
//        }
//        
//        /// Adds a custom element to the scene
//        /// - Parameter element: The custom element
//        /// - Returns: The scene builder for chaining
//        public func addCustomElement<T: SceneElement>(_ element: T) -> SceneBuilder {
//            elements.append(element)
//            scene.elements = elements
//            return self
//        }
//    }
//}
