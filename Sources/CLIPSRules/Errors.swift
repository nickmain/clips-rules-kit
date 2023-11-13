// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

public struct CLIPSMakeInstanceError: LocalizedError {
    public let kind: MakeInstanceError
    public let instance: String
    
    public var errorDescription: String? { "\(kind) for '\(instance)'" }
}

public struct CLIPSAssertStringError: LocalizedError {
    public let kind: AssertStringError
    public let fact: String

    public var errorDescription: String? { "\(kind) for '\(fact)'" }
}

public enum CLIPSUserFunctionError: LocalizedError {
    case minExceedsMax
    case nameInUse
    case invalidArgumentType
    case invalidReturnType

    public var errorDescription: String? { "CLIPSUserFunctionError: \(self)" }
}

public enum CLIPSEvalError: LocalizedError {
    case parseError
    case processingError

    public var errorDescription: String? { "CLIPSEvalError: \(self)" }
}

public enum CLIPSBuildError: LocalizedError {
    case couldNotBuild
    case constructNotFound
    case parsingError

    public var errorDescription: String? { "CLIPSBuildError: \(self)" }
}

public enum CLIPSRetractError: LocalizedError {
    case other(RetractError)
    case nullPointer
    case couldNotRetract
    case ruleNetworkError
    
    static func from(_ err: RetractError) -> CLIPSRetractError {
        switch err {
        case RE_NULL_POINTER_ERROR: return .nullPointer
        case RE_COULD_NOT_RETRACT_ERROR: return couldNotRetract
        case RE_RULE_NETWORK_ERROR: return ruleNetworkError
        default: return .other(err)
        }
    }
    
    public var errorDescription: String? { "CLIPSRetractError: \(self)" }
}

public enum CLIPSUnmakeInstanceError: LocalizedError {
    case other(UnmakeInstanceError)
    case nullPointer
    case couldNotDelete
    case alreadyDeleted
    case ruleNetworkError

    static func from(_ err: UnmakeInstanceError) -> CLIPSUnmakeInstanceError {
        switch err {
        case UIE_NULL_POINTER_ERROR: return .nullPointer
        case UIE_COULD_NOT_DELETE_ERROR: return .couldNotDelete
        case UIE_DELETED_ERROR: return .alreadyDeleted
        case UIE_RULE_NETWORK_ERROR: return .ruleNetworkError
        default: return .other(err)
        }
    }

    public var errorDescription: String? { "CLIPSUnmakeInstanceError: \(self)" }
}
