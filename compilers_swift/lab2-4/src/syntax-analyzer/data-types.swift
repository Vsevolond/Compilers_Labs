import Foundation

enum TypeKind {
    
    case global, local
}

class SomeType {
    
    let kind: TypeKind
    let name: String
    
    init(kind: TypeKind, name: String) {
        self.kind = kind
        self.name = name
    }
}

class VarType {
    
    let type: SomeType
    let isPointer: Bool
    
    init(type: SomeType, isPointer: Bool) {
        self.type = type
        self.isPointer = isPointer
    }
}

class VarDef {
    
    let name: String
    let type: VarType
    
    init(name: String, type: VarType) {
        self.name = name
        self.type = type
    }
}

class TypeDef {
    
    let name: String
    let parentType: SomeType?
    let varDefs: [VarDef]
    
    init(name: String, parentType: SomeType? = nil, varDefs: [VarDef]) {
        self.name = name
        self.parentType = parentType
        self.varDefs = varDefs
    }
}

class Statement {}

class Program {
    
    let typeDefs: [TypeDef]
    let varDefs: [VarDef]
    let statements: [Statement]
    
    init(typeDefs: [TypeDef], varDefs: [VarDef], statements: [Statement]) {
        self.typeDefs = typeDefs
        self.varDefs = varDefs
        self.statements = statements
    }
}

class Expr {}

class VarChain {
    
    let variables: [String]
    
    init(variables: [String]) {
        self.variables = variables
    }
}

class AssignStatement: Statement {
    
    let variable: VarChain
    let expr: Expr
    let isDereference: Bool
    
    init(variable: VarChain, expr: Expr, isDereference: Bool) {
        self.variable = variable
        self.expr = expr
        self.isDereference = isDereference
    }
}

class CreateStatement: Statement {
    
    let pointerName: VarChain
    
    init(pointerName: VarChain) {
        self.pointerName = pointerName
    }
}

class IfStatement: Statement {
    
    let condition: Expr
    let thenBranch: [Statement]
    let elseBranch: [Statement]
    
    init(condition: Expr, thenBranch: [Statement], elseBranch: [Statement]) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
    }
}

class WhileStatement: Statement {
    
    let condition: Expr
    let body: [Statement]
    
    init(condition: Expr, body: [Statement]) {
        self.condition = condition
        self.body = body
    }
}

class VariableExpr: Expr {
    
    let varName: VarChain
    
    init(varName: VarChain) {
        self.varName = varName
    }
}

class ConstExpr: Expr {
    
    let value: Any
    let type: SomeType
    
    init(value: Any, type: SomeType) {
        self.value = value
        self.type = type
    }
}

class BinOpExpr: Expr {
    
    let left: Expr
    let op: String
    let right: Expr
    
    init(left: Expr, op: String, right: Expr) {
        self.left = left
        self.op = op
        self.right = right
    }
}

class UnOpExpr: Expr {
    
    let op: String
    let expr: Expr
    
    init(op: String, expr: Expr) {
        self.op = op
        self.expr = expr
    }
}
