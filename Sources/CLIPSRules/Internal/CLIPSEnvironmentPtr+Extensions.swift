// Copyright (c) 2025 David N Main

import CLIPSCore

extension CLIPSEnvironment.Ptr {

    internal func retainCStringPtr(from string: String) -> UnsafePointer<CChar> {
        let lexPtr = CLIPSCore.CreateSymbol(self, string)!
        CLIPSCore.RetainLexeme(self, lexPtr)
        return lexPtr.pointee.contents
    }
}
