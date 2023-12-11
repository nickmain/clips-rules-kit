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
        return switch err {
        case RE_NULL_POINTER_ERROR:      .nullPointer
        case RE_COULD_NOT_RETRACT_ERROR: .couldNotRetract
        case RE_RULE_NETWORK_ERROR:      .ruleNetworkError
        default: .other(err)
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
        return switch err {
        case UIE_NULL_POINTER_ERROR:     .nullPointer
        case UIE_COULD_NOT_DELETE_ERROR: .couldNotDelete
        case UIE_DELETED_ERROR:          .alreadyDeleted
        case UIE_RULE_NETWORK_ERROR:     .ruleNetworkError
        default: .other(err)
        }
    }

    public var errorDescription: String? { "CLIPSUnmakeInstanceError: \(self)" }
}

public enum CLIPSAddUDFError: LocalizedError {
    case other(AddUDFError)
    case noError
    case minExceedsMax
    case functionNameInUse
    case invalidArgumentType
    case invalidReturnType

    static func from(_ err: AddUDFError) -> CLIPSAddUDFError {
        return switch err {
        case AUE_NO_ERROR:                    .noError
        case AUE_MIN_EXCEEDS_MAX_ERROR:       .minExceedsMax
        case AUE_FUNCTION_NAME_IN_USE_ERROR:  .functionNameInUse
        case AUE_INVALID_ARGUMENT_TYPE_ERROR: .invalidArgumentType
        case AUE_INVALID_RETURN_TYPE_ERROR:   .invalidReturnType
        default: .other(err)
        }
    }

    public var errorDescription: String? { "CLIPSAddUDFError: \(self)" }
}
