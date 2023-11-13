// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

extension CLIPS {
    public struct MakeInstanceError: LocalizedError {
        public let kind: CLIPSCore.MakeInstanceError
        public let instance: String

        public var errorDescription: String? { "\(kind) for '\(instance)'" }
    }

    public struct AssertStringError: LocalizedError {
        public enum Kind {
            case other(CLIPSCore.AssertStringError)
            case nullPointer
            case parsingError
            case couldNotAssert
        }

        public let kind: CLIPS.AssertStringError.Kind
        public let fact: String

        public init(kind: CLIPSCore.AssertStringError, fact: String) {
            self.kind = switch kind {
            case ASE_NULL_POINTER_ERROR:     .nullPointer
            case ASE_PARSING_ERROR:          .parsingError
            case ASE_COULD_NOT_ASSERT_ERROR: .couldNotAssert
            default: .other(kind)
            }
            self.fact = fact
        }

        public var errorDescription: String? { "\(kind) for '\(fact)'" }
    }

    public enum UserFunctionError: LocalizedError {
        case minExceedsMax
        case nameInUse
        case invalidArgumentType
        case invalidReturnType

        public var errorDescription: String? { "UserFunctionError: \(self)" }
    }

    public enum PutSlotError: LocalizedError {
        case noError
        case nullPointer
        case invalidTarget
        case slotNotFound
        case typeError
        case rangeError
        case allowedValues
        case cardinality
        case allowedClasses
        case evaluationError
        case ruleNetworkError
        case other(CLIPSCore.PutSlotError)

        static func from(_ err: CLIPSCore.PutSlotError) -> CLIPS.PutSlotError {
            switch err {
            case PSE_NO_ERROR:              .noError
            case PSE_NULL_POINTER_ERROR:    .nullPointer
            case PSE_INVALID_TARGET_ERROR:  .invalidTarget
            case PSE_SLOT_NOT_FOUND_ERROR:  .slotNotFound
            case PSE_TYPE_ERROR:            .typeError
            case PSE_RANGE_ERROR:           .rangeError
            case PSE_ALLOWED_VALUES_ERROR:  .allowedValues
            case PSE_CARDINALITY_ERROR:     .cardinality
            case PSE_ALLOWED_CLASSES_ERROR: .allowedClasses
            case PSE_EVALUATION_ERROR:      .evaluationError
            case PSE_RULE_NETWORK_ERROR:    .ruleNetworkError
            default: .other(err)
            }
        }

        public var errorDescription: String? { "PutSlotError: \(self)" }
    }

    public enum LoadError: LocalizedError {
        case noError
        case openFileError
        case parsingError
        case other(CLIPSCore.LoadError)

        static func from(_ err: CLIPSCore.LoadError) -> CLIPS.LoadError {
            switch err {
            case LE_NO_ERROR:        .noError
            case LE_OPEN_FILE_ERROR: .openFileError
            case LE_PARSING_ERROR:   .parsingError
            default: .other(err)
            }
        }
    }

    public enum InstanceBuilderError: LocalizedError {
        case noError
        case nullPointer
        case classNotFound
        case couldNotCreate
        case ruleNetworkError
        case other(CLIPSCore.InstanceBuilderError)

        static func from(_ err: CLIPSCore.InstanceBuilderError) -> CLIPS.InstanceBuilderError {
            switch err {
            case IBE_NO_ERROR: .noError
            case IBE_NULL_POINTER_ERROR:       .nullPointer
            case IBE_DEFCLASS_NOT_FOUND_ERROR: .classNotFound
            case IBE_COULD_NOT_CREATE_ERROR:   .couldNotCreate
            case IBE_RULE_NETWORK_ERROR:       .ruleNetworkError
            default: .other(err)
            }
        }
    }

    public enum FactBuilderError: LocalizedError {
        case noError
        case nullPointer
        case templateNotFound
        case impliedTemplate
        case couldNotAssert
        case ruleNetworkError
        case other(CLIPSCore.FactBuilderError)

        static func from(_ err: CLIPSCore.FactBuilderError) -> CLIPS.FactBuilderError {
            switch err {
            case FBE_NO_ERROR: .noError
            case FBE_NULL_POINTER_ERROR:          .nullPointer
            case FBE_DEFTEMPLATE_NOT_FOUND_ERROR: .templateNotFound
            case FBE_IMPLIED_DEFTEMPLATE_ERROR:   .impliedTemplate
            case FBE_COULD_NOT_ASSERT_ERROR:      .couldNotAssert
            case FBE_RULE_NETWORK_ERROR:          .ruleNetworkError
            default: .other(err)
            }
        }

