import Foundation

enum TypeKind: String {
    
    case integer = "INTEGER"
    case real    = "REAL"
    case boolean = "BOOLEAN"
    case local   = "LOCAL"
}

enum OperationKind: String {
    
    case addition       = "+"
    case substraction   = "-"
    case multiplication = "*"
    case division       = "/"
    case mod            = "MOD"
    case div            = "DIV"
    
    case less           = "<"
    case greater        = ">"
    case lessOrEqual    = "<="
    case greaterOrEqual = ">="
    case equal          = "=="
    case notEqual       = "#"
    case or             = "OR"
    case and            = "AND"
    
    case not            = "NOT"
    
    var isBoolean: Bool {
        switch self {
        case .less, .lessOrEqual, .greater, .greaterOrEqual, .equal, .notEqual, .or, .and, .not: true
        default: false
        }
    }
    
    var isArithmetic: Bool { !isBoolean }
}

class SomeType {
    
    let kind: TypeKind
    let name: String
    let coord: Fragment
    
    init(kind: TypeKind, name: String, coord: Fragment) {
        self.kind = kind
        self.name = name
        self.coord = coord
    }
    
    func isSimilar(with anotherType: SomeType, localTypes: [String: TypeDef]) -> Bool {
        if let parent1 = localTypes[name]?.parentType, let parent2 = localTypes[anotherType.name]?.parentType {
            return parent1.name == anotherType.name || parent2.name == name || parent1.name == parent2.name
            
        } else if let parent1 = localTypes[name]?.parentType {
            return parent1.name == anotherType.name
            
        } else if let parent2 = localTypes[anotherType.name]?.parentType {
            return parent2.name == name
            
        } else {
            return name == anotherType.name || (kind == .real && anotherType.kind == .integer)
        }
    }
    
    func isConforming(anotherType: SomeType, localTypes: [String: TypeDef]) -> Bool {
        guard name != anotherType.name else { return true }
        
        guard let parent = localTypes[name]?.parentType else {
            return false
        }
        
        return parent.name == anotherType.name
    }
}

class VarType {
    
    let type: SomeType
    let isPointer: Bool
    
    var coord: Fragment { type.coord }
    
    init(type: SomeType, isPointer: Bool) {
        self.type = type
        self.isPointer = isPointer
    }
}

class VarDef {
    
    let name: String
    let varType: VarType
    
    init(name: String, varType: VarType) {
        self.name = name
        self.varType = varType
    }
    
    func check(localTypes: [String: TypeDef]) throws {
        if varType.type.kind == .local, localTypes[varType.type.name] == nil {
            
            throw UnknownTypeError(typeName: varType.type.name, coord: varType.coord)
        }
    }
}

class TypeDef {
    
    let name: String
    let parentType: SomeType?
    let varDefs: [VarDef]
    
    private var varTypes: [String: VarType] {
        varDefs.reduce(into: [String: VarType]()) { $0[$1.name] = $1.varType }
    }
    
    init(name: String, parentType: SomeType? = nil, varDefs: [VarDef]) {
        self.name = name
        self.parentType = parentType
        self.varDefs = varDefs
    }
    
    func check(localTypes: [String: TypeDef]) throws {
        if let parentType {
            if parentType.kind != .local {
                throw ImpossibleInheritanceError(parent: parentType.name, coord: parentType.coord)
                
            } else if localTypes[parentType.name] == nil {
                throw UnknownTypeError(typeName: parentType.name, coord: parentType.coord)
            }
        }
        
        try varDefs.forEach{ try $0.check(localTypes: localTypes) }
    }
    
    func getTypeOf(varname: String, localTypes: [String: TypeDef]) -> VarType? {
        guard let parentType, let parent = localTypes[parentType.name] else {
            return varTypes[varname]
        }
        
        return varTypes[varname] ?? parent.getTypeOf(varname: varname, localTypes: localTypes)
    }
}

protocol Statement {
    
    func check(localVars: [String: VarType], localTypes: [String: TypeDef]) throws
}

class Program {
    
    let typeDefs: [TypeDef]
    let varDefs: [VarDef]
    let statements: [Statement]
    
    init(typeDefs: [TypeDef], varDefs: [VarDef], statements: [Statement]) {
        self.typeDefs = typeDefs
        self.varDefs = varDefs
        self.statements = statements
    }
    
