// Copyright (c) 2023 David N Main

import Foundation
import CLIPSRules

struct CouldNotFindSample: LocalizedError {
    let filename: String
    public var errorDescription: String? { "Could not find sample: \(filename)" }
}

// Get the path to a bundled sample clp file
func pathFor(sample filename: String) throws -> String {
    guard let doc = Bundle.module.url(forResource: filename,
                                      withExtension: "clp",
                                      subdirectory: "samples")
    else {
        throw  CouldNotFindSample(filename: filename)
    }

    return doc.path(percentEncoded: false)
}
