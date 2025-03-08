// Copyright (c) 2025 David N Main

import Foundation
import Testing
@testable import CLIPSCore
@testable import CLIPSRules

class MetaDataTests: CLIPSTest {

    @Test
    func experiment() throws {
        clips.registerFactCallbacks()
        clips.installUserDataRecord()

        let fact = try clips.assert(fact: "(foo bar)")

        #expect(fact.ptr.pointee.whichDeftemplate != nil)
        if let templatePtr = fact.ptr.pointee.whichDeftemplate {
            let userData = clips.fetchUserData(from: templatePtr)
            #expect(userData?.message == "Jello world")

            userData?.message = "altered"
            let userData2 = clips.fetchUserData(from: templatePtr)
            #expect(userData?.message == "altered")
        }

        if let factUserData = fact.ptr.pointee.patternHeader?.{

        }

            let userData = clips.fetchUserData(from: templatePtr)
    }
}
