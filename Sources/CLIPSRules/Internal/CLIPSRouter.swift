// Copyright (c) 2025 David N Main

import Foundation
import CLIPSCore

// Router passed as a pointer to CLIPS
class CLIPSRouter {
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

    func addRouter(env: CLIPSEnvironment.Ptr) {
        AddRouter(env, id, 1000,
                  routerQueryFunction(_:_:_:),
                  routerWriteFunction(_:_:_:_:),
                  routerReadFunction(_:_:_:),
                  routerUnreadFunction(_:_:_:_:),
                  routerExitFunction(_:_:_:),
                  UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }
}

func routerQueryFunction(_ env: CLIPSEnvironment.Ptr?,
                         _ logicalName: UnsafePointer<CChar>?,
                         _ context: UnsafeMutableRawPointer?) -> Bool {

    guard let context, let logicalName else { return false }
    let router: CLIPSRouter = Unmanaged.fromOpaque(context).takeUnretainedValue()
    let name = String(cString: logicalName)

    return router.names.contains(name)
}

func routerWriteFunction(_ env: CLIPSEnvironment.Ptr?,
                         _ logicalName: UnsafePointer<CChar>?,
                         _ chars: UnsafePointer<CChar>?,
                         _ context: UnsafeMutableRawPointer?) {
    guard let chars, let logicalName, let context else { return }
    let string = String(cString: chars)
    let name = String(cString: logicalName)
    let router: CLIPSRouter = Unmanaged.fromOpaque(context).takeUnretainedValue()

    router.write(string: string, for: name)
}

func routerExitFunction(_ env: CLIPSEnvironment.Ptr?,
                        _ code: Int32,
                        _ context: UnsafeMutableRawPointer?) {
    CLIPSEnvironment.logger.info("Router Exit Function called with code \(code)")
}

func routerReadFunction(_ env: CLIPSEnvironment.Ptr?,
                        _ logicalName: UnsafePointer<CChar>?,
                        _ context: UnsafeMutableRawPointer?) -> Int32 {
    // Reading is not supported
    let name = if let logicalName { String(cString: logicalName) } else { "<???>" }
    CLIPSEnvironment.logger.warning("Reading from CLIPS router is not implemented; name: \(name)")
    return -1 // EOF
}

func routerUnreadFunction(_ env: CLIPSEnvironment.Ptr?,
                          _ logicalName: UnsafePointer<CChar>?,
                          _ char: Int32,
                          _ context: UnsafeMutableRawPointer?) -> Int32 {
    // not supported
    let name = if let logicalName { String(cString: logicalName) } else { "<???>" }
    CLIPSEnvironment.logger.warning("Unreading from CLIPS router is not implemented; name: \(name)")
    return -1 // EOF
}