    func check() throws {
        var localTypes = [String: TypeDef]()
        var localVars = [String: VarType]()
        
        for typeDef in typeDefs {
            localTypes[typeDef.name] = typeDef
        }
        
        for varDef in varDefs {
            localVars[varDef.name] = varDef.varType
        }
        
        try typeDefs.forEach { try $0.check(localTypes: localTypes) }
        try varDefs.forEach { try $0.check(localTypes: localTypes) }
        try statements.forEach { try $0.check(localVars: localVars, localTypes: localTypes) }
    }
}

protocol Expr {
    
    func checkType(localVars: [String: VarType], localTypes: [String: TypeDef]) throws -> VarType
}

class VarChain {
    
    let variables: [String]
    let coord: Fragment
    
    var stringValue: String { variables.joined(separator: ".") }
    
    init(variables: [String], coord: Fragment) {
        self.variables = variables
        self.coord = coord
    }
    
    func checkType(localVars: [String: VarType], localTypes: [String: TypeDef]) throws -> VarType {
        var variable = variables[0]
        
        guard var varType = localVars[variable] else {
            throw UnknownVarError(varName: variable, coord: .init(start: coord.start, end: coord.start + variable.count))
        }
        
        for i in 1..<variables.count {
            variable = variables[i]
            
            guard varType.type.kind == .local, let type = localTypes[varType.type.name]?.getTypeOf(varname: variable, localTypes: localTypes) else {
                let start = coord.start + variables[i - 1].count + 1
                let end = coord.start + variables[i - 1].count + 1 + variable.count
                
                throw NonExistentPropertyError(property: variable, type: varType.type.name, coord: .init(start: start, end: end))
            }
            
            varType = type
        }
        
        return varType
    }
}

class AssignStatement: Statement {
    
    let variable: VarChain
    let expr: Expr
    let isDereference: Bool
    let assignCoord: Fragment
    let derefCoord: Fragment
    
    init(variable: VarChain, expr: Expr, isDereference: Bool, assignCoord: Fragment, derefCoord: Fragment) {
        self.variable = variable
        self.expr = expr
        self.isDereference = isDereference
        self.assignCoord = assignCoord
        self.derefCoord = derefCoord
    }
    
    func check(localVars: [String : VarType], localTypes: [String : TypeDef]) throws {
        let variableType = try variable.checkType(localVars: localVars, localTypes: localTypes)
        let exprType = try expr.checkType(localVars: localVars, localTypes: localTypes)
        
        if isDereference {
            if !variableType.isPointer {
                throw ImpossibleOperationError(op: "^", coord: derefCoord)
                
            } else if exprType.isPointer || !variableType.type.isSimilar(with: exprType.type, localTypes: localTypes) {
                throw ImpossibleOperationError(op: ":=", coord: assignCoord)
            }
            
        } else {
            if variableType.isPointer, exprType.isPointer, !exprType.type.isConforming(anotherType: variableType.type, localTypes: localTypes) {
                throw ImpossibleOperationError(op: ":=", coord: assignCoord)
                
            } else if !variableType.isPointer, !exprType.isPointer, !variableType.type.isSimilar(with: exprType.type, localTypes: localTypes) {
                throw ImpossibleOperationError(op: ":=", coord: assignCoord)
            }
        }
    }
}

class CreateStatement: Statement {
    
    let pointerName: VarChain
    
    init(pointerName: VarChain) {
        self.pointerName = pointerName
    }
    
    func check(localVars: [String : VarType], localTypes: [String : TypeDef]) throws {
        let type = try pointerName.checkType(localVars: localVars, localTypes: localTypes)
        guard type.isPointer else {
            throw NotPointerError(variable: pointerName.stringValue, coord: pointerName.coord)
        }
    }
}

class IfStatement: Statement {
    
    let condition: Expr
    let conditionCoord: Fragment
    let thenBranch: [Statement]
    let elseBranch: [Statement]
    
    init(condition: Expr, conditionCoord: Fragment, thenBranch: [Statement], elseBranch: [Statement]) {
        self.condition = condition
        self.conditionCoord = conditionCoord
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
    }
    
