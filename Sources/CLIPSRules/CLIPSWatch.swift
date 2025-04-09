// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

/// The different item types that can be watched for debugging
public enum CLIPSWatchItemType {
    case facts, instances, slots, rules, activations, messages,
         message_handlers, generic_functions, methods, deffunctions,
         compilations, statistics, globals, focus

    internal var item: CLIPSCore.WatchItem {
        switch self {
        case .facts: return CLIPSCore.FACTS
        case .instances: return CLIPSCore.INSTANCES
        case .slots: return CLIPSCore.SLOTS
        case .rules: return CLIPSCore.RULES
        case .activations: return CLIPSCore.ACTIVATIONS
        case .messages: return CLIPSCore.MESSAGES
        case .message_handlers: return CLIPSCore.MESSAGE_HANDLERS
        case .generic_functions: return CLIPSCore.GENERIC_FUNCTIONS
        case .methods: return CLIPSCore.METHODS
        case .deffunctions: return CLIPSCore.DEFFUNCTIONS
        case .compilations: return CLIPSCore.COMPILATIONS
        case .statistics: return CLIPSCore.STATISTICS
        case .globals: return CLIPSCore.GLOBALS
        case .focus: return CLIPSCore.FOCUS
        }
    }
}
