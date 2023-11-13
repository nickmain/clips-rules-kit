// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

extension CLIPS {

    /// A value of the one of the various kinds that CLIPS supports
    public enum Value: Equatable {
        case float(Double)
        case integer(Int)
        case string(String)
        case symbol(String)
        case instanceName(String)
        case boolean(Bool)
        case fact(CLIPS.Fact)
        case instance(CLIPS.Instance)
        case external(CLIPS.ExternalAddress)
        case multifield([Value])
        case void
    }
}
