import Foundation

enum ParserError: Error {
    
    case invalid(expected: [String], given: Any, coord: Fragment)
}

final class Parser {
    
    private let tokens: [Token]
    
    private var currentIndex: Int = 0
    private var currentToken: Token { tokens[currentIndex] }
    private var currentTerm: Term { .init(domain: currentToken.tag) }
    
    private var lastToken: Token { tokens[currentIndex - 1] }
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    @discardableResult
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
        
        let program = lab3_3.Program(typeDefs: typeDefs, varDefs: varDefs, statements: statements)
        try program.check()
        
        return program
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
        
        return [variable].withAppending(varNames).map { VarDef(name: $0, varType: varType) }
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
        guard currentTerm == .dot_sym else { return lab3_3.VarChain(variables: [], coord: lastToken.coord) }
        updateCurrent()
        
        guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
        let start = currentToken.coord.start
        
        updateCurrent()
        let varChain = try VarChain()
        
        return lab3_3.VarChain(variables: [variable].withAppending(varChain.variables), coord: .init(start: start, end: varChain.coord.end))
    }
    
    // VarType -> Type | pointer_kw to_kw Type .
    private func VarType() throws -> VarType {
        if currentTerm == .pointer_kw {
            updateCurrent()
            
            guard currentTerm == .to_kw else { throw error(expected: [.to_kw]) }
            updateCurrent()
            
            let type = try Type()
            return lab3_3.VarType(type: type, isPointer: true)
            
        } else {
            let type = try Type()
            return lab3_3.VarType(type: type, isPointer: false)
        }
    }
    
    // Type -> integer_type | real_type | boolean_type | local_type .
    private func Type() throws -> SomeType {
        let coord = currentToken.coord
        
        switch currentTerm {
        case .integer_type:
            let typeName = currentToken.tag.value
            updateCurrent()
            
            return SomeType(kind: .integer, name: typeName, coord: coord)
            
        case .real_type:
            let typeName = currentToken.tag.value
            updateCurrent()
            
            return SomeType(kind: .real, name: typeName, coord: coord)
            
        case .boolean_type:
            let typeName = currentToken.tag.value
            updateCurrent()
            
            return SomeType(kind: .boolean, name: typeName, coord: coord)
            
        case .local_type:
            guard let typeName = currentToken.value as? String else { fatalError("can't cast") }
            updateCurrent()
            
            return SomeType(kind: .local, name: typeName, coord: coord)
            
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
        
        return lab3_3.TypeDef(name: typeName, parentType: parentType, varDefs: varDefs)
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
            let start = currentToken.coord.start
            updateCurrent()
            
            let varChain = try VarChain()
            let (expr, isDereference, derefCoord, assignCoord) = try Equation()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return AssignStatement(variable: .init(variables: [variable].withAppending(varChain.variables),
                                                   coord: .init(start: start, end: varChain.coord.end)),
                                   expr: expr, isDereference: isDereference, assignCoord: assignCoord, derefCoord: derefCoord)
            
        } else if currentTerm == .new_kw {
            updateCurrent()
            
            guard currentTerm == .openBracket_sym else { throw error(expected: [.openBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .ident, let variable = currentToken.value as? String else { throw error(expected: [.ident]) }
            let start = currentToken.coord.start
            updateCurrent()
            
            let varChain = try VarChain()
            
            guard currentTerm == .closeBracket_sym else { throw error(expected: [.closeBracket_sym]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return CreateStatement(pointerName: .init(variables: [variable].withAppending(varChain.variables),
                                                      coord: .init(start: start, end: varChain.coord.end)))
            
        } else if currentTerm == .if_kw {
            updateCurrent()
            let (expr, coord) = try Expr()
            
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
            
            return IfStatement(condition: expr, conditionCoord: coord, thenBranch: thenBranch, elseBranch: elseBranch)
            
        } else if currentTerm == .while_kw {
            updateCurrent()
            let (expr, coord) = try Expr()
            
            guard currentTerm == .do_kw else { throw error(expected: [.do_kw]) }
            updateCurrent()
            let body = try Statements()
            
            guard currentTerm == .end_kw else { throw error(expected: [.end_kw]) }
            updateCurrent()
            
            guard currentTerm == .semicolon_sym else { throw error(expected: [.semicolon_sym]) }
            updateCurrent()
            
            return WhileStatement(condition: expr, conditionCoord: coord, body: body)
            
        } else {
            throw error(expected: [.ident, .new_kw, .if_kw, .while_kw])
        }
    }
    
    // Equation -> VarEquation | PointerEquation .
    private func Equation() throws -> (expr: Expr, isDereference: Bool, derefCoord: Fragment, assignCoord: Fragment) {
        if currentTerm == .dereference_op {
            let pointerEquation = try PointerEquation()
            return (pointerEquation.expr, true, pointerEquation.derefCoord, pointerEquation.assignCoord)
            
        } else {
            let varEquation = try VarEquation()
            return (varEquation.expr, false, .zero, varEquation.assignCoord)
        }
    }
    
    // VarEquation -> varAssignment_op Expr .
    private func VarEquation() throws -> (expr: Expr, assignCoord: Fragment) {
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        let assignCoord = currentToken.coord
        
        updateCurrent()
        let (expr, _) = try Expr()
        
        return (expr, assignCoord)
    }
    
    // PointerEquation -> dereference_op varAssignment_op Expr .
    private func PointerEquation() throws -> (expr: Expr, derefCoord: Fragment, assignCoord: Fragment) {
        guard currentTerm == .dereference_op else { throw error(expected: [.dereference_op]) }
        let derefCoord = currentToken.coord
        updateCurrent()
        
        guard currentTerm == .varAssignment_op else { throw error(expected: [.varAssignment_op]) }
        let assignCoord = currentToken.coord
        updateCurrent()
        
        let (expr, _) = try Expr()
        
        return (expr, derefCoord, assignCoord)
    }
    
    // Expr -> ArithmExpr CmpExpr .
    private func Expr() throws -> (expr: Expr, coord: Fragment) {
        let (expr, coord) = try ArithmExpr()
        
        if let (cmpOp, opCoord, cmpExpr, exprCoord) = try CmpExpr() {
            return (BinOpExpr(left: expr, right: cmpExpr, op: cmpOp, opCoord: opCoord), .init(start: coord.start, end: exprCoord.end))
            
        } else {
            return (expr, coord)
        }
    }
    
    // CmpExpr -> CmpOp ArithmExpr | .
    private func CmpExpr() throws -> (op: OperationKind, opCoord: Fragment, expr: Expr, exprCoord: Fragment)? {
        let possible: Set<Term> = [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let (cmpOp, opCoord) = try CmpOp()
        let (expr, exprCoord) = try ArithmExpr()
        
        return (cmpOp, opCoord, expr, exprCoord)
    }
    
    // CmpOp -> less_op | greater_op | lessOrEqual_op | greaterOrEqual_op | notEqual_op | equal_op .
    private func CmpOp() throws -> (op: OperationKind, coord: Fragment) {
        let coord = currentToken.coord
        
        switch currentTerm {
            
        case .less_op:
            updateCurrent()
            return (.less, coord)
            
        case .lessOrEqual_op:
            updateCurrent()
            return (.lessOrEqual, coord)
            
        case .greater_op:
            updateCurrent()
            return (.greater, coord)
            
        case .greaterOrEqual_op:
            updateCurrent()
            return (.greater, coord)
            
        case .equal_op:
            updateCurrent()
            return (.equal, coord)
            
        case .notEqual_op:
            updateCurrent()
            return (.notEqual, coord)
            
        default: throw error(expected: [.less_op, .lessOrEqual_op, .greater_op, .greaterOrEqual_op, .notEqual_op, .equal_op])
        }
    }
    
    // ArithmExpr -> Term AddExpr .
    private func ArithmExpr() throws -> (expr: Expr, coord: Fragment) {
        let (term, coord) = try Term()
        
        if let (addOp, opCoord, expr, exprCoord) = try AddExpr() {
            return (BinOpExpr(left: term, right: expr, op: addOp, opCoord: opCoord), .init(start: coord.start, end: exprCoord.end))
            
        } else {
            return (term, coord)
        }
    }
    
    // AddExpr -> AddOp ArithmExpr | .
    private func AddExpr() throws -> (op: OperationKind, opCoord: Fragment, expr: Expr, exprCoord: Fragment)? {
        let possible: Set<Term> = [.addition_op, .substraction_op, .or_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let (addOp, opCoord) = try AddOp()
        let (expr, exprCoord) = try ArithmExpr()
        
        return (addOp, opCoord, expr, exprCoord)
    }
    
    // AddOp -> addition_op | substraction_op | or_op .
    private func AddOp() throws -> (op: OperationKind, coord: Fragment) {
        let coord = currentToken.coord
        
        switch currentTerm {
        case .addition_op:
            updateCurrent()
            return (.addition, coord)
            
        case .substraction_op:
            updateCurrent()
            return (.substraction, coord)
            
        case .or_op:
            updateCurrent()
            return (.or, coord)
            
        default: throw error(expected: [.addition_op, .substraction_op, .or_op])
        }
    }
    
    // Term -> Factor MulExpr .
    private func Term() throws -> (expr: Expr, coord: Fragment) {
        let (factor, coord) = try Factor()
        
        if let (mulOp, opCoord, mulExpr, exprCoord) = try MulExpr() {
            return (BinOpExpr(left: factor, right: mulExpr, op: mulOp, opCoord: opCoord), .init(start: coord.start, end: exprCoord.end))
            
        } else {
            return (factor, coord)
        }
    }
    
    // MulExpr -> MulOp Term | .
    private func MulExpr() throws -> (op: OperationKind, opCoord: Fragment, expr: Expr, exprCoord: Fragment)? {
        let possible: Set<Term> = [.multiplication_op, .division_op, .div_op, .mod_op, .and_op]
        
        guard possible.contains(currentTerm) else { return .none }
        let (mulOp, opCoord) = try MulOp()
        let (term, coord) = try Term()
        
        return (mulOp, opCoord, term, coord)
    }
    
    // MulOp -> multiplication_op | division_op | div_op | mod_op | and_op .
    private func MulOp() throws -> (op: OperationKind, coord: Fragment) {
        let coord = currentToken.coord
        
        switch currentTerm {
            
        case .multiplication_op, .division_op, .div_op, .mod_op, .and_op:
            updateCurrent()
            return (.multiplication, coord)
            
        case .division_op:
            updateCurrent()
            return (.division, coord)
            
        case .div_op:
            updateCurrent()
            return (.div, coord)
            
        case .mod_op:
            updateCurrent()
            return (.mod, coord)
            
        case .and_op:
            updateCurrent()
            return (.and, coord)
            
        default: throw error(expected: [.multiplication_op, .division_op, .div_op, .mod_op, .and_op])
        }
    }
    
    // Factor -> not_op Factor | Const | ident VarChain | openbracket_sym Expr closebracket_sym .
    private func Factor() throws -> (expr: Expr, coord: Fragment) {
        if currentTerm == .not_op {
            let coord = currentToken.coord
            updateCurrent()
            
            let (expr, exprCoord) = try Factor()
            return (UnOpExpr(op: .not, opCoord: coord, expr: expr), .init(start: coord.start, end: exprCoord.end))
            
        } else if currentTerm == .ident, let variable = currentToken.value as? String {
            let start = currentToken.coord.start
            updateCurrent()
            let varChain = try VarChain()
            
            return (VariableExpr(varName: .init(variables: [variable].withAppending(varChain.variables),
                                               coord: .init(start: start, end: varChain.coord.end))),
                    .init(start: start, end: varChain.coord.end))
            
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
    private func Const() throws -> (expr: Expr, coord: Fragment) {
        let coord = currentToken.coord
        
        switch currentTerm {
            
        case .integer_const:
            let value = currentToken.value
            updateCurrent()
            
            return (ConstExpr(value: value, type: .integer), coord)
            
        case .real_const:
            let value = currentToken.value
            updateCurrent()
            
            return (ConstExpr(value: value, type: .real), coord)
            
        case .boolean_const:
            let value = currentToken.value
            updateCurrent()
            
            return (ConstExpr(value: value, type: .boolean), coord)
            
        default: throw error(expected: [.integer_const, .real_const, .boolean_const])
        }
    }
}
