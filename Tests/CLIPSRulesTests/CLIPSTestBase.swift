// Copyright (c) 2023 David N Main

import Foundation
import XCTest
import CLIPSRules

class CLIPSTestBase: XCTestCase {

    var clips: CLIPS!

    override func setUpWithError() throws {
        clips = CLIPS()
    }

    override func tearDownWithError() throws {
        clips = nil
    }
}
