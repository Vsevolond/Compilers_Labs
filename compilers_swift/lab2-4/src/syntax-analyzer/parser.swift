import Foundation

enum ParserError: Error {
    
    case invalid(expected: [String], given: Any, coord: Fragment)
}

final class Parser {
    
    private let tokens: [Token]
    
    private var currentIndex: Int = 0
    private var currentToken: Token { tokens[currentIndex] }
    private var currentTerm: Term { .init(domain: currentToken.tag) }
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func parse() throws -> Program { return try Program() }
    
    private func updateCurrent() { currentIndex += 1 }
    
    private func error(expected terms: [Term]) -> ParserError {
        .invalid(expected: terms.map { $0.id }, given: tokens[currentIndex].value, coord: tokens[currentIndex].coord)
    }
    
    // Program -> type_kw TypeDefs var_kw VarDefs begin_kw Statements end_kw dot_sym .
    private func Program() throws -> Program {
        guard currentTerm == .type_kw else { throw error(expected: [.type_kw]) }
        updateCurrent()
        let typeDefs = try TypeDefs()
        
        guard currentTerm == .var_kw else { throw error(expected: [.var_kw]) }
        updateCurrent()
        let varDefs = try VarDefs()
        
        guard currentTerm == .begin_kw else { throw error(expected: [.begin_kw]) }
        updateCurrent()
        let statements = try Statements()
        
        guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
        updateCurrent()
        
        guard currentTerm == .dot_sym else { throw error(expected: [.dot_sym]) }
        updateCurrent()
        
        guard currentTerm == .end else { throw error(expected: [.end]) }
        
        return lab2_4.Program(typeDefs: typeDefs, varDefs: varDefs, statements: statements)
    }
    
    // VarDefs -> VarsDef VarDefs | .
    private func VarDefs() throws -> [VarDef] {
        guard currentTerm == .ident else { return [] }
        let varsDef = try VarsDef()
        let varDefs = try VarDefs()
        
        return varsDef.withAppending(varDefs)
    }
    
    // VarsDef -> ident VarNames colon_sym VarType semicolon_sym .
    private func VarsDef() throws -> [VarDef] {
        guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
        updateCurrent()
        let varNames = try VarNames()
        
        guard currentTerm == .colon_sym else { throw error(expected: [.colon_sym]) }
        updateCurrent()
        let varType = try VarType()
        
        guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
        updateCurrent()
        
        return [variable].withAppending(varNames).map { VarDef(name: $0, type: varType) }
    }
    
    // VarNames -> comma_sym ident VarNames | .
    private func VarNames() throws -> [String] {
        guard currentTerm == .comma_sym else { return [] }
        updateCurrent()
        
        guard currentTerm == .ident, let varName = currentToken.value as? String else { throw error(expected: [.ident]) }
        updateCurrent()
        let varNames = try VarNames()
        
        return [varName].withAppending(varNames)
    }
    
    // VarChain -> dot_sym ident VarChain | .
    private func VarChain() throws -> VarChain {
        guard currentTerm == .dot_sym else { return lab2_4.VarChain(variables: []) }
        updateCurrent()
        
        guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
        updateCurrent()
        let varChain = try VarChain()
        
        return lab2_4.VarChain(variables: [variable].withAppending(varChain.variables))
    }
    
    // VarType -> Type | pointer_kw to_kw Type .
    private func VarType() throws -> VarType {
        if currentTerm == .pointer_kw {
            updateCurrent()
            
            guard currentTerm == .to_kw else { throw error(expected: [.to_kw]) }
            updateCurrent()
            
            let type = try Type()
            return lab2_4.VarType(type: type, isPointer: true)
            
        } else {
            let type = try Type()
            return lab2_4.VarType(type: type, isPointer: false)
        }
    }
    
    // Type -> integer_type | real_type | boolean_type | local_type .
    private func Type() throws -> SomeType {
        switch currentTerm {
        case .integer_type, .real_type, .boolean_type:
            let typeName = currentToken.tag.value
            updateCurrent()
            
            return SomeType(kind: .global, name: typeName)
            
        case .local_type:
            guard let typeName = currentToken.value as? String else { fatalError("can't cast") }
            updateCurrent()
            
            return SomeType(kind: .local, name: typeName)
            
        default: throw error(expected: [.integer_type, .real_type, .boolean_type, .local_type])
        }
    }
    
