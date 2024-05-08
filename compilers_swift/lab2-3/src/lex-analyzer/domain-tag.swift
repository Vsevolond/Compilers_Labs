import Foundation

enum DomainTag: String, Hashable {
    
    case star
    case mark
    case openBracket
    case closeBracket
    case ident
    case char
    case unrecognized
    case endOfInput
    
    var value: String {
        switch self {
        case .star: "*"
        case .mark: "'"
        case .openBracket: "("
        case .closeBracket: ")"
        case .ident: "ident"
        case .char: "char"
        case .unrecognized: "unrecognized"
        case .endOfInput: "$"
        }
    }
}
