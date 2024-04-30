import Foundation

enum ParserError: Error {
    
    case invalid(expected: [String], given: Any, coord: Fragment)
}

final class Parser {
    
    private let tokens: [Token]
    
    private var currentIndex: Int = 0
    private var currentTerm: Term { .init(domain: tokens[currentIndex].tag) }
    
    private var NProgram = NonTerm(id: "Program")
    private var NVarDefs = NonTerm(id: "VarDefs")
    private var NVarsDef = NonTerm(id: "VarsDef")
    private var NVarNames = NonTerm(id: "VarNames")
    private var NVarChain = NonTerm(id: "VarChain")
    private var NVarType = NonTerm(id: "NVarType")
    private var NType = NonTerm(id: "Type")
    private var NTypeDefs = NonTerm(id: "TypeDefs")
    private var NTypeDef = NonTerm(id: "TypeDef")
    private var NParentType = NonTerm(id: "ParentType")
    private var NStatements = NonTerm(id: "Statements")
    private var NStatement = NonTerm(id: "Statement")
    private var NEquation = NonTerm(id: "Equation")
    private var NVarEquation = NonTerm(id: "VarEquation")
    private var NPointerEquation = NonTerm(id: "PointerEquation")
    private var NExpr = NonTerm(id: "Expr")
    private var NCmpExpr = NonTerm(id: "CmpExpr")
    private var NCmpOp = NonTerm(id: "CmpOp")
    private var NArithmExpr = NonTerm(id: "ArithmExpr")
    private var NAddExpr = NonTerm(id: "AddExpr")
    private var NAddOp = NonTerm(id: "AddOp")
    private var NTerm = NonTerm(id: "Term")
    private var NMulExpr = NonTerm(id: "MulExpr")
    private var NMulOp = NonTerm(id: "MulOp")
    private var NFactor = NonTerm(id: "Factor")
    private var NConst = NonTerm(id: "Const")
    
    init(tokens: [Token]) {
        self.tokens = tokens
        setupGrammar()
    }
    
    private func setupGrammar() {
        NProgram => [.type_kw, NTypeDefs, .var_kw, NVarDefs, .begin_kw, NStatements, .end_kw, .dot_sym]
        
        NVarDefs => [NVarsDef, NVarDefs] | .eps
        NVarsDef => [.ident, NVarNames, .colon_sym, NVarType, .semicolon_sym]
        NVarNames => [.comma_sym, .ident, NVarNames] | .eps
        NVarChain => [.dot_sym, .ident, NVarChain] | .eps
        NVarType => [.pointer_kw, .to_kw, NType] | NType
        
        NType => .integer_type | .real_type | .boolean_type | .local_type
        NTypeDefs => [NTypeDef, NTypeDefs] | .eps
        NTypeDef => [.local_type, .typeAssignment_op, .record_kw, NParentType, NVarDefs, .end_kw, .semicolon_sym]
        NParentType => [.openBracket_sym, NType, .closeBracket_sym] | .eps
        
        NStatements => [NStatement, NStatements] | .eps
        NStatement => [.ident, NEquation, .semicolon_sym] | 
                      [.new_kw, .openBracket_sym, .ident, .closeBracket_sym, .semicolon_sym] |
                      [.if_kw, NExpr, .then_kw, NStatements, .else_kw, NStatements, .end_kw, .semicolon_sym] |
                      [.while_kw, NExpr, .do_kw, NStatements, .end_kw, .semicolon_sym]
        
        NEquation => NVarEquation | NPointerEquation
        NVarEquation => [NVarChain, .varAssignment_op, NExpr]
        NPointerEquation => [.dereference_op, .varAssignment_op, .ident, NVarChain]
        
        NExpr => [NArithmExpr, NCmpExpr]
        
        NCmpExpr => [NCmpOp, NArithmExpr] | .eps
        NCmpOp => .less_op | .greater_op | .lessOrEqual_op | .greaterOrEqual_op | .notEqual_op | .equal_op
        
        NArithmExpr => [NTerm, NAddExpr]
        
        NAddExpr => [NAddOp, NArithmExpr] | .eps
        NAddOp => .addition_op | .substraction_op | .or_op
        
        NTerm => [NFactor, NMulExpr]
        
        NMulExpr => [NMulOp, NTerm] | .eps
        NMulOp => .multiplication_op | .division_op | .div_op | .mod_op | .and_op
        
        NFactor => [.not_op, NFactor] | NConst | [.ident, NVarChain] | [.openBracket_sym, NExpr, .closeBracket_sym]
        NConst => .integer_const | .real_const | .boolean_const
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
        guard NVarsDef.firstSet.contains(currentTerm) else { return }  // ???
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
        guard NTypeDef.firstSet.contains(currentTerm) else { return }  // ???
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
        guard NStatement.firstSet.contains(currentTerm) else { return }
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
        if NVarEquation.firstSet.contains(currentTerm) {
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
        guard NCmpOp.firstSet.contains(currentTerm) else { return }
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
        guard NAddOp.firstSet.contains(currentTerm) else { return }
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
        guard NMulOp.firstSet.contains(currentTerm) else { return }
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
