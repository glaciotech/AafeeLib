import Foundation
import Logging
import SwiftyPrompts
import SwiftyPrompts_OpenAI

struct Global {
    
    static var l = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
    }
    
    static var logger = Logger(label: "AafeeLib")
}

// Make logger available to module
let logger = Global.logger

/// Main class for the AafeeLib library
public class AafeeLib {
    public init() {}
}
