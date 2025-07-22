//
//  CLIProcess.swift
//  AafeeLib
//
//  Created by Peter Liddle on 6/20/25.
//
import Foundation
import Logging
import MCP

#if canImport(System)
import System
#else
import SystemPackage
#endif

extension Process {
    var terminalCommand: String {
        return  ([self.executableURL?.path] + (self.arguments ?? [])).compactMap { $0 }.joined(separator: " ")
    }
}

let log: Logger = {
    Logger(label: "")
}()

class MCPProcess {
    
    var executablePath: String = "/usr/bin/env"
    
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    
    let log = Logger(label: "")
    
//    enum ProcessError: Error {
//        
//        case runError(String)
//        case runFailed(String)
//        case corruptOutput
//    }
    
    var arguments = [String]()
    
    var task: Task<Void, Never>?
    
    init(executablePath: String = "/usr/bin/env", arguments: [String] = [String]()) {
        self.executablePath = executablePath
        self.arguments = arguments
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        wrappedProcess = process
    }
    
    private var wrappedProcess: Process
    
    var terminalCommand: String {
        return wrappedProcess.terminalCommand
    }
    
    private func createTransport() -> StdioTransport {
        let outFd = FileDescriptor(rawValue: outputPipe.fileHandleForReading.fileDescriptor)
        let inFd = FileDescriptor(rawValue: inputPipe.fileHandleForWriting.fileDescriptor)
        return StdioTransport(input: inFd, output: outFd)
    }
    
    func start() throws -> StdioTransport {

        let process = wrappedProcess
            
//       Optional: You can add a readabilityHandler to immediately process the output.
//        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
//          if let output = String(data: fileHandle.availableData, encoding: .utf8) {
//              guard !output.isEmpty else { return }
//              self.log.trace("\(output)")
//              outputText.append(output)
//          }
//        }
//        
//        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
//            if let output = String(data: fileHandle.availableData, encoding: .utf8) {
//                guard !output.isEmpty else { return }
//                self.log.trace("\(output)")
//                errorText.append(output)
//            }
//        }
    
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        log.debug("Process started")
 
//        task = Task.detached {
            try? process.run()
//            process.waitUntilExit()
//        }
        
        log.debug("Process finished")
        
        
//        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
//            errorText.append(error)
//            throw ProcessError.runError(errorText)
//        }

        
        return createTransport()
    }
    
    deinit {
        // Kill process if app is killed
        log.debug("Killing process \(String(describing: self.wrappedProcess.processIdentifier))")
        if self.wrappedProcess.isRunning {
            self.wrappedProcess.terminate()
        }
    }
}