    // TypeDefs -> TypeDef TypeDefs | .
    private func TypeDefs() throws -> [TypeDef] {
        guard currentTerm == .local_type else { return [] }
        let typeDef = try TypeDef()
        let typeDefs = try TypeDefs()
        
        return typeDefs.withInserting(at: 0, elem: typeDef)
    }
    
    // TypeDef -> local_type typeAssignment_op record_kw ParentType VarDefs end_kw semicolon_sym .
    private func TypeDef() throws -> TypeDef {
        guard currentTerm == .local_type, let typeName = currentToken.value as? String else { throw error(expected: [.local_type]) }
        updateCurrent()
        
        guard currentTerm == .typeAssignment_op else { throw error(expected: [.typeAssignment_op]) }
        updateCurrent()
        
        guard currentTerm == .record_kw else { throw error(expected: [.record_kw]) }
        updateCurrent()
        let parentType = try ParentType()
        let varDefs = try VarDefs()
        
        guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
        updateCurrent()
        
        guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
        updateCurrent()
        
        return lab2_4.TypeDef(name: typeName, parentType: parentType, varDefs: varDefs)
    }
    
    // ParentType -> openbracket_sym Type closebracket_sym | .
    private func ParentType() throws -> SomeType? {
        guard currentTerm == .openBracket_sym else { return .none }
        updateCurrent()
        let type = try Type()
        
        guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
        updateCurrent()
        
        return type
    }
    
    // Statements -> Statement Statements | .
    private func Statements() throws -> [Statement] {
        let possible: Set<Term> = [.ident, .new_kw, .if_kw, .while_kw]
        
        guard possible.contains(currentTerm) else { return [] }
        let statement = try Statement()
        let statements = try Statements()
        
        return statements.withInserting(at: 0, elem: statement)
    }
    
