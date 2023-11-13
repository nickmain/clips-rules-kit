// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

// Router passed as a pointer to CLIPS
class Router {
    static let stdout = String(cString: STDOUT)
    static let stderr = String(cString: STDERR)
    static let stdwrn = String(cString: STDWRN)

    var names = Set<String>() // allowed names
    let handler: CLIPSOutputHandler
    let id = UUID().uuidString

    var lineBuffers: [String: String] = [:]

    init(handler: CLIPSOutputHandler) {
        self.handler = handler
    }

    func addStdOut() { names.insert(Self.stdout) }
    func addStdErr() { names.insert(Self.stderr) }
    func addStdWrn() { names.insert(Self.stdwrn) }

    func add(name: String) {
        names.insert(name)
    }

    func write(string: String, for name: String) {
        let partialLine = lineBuffers.removeValue(forKey: name) ?? ""
        var lines = (partialLine + string).split(separator: "\n",  omittingEmptySubsequences: false)

        let lastPartial = lines.removeLast()
        lineBuffers[name] = String(lastPartial)

        for line in lines {
            handler.handle(line: .from(name: name, line: String(line)))
        }
    }

    func addRouter(env: CLIPS.EnvironmentPtr) {
        AddRouter(env, id, 1000,
                  routerQueryFunction(_:_:_:),
                  routerWriteFunction(_:_:_:_:),
                  routerReadFunction(_:_:_:),
                  routerUnreadFunction(_:_:_:_:),
                  routerExitFunction(_:_:_:),
                  UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }
}

func routerQueryFunction(_ env: CLIPS.EnvironmentPtr?,
                         _ logicalName: UnsafePointer<CChar>?,
                         _ context: UnsafeMutableRawPointer?) -> Bool {

    guard let context, let logicalName else { return false }
    let router: Router = Unmanaged.fromOpaque(context).takeUnretainedValue()
    let name = String(cString: logicalName)

    return router.names.contains(name)
}

func routerWriteFunction(_ env: CLIPS.EnvironmentPtr?,
                         _ logicalName: UnsafePointer<CChar>?,
                         _ chars: UnsafePointer<CChar>?,
                         _ context: UnsafeMutableRawPointer?) {
    guard let chars, let logicalName, let context else { return }
    let string = String(cString: chars)
    let name = String(cString: logicalName)
    let router: Router = Unmanaged.fromOpaque(context).takeUnretainedValue()

    router.write(string: string, for: name)
}

func routerExitFunction(_ env: CLIPS.EnvironmentPtr?,
                        _ code: Int32,
                        _ context: UnsafeMutableRawPointer?) {
    CLIPS.logger.info("Router Exit Function called with code \(code)")
}

func routerReadFunction(_ env: CLIPS.EnvironmentPtr?,
                        _ logicalName: UnsafePointer<CChar>?,
                        _ context: UnsafeMutableRawPointer?) -> Int32 {
    // Reading is not supported
    let name = if let logicalName { String(cString: logicalName) } else { "<???>" }
    CLIPS.logger.warning("Reading from CLIPS router is not implemented; name: \(name)")
    return -1 // EOF
}

func routerUnreadFunction(_ env: CLIPS.EnvironmentPtr?,
                          _ logicalName: UnsafePointer<CChar>?,
                          _ char: Int32,
                          _ context: UnsafeMutableRawPointer?) -> Int32 {
    // not supported
    let name = if let logicalName { String(cString: logicalName) } else { "<???>" }
    CLIPS.logger.warning("Unreading from CLIPS router is not implemented; name: \(name)")
    return -1 // EOF
}
