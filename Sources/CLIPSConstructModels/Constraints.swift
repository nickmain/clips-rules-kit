// Copyright (c) 2023 David N Main

import Foundation

public enum ConstraintAttributeModel: Codable {
    case types(TypeSpecification)
    case allowedConstants(Constants)
    case range(ConstantModel.Number?, ConstantModel.Number?)
    case cardinality(Int?, Int?)

    public enum TypeSpecification: Codable {
        public enum AllowedType: Codable {
            case symbol, string, lexeme
            case integer, float, number
            case instanceName, instance
            case externalAddress, instanceAddress, factAddress
        }

        case any
        case types([AllowedType])
    }

    public enum Constants: Codable {
        case symbols(Lexemes)
        case strings(Lexemes)
        case lexemes(Lexemes)
        case ints(Ints)
        case floats(Floats)
        case numbers(Numbers)
        case instanceNames(Names)
        case classNames(Names)
        case values(Values)

        public enum Values: Codable {
            case any
            case values([ConstantModel])
        }

        public enum Lexemes: Codable {
            case any
            case values([String])
        }

        public enum Names: Codable {
            case any
            case values([String])
        }

        public enum Ints: Codable {
            case any
            case values([Int])
        }

        public enum Floats: Codable {
            case any
            case values([Double])
        }

        public enum Numbers: Codable {
            case any
            case values([ConstantModel.Number])
        }
    }
}