    // Statement -> ident VarChain Equation semicolon_sym |
    //              new_kw openbracket_sym ident closebracket_sym semicolon_sym |
    //              if_kw Expr then_kw Statements else_kw Statements end_kw semicolon_sym |
    //              while_kw Expr do_kw Statements end_kw semicolon_sym .
    private func Statement() throws -> Statement {
        if currentTerm == .ident, let variable = currentToken.value as? String {
            updateCurrent()
            
            let varChain = try VarChain()
            let (expr, isDereference) = try Equation()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return AssignStatement(variable: .init(variables: [variable].withAppending(varChain.variables)), expr: expr, isDereference: isDereference)
            
        } else if currentTerm == .new_kw {
            updateCurrent()
            
            guard currentTerm == .openBracket_sym else { throw error(expected: [.openBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
            updateCurrent()
            
            let varChain = try VarChain()
            
            guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return CreateStatement(pointerName: .init(variables: [variable].withAppending(varChain.variables)))
            
        } else if currentTerm == .if_kw {
            updateCurrent()
            let expr = try Expr()
            
            guard currentTerm == .then_kw else { throw error(expected: [.then_kw]) }
            updateCurrent()
            let thenBranch = try Statements()
            
            guard currentTerm == .else_kw else { throw error(expected: [.else_kw]) }
            updateCurrent()
            let elseBranch = try Statements()
            
            guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return IfStatement(condition: expr, thenBranch: thenBranch, elseBranch: elseBranch)
            
        } else if currentTerm == .while_kw {
            updateCurrent()
            let expr = try Expr()
            
            guard currentTerm == .do_kw else { throw error(expected: [.do_kw]) }
            updateCurrent()
            let body = try Statements()
            
            guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return WhileStatement(condition: expr, body: body)
            
        } else {
            throw error(expected: [.ident, .new_kw, .if_kw, .while_kw])
        }
    }
    
    // Equation -> VarEquation | PointerEquation .
    private func Equation() throws -> (expr: Expr, isDereference: Bool) {
        if currentTerm == .dereference_op {
           return (try PointerEquation(), true)
            
        } else {
            return (try VarEquation(), false)
        }
    }
    
    // VarEquation -> varAssignment_op Expr .
    private func VarEquation() throws -> Expr {
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        updateCurrent()
        let expr = try Expr()
        
        return expr
    }
    
    // PointerEquation -> dereference_op varAssignment_op ident VarChain .
    private func PointerEquation() throws -> Expr {
        guard currentTerm == .dereference_op else { throw error(expected: [.dereference_op]) }
        updateCurrent()
        
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        updateCurrent()
        
        guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
        updateCurrent()
        let varChain = try VarChain()
        
        return VariableExpr(varName: .init(variables: [variable].withAppending(varChain.variables)))
    }
    
    // Expr -> ArithmExpr CmpExpr .
    private func Expr() throws -> Expr {
        let expr = try ArithmExpr()
        
        if let (cmpOp, cmpExpr) = try CmpExpr() {
            return BinOpExpr(left: expr, op: cmpOp, right: cmpExpr)
            
        } else {
            return expr
        }
    }
    
    // CmpExpr -> CmpOp ArithmExpr | .
    private func CmpExpr() throws -> (op: String, right: Expr)? {
        let possible: Set<Term> = [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let cmpOp = try CmpOp()
        let expr = try ArithmExpr()
        
        return (cmpOp, expr)
    }
    
    // CmpOp -> less_op | greater_op | lessOrEqual_op | greaterOrEqual_op | notEqual_op | equal_op .
    private func CmpOp() throws -> String {
        switch currentTerm {
            
        case .less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op:
            let op = currentToken.tag.value
            updateCurrent()
            
            return op
            
        default: throw error(expected: [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op])
        }
    }
    
    // ArithmExpr -> Term AddExpr .
    private func ArithmExpr() throws -> Expr {
        let term = try Term()
        
        if let (addOp, expr) = try AddExpr() {
            return BinOpExpr(left: term, op: addOp, right: expr)
            
        } else {
            return term
        }
    }
    
    // AddExpr -> AddOp ArithmExpr | .
    private func AddExpr() throws -> (op: String, right: Expr)? {
        let possible: Set<Term> = [.addition_op, .substraction_op, .or_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let addOp = try AddOp()
        let expr = try ArithmExpr()
        
        return (addOp, expr)
    }
    
    // AddOp -> addition_op | substraction_op | or_op .
    private func AddOp() throws -> String {
        switch currentTerm {
        case .addition_op, .substraction_op, .or_op: 
            let op = currentToken.tag.value
            updateCurrent()
            
            return op
            
        default: throw error(expected: [.addition_op, .substraction_op, .or_op])
        }
    }
    
    // Term -> Factor MulExpr .
    private func Term() throws -> Expr {
        let factor = try Factor()
        
        if let (mulOp, mulExpr) = try MulExpr() {
            return BinOpExpr(left: factor, op: mulOp, right: mulExpr)
            
        } else {
            return factor
        }
    }
    
    // MulExpr -> MulOp Term | .
    private func MulExpr() throws -> (op: String, right: Expr)? {
        let possible: Set<Term> = [.multiplication_op, .division_op, .div_op, .mod_op, .and_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let mulOp = try MulOp()
        let term = try Term()
        
        return (mulOp, term)
    }
    
    // MulOp -> multiplication_op | division_op | div_op | mod_op | and_op .
    private func MulOp() throws -> String {
        switch currentTerm {
            
        case .multiplication_op, .division_op, .div_op, .mod_op, .and_op:
            let op = currentToken.tag.value
            updateCurrent()
            
            return op
            
        default: throw error(expected: [.multiplication_op, .division_op, .div_op, .mod_op, .and_op])
        }
    }
    
    // Factor -> not_op Factor | Const | ident VarChain | openbracket_sym Expr closebracket_sym .
    private func Factor() throws -> Expr {
        if currentTerm == .not_op {
            let op = currentToken.tag.value
            updateCurrent()
            
            let expr = try Factor()
            return UnOpExpr(op: op, expr: expr)
            
        } else if currentTerm == .ident, let variable = currentToken.value as? String {
            updateCurrent()
            let varChain = try VarChain()
            
            return VariableExpr(varName: .init(variables: [variable].withAppending(varChain.variables)))
            
        } else if currentTerm == .openBracket_sym {
            updateCurrent()
            let expr = try Expr()
            
            guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
            updateCurrent()
            return expr
            
        } else {
            let const = try Const()
            return const
        }
    }
    
    // Const -> integer_const | real_const | boolean_const .
    private func Const() throws -> Expr {
        switch currentTerm {
            
        case .integer_const, .real_const, .boolean_const:
            let typeName = currentToken.tag.value
            let value = currentToken.value
            updateCurrent()
            
            return ConstExpr(value: value, type: .init(kind: .global, name: typeName))
            
        default: throw error(expected: [.integer_const, .real_const, .boolean_const])
        }
    }
}
