import Foundation

class GrammarElem: Hashable {
    
    let id: String
    
    var isNonTerm: Bool { false }
    var isTerm: Bool { false }
    var isEmpty: Bool { self == .eps }
    
    static let eps: GrammarElem = .init(id: "𝛆")
    
    init(id: String) {
        self.id = id
    }
    
    static func == (lhs: GrammarElem, rhs: GrammarElem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func | (lhs: GrammarElem, rhs: GrammarElem) -> [[GrammarElem]] {
        [[lhs], [rhs]]
    }
}

infix operator |: AdditionPrecedence

extension Array where Element == GrammarElem {
    
    static func | (lhs: [GrammarElem], rhs: [GrammarElem]) -> [[GrammarElem]] {
        [lhs, rhs]
    }
    
    static func | (lhs: [GrammarElem], rhs: GrammarElem) -> [[GrammarElem]] {
        [lhs, [rhs]]
    }
}

extension Array where Element == [GrammarElem] {
    
    static func | (lhs: [[GrammarElem]], rhs: GrammarElem) -> [[GrammarElem]] {
        var result: [[GrammarElem]] = lhs
        result.append([rhs])
        
        return result
    }
    
    static func | (lhs: [[GrammarElem]], rhs: [GrammarElem]) -> [[GrammarElem]] {
        var result: [[GrammarElem]] = lhs
        result.append(rhs)
        
        return result
    }
}

extension GrammarElem {
    
    static let type_kw = Term(domain: .keyword(.type_kw))
    static let record_kw = Term(domain: .keyword(.record_kw))
    static let end_kw = Term(domain: .keyword(.end_kw))
    static let var_kw = Term(domain: .keyword(.var_kw))
    static let begin_kw = Term(domain: .keyword(.begin_kw))
    static let new_kw = Term(domain: .keyword(.new_kw))
    static let while_kw = Term(domain: .keyword(.while_kw))
    static let do_kw = Term(domain: .keyword(.do_kw))
    static let if_kw = Term(domain: .keyword(.if_kw))
    static let then_kw = Term(domain: .keyword(.then_kw))
    static let else_kw = Term(domain: .keyword(.else_kw))
    static let pointer_kw = Term(domain: .keyword(.pointer_kw))
    static let to_kw = Term(domain: .keyword(.to_kw))
    
    static let typeAssignment_op = Term(domain: .operation(.assignment(.typeAssignment_op)))
    static let varAssignment_op = Term(domain: .operation(.assignment(.varAssignment_op)))
    
    static let dereference_op = Term(domain: .operation(.pointer(.dereference_op)))
    
    static let div_op = Term(domain: .operation(.arithmetic(.div_op)))
    static let mod_op = Term(domain: .operation(.arithmetic(.mod_op)))
    static let and_op = Term(domain: .operation(.arithmetic(.and_op)))
    static let not_op = Term(domain: .operation(.arithmetic(.not_op)))
    static let or_op = Term(domain: .operation(.arithmetic(.or_op)))
    static let addition_op = Term(domain: .operation(.arithmetic(.addition_op)))
    static let substraction_op = Term(domain: .operation(.arithmetic(.substraction_op)))
    static let multiplication_op = Term(domain: .operation(.arithmetic(.multiplication_op)))
    static let division_op = Term(domain: .operation(.arithmetic(.division_op)))
    
    static let equal_op = Term(domain: .operation(.compare(.equal_op)))
    static let less_op = Term(domain: .operation(.compare(.less_op)))
    static let lessOrEqual_op = Term(domain: .operation(.compare(.lessOrEqual_op)))
    static let greater_op = Term(domain: .operation(.compare(.greater_op)))
    static let greaterOrEqual_op = Term(domain: .operation(.compare(.greaterOrEqual_op)))
    static let notEqual_op = Term(domain: .operation(.compare(.notEqual_op)))
    
    static let dot_sym = Term(domain: .symbol(.dot_sym))
    static let comma_sym = Term(domain: .symbol(.comma_sym))
    static let colon_sym = Term(domain: .symbol(.colon_sym))
    static let semicolon_sym = Term(domain: .symbol(.semicolon_sym))
    static let openBracket_sym = Term(domain: .symbol(.openBracket_sym))
    static let closeBracket_sym = Term(domain: .symbol(.closeBracket_sym))
    
    static let integer_type = Term(domain: .typeDeclare(.global(.integer_type)))
    static let real_type = Term(domain: .typeDeclare(.global(.real_type)))
    static let boolean_type = Term(domain: .typeDeclare(.global(.boolean_type)))
    static let local_type = Term(domain: .typeDeclare(.local_type))
    
    static let integer_const = Term(domain: .const(.integer_const))
    static let real_const = Term(domain: .const(.real_const))
    static let boolean_const = Term(domain: .const(.boolean_const))
    
    static let ident = Term(domain: .ident)

    static let end: Term = .init(domain: .endOfInput)
}
