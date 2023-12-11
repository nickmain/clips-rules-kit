// Copyright (c) 2023 David N Main

import Foundation

public enum ConstantModel: Codable {
    case symbol(String)
    case string(String)
    case integer(Int)
    case float(Double)
    case instanceName(String)

    public enum Number: Codable {
        case int(Int)
        case float(Double)
    }
}

public enum VariableModel: Codable {
    case singleField(String)
    case multiField(String)
    case global(String)
}

indirect
public enum ExpressionModel: Codable {
    case constant(ConstantModel)
    case variable(VariableModel)
    case functionCall(_ name: String, _ args: [ExpressionModel])
}
