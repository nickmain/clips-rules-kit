// Copyright (C) 2024 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import CLIPSCore
import CLIPSRules

public struct CLIPSUI {
    internal let engine: CLIPS.Engine

    public init(engine: CLIPS.Engine) {
        self.engine = engine
    }

    public init() {
        self.init(engine: .init())
    }

}
