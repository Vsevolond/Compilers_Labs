import Foundation

enum DomainTag: Equatable {
    
    case ident(value: String)
    case keyword(value: String)
    case comment
    case unrecognized
    case endOfProgram
    
    var key: String {
        switch self {
        case .ident(_): return "IDENT"
        case .keyword(_): return "KEYWORD"
        case .comment: return "COMMENT"
        case .endOfProgram, .unrecognized: return .empty
        }
    }
    
    var value: String {
        switch self {
        case .ident(let value): return value
        case .keyword(let value): return value
        case .comment, .endOfProgram, .unrecognized: return .empty
        }
    }
}
