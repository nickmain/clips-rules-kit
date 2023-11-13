// Copyright (c) 2023 David N Main

import Foundation

public struct FactTemplateModel: Codable {
    let name: String
    let comment: String?
    let slots: [Slot]

    public enum Slot: Codable {
        case singleSlot(_ name: String, _ attributes: [Attribute])
        case multiSlot(_ name: String, _ attributes: [Attribute])

        public enum Attribute: Codable {
            case default_(Default)
            case constraint(ConstraintAttributeModel)

            public enum Default: Codable {
                case derive
                case none
                case staticValues([ExpressionModel])
                case dynamicValues([ExpressionModel])
            }
        }
    }
}
