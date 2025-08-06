import Foundation
import Logging
import SwiftyPrompts
import SwiftyPrompts_OpenAI



extension Message {
    var content: Content {
        switch self {
        case .ai(let content), .system(let content), .user(let content):
            return content
        }
    }
}

extension Content {
    var text: String {
        switch self {
        case .text(let text):
            return text
        case .fileId(let fileId):
            return "FileName: \(fileId)"
        case let .image(data, type):
            return "IMAGE TYPE: \(type)"
        case .imageUrl(let url):
            return "IMAGE URL: \(url)"
        }
    }
}

// Global logger for the library
public let logger: Logger = {
    var logger = Logger(label: "tech.glacio.aafee")
//    logger.logLevel = .debug
    return logger
}()

// Function to set up the logging system
public func initializeLogging() {
    LoggingSystem.bootstrap { label in
        StreamLogHandler.standardOutput(label: label)
    }
}

/// Main class for the AafeeLib library
public class AafeeLib {
    public init() {}
}
