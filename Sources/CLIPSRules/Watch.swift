// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

/// The different items that can be watched for debugging
public enum Watch {
    case facts, instances, slots, rules, activations, messages,
         message_handlers, generic_functions, methods, deffunctions,
         compilations, statistics, globals, focus

    /// Set the watch state for the item
    public func set(on state: Bool, for clips: CLIPS) async {
        await clips.perform { env in
            SetWatchState(env, item, state)
        }
    }

    /// Get the watch state for the item
    public func on(for clips: CLIPS) async -> Bool {
        await clips.perform { env in
            GetWatchState(env, item)
        }
    }

    /// Set the watch state for all the items
    public static func turnAll(on state: Bool, for clips: CLIPS) async {
        await clips.perform { env in
            SetWatchState(env, CLIPSCore.ALL, state)
        }
    }

    private var item: WatchItem {
        switch self {
        case .facts: return FACTS
        case .instances: return INSTANCES
        case .slots: return SLOTS
        case .rules: return RULES
        case .activations: return ACTIVATIONS
        case .messages: return MESSAGES
        case .message_handlers: return MESSAGE_HANDLERS
        case .generic_functions: return GENERIC_FUNCTIONS
        case .methods: return METHODS
        case .deffunctions: return DEFFUNCTIONS
        case .compilations: return COMPILATIONS
        case .statistics: return STATISTICS
        case .globals: return GLOBALS
        case .focus: return FOCUS
        }
    }
}