    func check(localVars: [String : VarType], localTypes: [String : TypeDef]) throws {
        let conditionType = try condition.checkType(localVars: localVars, localTypes: localTypes)
        
        guard !conditionType.isPointer, conditionType.type.kind == .boolean else {
            throw NotBoolConditionError(type: conditionType.type.name, coord: conditionCoord)
        }
        
        try thenBranch.forEach { try $0.check(localVars: localVars, localTypes: localTypes) }
        try elseBranch.forEach { try $0.check(localVars: localVars, localTypes: localTypes) }
    }
}

class WhileStatement: Statement {
    
    let condition: Expr
    let conditionCoord: Fragment
    let body: [Statement]
    
    init(condition: Expr, conditionCoord: Fragment, body: [Statement]) {
        self.condition = condition
        self.conditionCoord = conditionCoord
        self.body = body
    }
    
    func check(localVars: [String : VarType], localTypes: [String : TypeDef]) throws {
        let conditionType = try condition.checkType(localVars: localVars, localTypes: localTypes)
        
        guard !conditionType.isPointer, conditionType.type.kind == .boolean else {
            throw NotBoolConditionError(type: conditionType.type.name, coord: conditionCoord)
        }
        
        try body.forEach { try $0.check(localVars: localVars, localTypes: localTypes) }
    }
}

class VariableExpr: Expr {
    
    let varName: VarChain
    
    init(varName: VarChain) {
        self.varName = varName
    }
    
    func checkType(localVars: [String : VarType], localTypes: [String : TypeDef]) throws -> VarType {
        try varName.checkType(localVars: localVars, localTypes: localTypes)
    }
}

class ConstExpr: Expr {
    
    let value: Any
    let type: TypeKind
    
    init(value: Any, type: TypeKind) {
        self.value = value
        self.type = type
    }
    
    func checkType(localVars: [String : VarType], localTypes: [String : TypeDef]) throws -> VarType {
        .init(type: .init(kind: type, name: type.rawValue, coord: .zero), isPointer: false)
    }
}

class BinOpExpr: Expr {
    
    let left: Expr
    let right: Expr
    let op: OperationKind
    let opCoord: Fragment
    
    init(left: Expr, right: Expr, op: OperationKind, opCoord: Fragment) {
        self.left = left
        self.right = right
        self.op = op
        self.opCoord = opCoord
    }
    
    func checkType(localVars: [String : VarType], localTypes: [String : TypeDef]) throws -> VarType {
        let leftType = try left.checkType(localVars: localVars, localTypes: localTypes)
        let rightType = try right.checkType(localVars: localVars, localTypes: localTypes)
        
        guard !leftType.isPointer, !rightType.isPointer, leftType.type.kind != .local, rightType.type.kind != .local,
              (leftType.type.kind == rightType.type.kind || (leftType.type.kind == .integer && rightType.type.kind == .real) || (leftType.type.kind == .real && rightType.type.kind == .integer)) else
        {
            throw ImpossibleOperationError(op: op.rawValue, coord: opCoord)
        }
        
        if op.isBoolean {
            return .init(type: .init(kind: .boolean, name: TypeKind.boolean.rawValue, coord: opCoord), isPointer: false)
            
        } else {
            return .init(type: .init(kind: leftType.type.kind, name: leftType.type.name, coord: opCoord), isPointer: false)
        }
    }
}

class UnOpExpr: Expr {
    
    let op: OperationKind
    let opCoord: Fragment
    let expr: Expr
    
    init(op: OperationKind, opCoord: Fragment, expr: Expr) {
        self.op = op
        self.opCoord = opCoord
        self.expr = expr
    }
    
    func checkType(localVars: [String : VarType], localTypes: [String : TypeDef]) throws -> VarType {
        let exprType = try expr.checkType(localVars: localVars, localTypes: localTypes)
        
        guard !exprType.isPointer else {
            throw ImpossibleOperationError(op: op.rawValue, coord: opCoord)
        }
        
        guard (op.isBoolean && exprType.type.kind == .boolean) ||
              (op.isArithmetic && (exprType.type.kind == .integer || exprType.type.kind == .real)) else
        {
            throw ImpossibleOperationError(op: op.rawValue, coord: opCoord)
        }
        
        return .init(type: exprType.type, isPointer: false)
    }
}
