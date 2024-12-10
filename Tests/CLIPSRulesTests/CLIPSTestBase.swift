// Copyright (c) 2023 David N Main

import Foundation
import XCTest
import CLIPSRules

class CLIPSTest {
    let engine = CLIPS.Engine()
    let clips: CLIPS.Environment

    init() {
        clips = engine.environment
    }
}

class CLIPSTestBase: XCTestCase {

    var engine: CLIPS.Engine!
    var clips: CLIPS.Environment!

    override func setUpWithError() throws {
        engine = CLIPS.Engine()
        clips = engine.environment
    }

    override func tearDownWithError() throws {
        engine = nil
    }
}
