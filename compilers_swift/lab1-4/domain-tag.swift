import Foundation

enum DomainTag: Equatable {
    
    case ident(value: String)
    case number(value: String)
    case keyword(value: String)
    case operation(value: String)
    case comment
    case unrecognized
    case endOfProgram
    
    var key: String {
        switch self {
        case .ident(_): return "IDENT"
        case .number(_): return "NUMBER"
        case .keyword(_): return "KEYWORD"
        case .operation(_): return "OPERATOR"
        case .comment: return "COMMENT"
        case .endOfProgram, .unrecognized: return .empty
        }
    }
    
    var value: String {
        switch self {
        case .ident(let value), .keyword(let value), .operation(let value), .number(let value): return value
        case .comment, .endOfProgram, .unrecognized: return .empty
        }
    }
}
