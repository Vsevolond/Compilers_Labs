import Foundation

enum ParserError: Error {
    
    case invalid(expected: [String], given: Any, coord: Fragment)
}

final class Parser {
    
    private let tokens: [Token]
    
    private var currentIndex: Int = 0
    private var currentTerm: Term { .init(domain: tokens[currentIndex].tag) }
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func parse() throws { try Program() }
    
    private func updateCurrent() { currentIndex += 1 }
    
    private func error(expected terms: [Term]) -> ParserError {
        .invalid(expected: terms.map { $0.id }, given: tokens[currentIndex].value, coord: tokens[currentIndex].coord)
    }
    
    private func Program() throws {
        guard currentTerm == .type_kw else { throw error(expected: [.type_kw]) }
        updateCurrent()
        try TypeDefs()
        
        guard currentTerm == .var_kw else { throw error(expected: [.var_kw]) }
        updateCurrent()
        try VarDefs()
        
        guard currentTerm == .begin_kw else { throw error(expected: [.begin_kw]) }
        updateCurrent()
        try Statements()
        
        guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
        updateCurrent()
        
        guard currentTerm == .dot_sym else { throw error(expected: [.dot_sym]) }
        updateCurrent()
        
        guard currentTerm == .end else { throw error(expected: [.end]) }
    }
    
    private func VarDefs() throws {
        guard currentTerm == .ident else { return }
        try VarsDef()
        try VarDefs()
    }
    
    private func VarsDef() throws {
        guard currentTerm == .ident else { throw error(expected: [.ident]) }
        updateCurrent()
        try VarNames()
        
        guard currentTerm == .colon_sym else { throw error(expected: [.colon_sym]) }
        updateCurrent()
        try VarType()
        
        guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
        updateCurrent()
    }
    
    private func VarNames() throws {
        guard currentTerm == .comma_sym else { return }
        updateCurrent()
        
        guard currentTerm == .ident else { throw error(expected: [.ident]) }
        updateCurrent()
        try VarNames()
    }
    
    private func VarChain() throws {
        guard currentTerm == .dot_sym else { return }
        updateCurrent()
        
        guard currentTerm == .ident else { throw error(expected: [.ident]) }
        updateCurrent()
        try VarChain()
    }
    
    private func VarType() throws {
        if currentTerm == .pointer_kw {
            updateCurrent()
            
            guard currentTerm == .to_kw else { throw error(expected: [.to_kw]) }
            updateCurrent()
            try Type()
            
        } else {
            try Type()
        }
    }
    
    private func Type() throws {
        switch currentTerm {
        case .integer_type, .real_type, .boolean_type, .local_type: updateCurrent()
        default: throw error(expected: [.integer_type, .real_type, .boolean_type, .local_type])
        }
    }
    
    private func TypeDefs() throws {
        guard currentTerm == .local_type else { return }
        try TypeDef()
        try TypeDefs()
    }
    
    private func TypeDef() throws {
        guard currentTerm == .local_type else { throw error(expected: [.local_type]) }
        updateCurrent()
        
        guard currentTerm == .typeAssignment_op else { throw error(expected: [.typeAssignment_op]) }
        updateCurrent()
        
        guard currentTerm == .record_kw else { throw error(expected: [.record_kw]) }
        updateCurrent()
        try ParentType()
        try VarDefs()
        
        guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
        updateCurrent()
        
        guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
        updateCurrent()
    }
    
    private func ParentType() throws {
        guard currentTerm == .openBracket_sym else { return }
        updateCurrent()
        try Type()
        
        guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
        updateCurrent()
    }
    
    private func Statements() throws {
        let possible: Set<Term> = [.ident, .new_kw, .if_kw, .while_kw]
        
        guard possible.contains(currentTerm) else { return }
        try Statement()
        try Statements()
    }
    
    private func Statement() throws {
        if currentTerm == .ident {
            updateCurrent()
            try Equation()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
        } else if currentTerm == .new_kw {
            updateCurrent()
            
            guard currentTerm == .openBracket_sym else { throw error(expected: [.openBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .ident else { throw error(expected: [.ident]) }
            updateCurrent()
            
            guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
        } else if currentTerm == .if_kw {
            updateCurrent()
            try Expr()
            
            guard currentTerm == .then_kw else { throw error(expected: [.then_kw]) }
            updateCurrent()
            try Statements()
            
            guard currentTerm == .else_kw else { throw error(expected: [.else_kw]) }
            updateCurrent()
            try Statements()
            
            guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
        } else if currentTerm == .while_kw {
            updateCurrent()
            try Expr()
            
            guard currentTerm == .do_kw else { throw error(expected: [.do_kw]) }
            updateCurrent()
            try Statements()
            
            guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
        } else {
            throw error(expected: [.ident, .new_kw, .if_kw, .while_kw])
        }
    }
    
    private func Equation() throws {
        if currentTerm == .dot_sym || currentTerm == .varAssignment_op {
            try VarEquation()
            
        } else {
            try PointerEquation()
        }
    }
    
    private func VarEquation() throws {
        try VarChain()
        
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        updateCurrent()
        try Expr()
    }
    
    private func PointerEquation() throws {
        guard currentTerm == .dereference_op else { throw error(expected: [.dereference_op]) }
        updateCurrent()
        
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        updateCurrent()
        
        guard currentTerm == .ident else { throw error(expected: [.ident]) }
        updateCurrent()
        try VarChain()
    }
    
    private func Expr() throws {
        try ArithmExpr()
        try CmpExpr()
    }
    
    private func CmpExpr() throws {
        let possible: Set<Term> = [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op]
        
        guard possible.contains(currentTerm) else { return }
        try CmpOp()
        try ArithmExpr()
    }
    
    private func CmpOp() throws {
        switch currentTerm {
        case .less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op: updateCurrent()
        default: throw error(expected: [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op])
        }
    }
    
    private func ArithmExpr() throws {
        try Term()
        try AddExpr()
    }
    
    private func AddExpr() throws {
        let possible: Set<Term> = [.addition_op, .substraction_op, .or_op]
        
        guard possible.contains(currentTerm) else { return }
        try AddOp()
        try ArithmExpr()
    }
    
    private func AddOp() throws {
        switch currentTerm {
        case .addition_op, .substraction_op, .or_op: updateCurrent()
        default: throw error(expected: [.addition_op, .substraction_op, .or_op])
        }
    }
    
    private func Term() throws {
        try Factor()
        try MulExpr()
    }
    
    private func MulExpr() throws {
        let possible: Set<Term> = [.multiplication_op, .division_op, .div_op, .mod_op, .and_op]
        
        guard possible.contains(currentTerm) else { return }
        try MulOp()
        try Term()
    }
    
    private func MulOp() throws {
        switch currentTerm {
        case .multiplication_op, .division_op, .div_op, .mod_op, .and_op: updateCurrent()
        default: throw error(expected: [.multiplication_op, .division_op, .div_op, .mod_op, .and_op])
        }
    }
    
    private func Factor() throws {
        if currentTerm == .not_op {
            updateCurrent()
            try Factor()
            
        } else if currentTerm == .ident {
            updateCurrent()
            try VarChain()
            
        } else if currentTerm == .openBracket_sym {
            updateCurrent()
            try Expr()
            
            guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
            updateCurrent()
            
        } else {
            try Const()
        }
    }
    
    private func Const() throws {
        switch currentTerm {
        case .integer_const, .real_const, .boolean_const: updateCurrent()
        default: throw error(expected: [.integer_const, .real_const, .boolean_const])
        }
    }
}
