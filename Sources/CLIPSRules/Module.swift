// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    typealias DefModulePtr = UnsafeMutablePointer<CLIPSCore.Defmodule>

    /// A CLIPS module
    public struct Module {
        internal let ptr: DefModulePtr
    }
}

extension CLIPS.Environment {

    /// Find a module by name
    public func find(module name: String) -> CLIPS.Module? {
        guard let mod = CLIPSCore.FindDefmodule(ptr, name) else { return nil }
        return .init(ptr: mod)
    }

    /// Get the name of a module
    public func getName(of module: CLIPS.Module) -> String {
        String(cString: CLIPSCore.DefmoduleName(module.ptr))
    }

    /// The current module
    public var currentModule: CLIPS.Module {
        .init(ptr: CLIPSCore.GetCurrentModule(ptr))
    }

    /// Set the current module
    public func setCurrent(module: CLIPS.Module) {
        CLIPSCore.SetCurrentModule(ptr, module.ptr)
    }

    /// Get the name of the module that the template is declared in
    public func getModule(of template: CLIPS.FactTemplate) -> String {
        String(cString: CLIPSCore.DeftemplateModule(template.ptr))
    }
}