        public var errorDescription: String? { "FactBuilderError: \(self)" }
    }

    public enum FunctionCallBuilderError: LocalizedError {
        case noError
        case nullPointer
        case functionNotFound
        case invalidFunction
        case argumentCount
        case argumentType
        case processingError
        case other(CLIPSCore.FunctionCallBuilderError)

        static func from(_ err: CLIPSCore.FunctionCallBuilderError) -> CLIPS.FunctionCallBuilderError {
            switch err {
            case FCBE_NO_ERROR:                 .noError
            case FCBE_NULL_POINTER_ERROR:       .nullPointer
            case FCBE_FUNCTION_NOT_FOUND_ERROR: .functionNotFound
            case FCBE_INVALID_FUNCTION_ERROR:   .invalidFunction
            case FCBE_ARGUMENT_COUNT_ERROR:     .argumentCount
            case FCBE_ARGUMENT_TYPE_ERROR:      .argumentType
            case FCBE_PROCESSING_ERROR:         .processingError
            default: .other(err)
            }
        }

        public var errorDescription: String? { "FunctionCallBuilderError: \(self)" }
    }

    public enum EvalError: LocalizedError {
        case parseError
        case processingError

        public var errorDescription: String? { "EvalError: \(self)" }
    }

    public enum BuildError: LocalizedError {
        case couldNotBuild
        case constructNotFound
        case parsingError

        public var errorDescription: String? { "BuildError: \(self)" }
    }

    public enum RetractError: LocalizedError {
        case other(CLIPSCore.RetractError)
        case nullPointer
        case couldNotRetract
        case ruleNetworkError

        static func from(_ err: CLIPSCore.RetractError) -> RetractError {
            switch err {
            case RE_NULL_POINTER_ERROR:      .nullPointer
            case RE_COULD_NOT_RETRACT_ERROR: .couldNotRetract
            case RE_RULE_NETWORK_ERROR:      .ruleNetworkError
            default: .other(err)
            }
        }

        public var errorDescription: String? { "RetractError: \(self)" }
    }

    public enum GetSlotError: LocalizedError {
        case other(CLIPSCore.GetSlotError)
        case noError
        case nullPointer
        case invalidTarget
        case slotNotFound

        static func from(_ err: CLIPSCore.GetSlotError) -> GetSlotError {
            switch err {
            case GSE_NO_ERROR:             .noError
            case GSE_NULL_POINTER_ERROR:   .nullPointer
            case GSE_INVALID_TARGET_ERROR: .invalidTarget
            case GSE_SLOT_NOT_FOUND_ERROR: .slotNotFound
            default: .other(err)
            }
        }
    }

    public enum UnmakeInstanceError: LocalizedError {
        case other(CLIPSCore.UnmakeInstanceError)
        case nullPointer
        case couldNotDelete
        case alreadyDeleted
        case ruleNetworkError

        static func from(_ err: CLIPSCore.UnmakeInstanceError) -> UnmakeInstanceError {
            switch err {
            case CLIPSCore.UIE_NULL_POINTER_ERROR:     .nullPointer
            case CLIPSCore.UIE_COULD_NOT_DELETE_ERROR: .couldNotDelete
            case CLIPSCore.UIE_DELETED_ERROR:          .alreadyDeleted
            case CLIPSCore.UIE_RULE_NETWORK_ERROR:     .ruleNetworkError
            default: .other(err)
            }
        }

        public var errorDescription: String? { "UnmakeInstanceError: \(self)" }
    }

    public enum AddUDFError: LocalizedError {
        case other(CLIPSCore.AddUDFError)
        case noError
        case minExceedsMax
        case functionNameInUse
        case invalidArgumentType
        case invalidReturnType
        case unexpected

        static func from(_ err: CLIPSCore.AddUDFError) -> AddUDFError {
            switch err {
            case CLIPSCore.AUE_NO_ERROR:                    .noError
            case CLIPSCore.AUE_MIN_EXCEEDS_MAX_ERROR:       .minExceedsMax
            case CLIPSCore.AUE_FUNCTION_NAME_IN_USE_ERROR:  .functionNameInUse
            case CLIPSCore.AUE_INVALID_ARGUMENT_TYPE_ERROR: .invalidArgumentType
            case CLIPSCore.AUE_INVALID_RETURN_TYPE_ERROR:   .invalidReturnType
            default: .other(err)
            }
        }

        public var errorDescription: String? { "AddUDFError: \(self)" }
    }
}
