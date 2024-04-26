import Foundation

enum DomainTag: String, Hashable {
    
    case star
    case plus
    case mark
    case openBracket
    case closeBracket
    case quote
    case ident
    case char
    case unrecognized
    case endOfGrammar
    
    var value: String {
        switch self {
        case .star: "*"
        case .plus: "+"
        case .mark: "'"
        case .openBracket: "("
        case .closeBracket: ")"
        case .quote: "\""
        case .ident: "some ident"
        case .char: "some char"
        case .unrecognized: "unrecognized"
        case .endOfGrammar: "$"
        }
    }
}
