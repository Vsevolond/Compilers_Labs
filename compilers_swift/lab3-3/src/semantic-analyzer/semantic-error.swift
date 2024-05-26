import Foundation

protocol SemanticError: Error {
    
    var coord: Fragment { get }
    var message: String { get }
}

class UnknownVarError: SemanticError {
    
    let varName: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Необъявленная переменная \(varName)"
    }
    
    init(varName: String, coord: Fragment) {
        self.varName = varName
        self.coord = coord
    }
}

class UnknownTypeError: SemanticError {
    
    let typeName: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Необъявленный тип данных \(typeName)"
    }
    
    init(typeName: String, coord: Fragment) {
        self.typeName = typeName
        self.coord = coord
    }
}

class ImpossibleOperationError: SemanticError {
    
    let op: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Невозможно применить операцию \(op)"
    }
    
    init(op: String, coord: Fragment) {
        self.op = op
        self.coord = coord
    }
}

class NotBoolConditionError: SemanticError {
    
    let type: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Условие имеет тип \(type) вместо логического"
    }
    
    init(type: String, coord: Fragment) {
        self.type = type
        self.coord = coord
    }
}

class ImpossibleInheritanceError: SemanticError {
    
    let parent: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Невозможно наследоваться от типа \(parent)"
    }
    
    init(parent: String, coord: Fragment) {
        self.parent = parent
        self.coord = coord
    }
}

class NonExistentPropertyError: SemanticError {
    
    let property: String
    let type: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): Тип \(type) не содержит свойства \(property)"
    }
    
    init(property: String, type: String, coord: Fragment) {
        self.property = property
        self.type = type
        self.coord = coord
    }
}

class NotPointerError: SemanticError {
    
    let variable: String
    let coord: Fragment
    
    var message: String {
        "\(coord.stringValue): \(variable) не является указателем"
    }
    
    init(variable: String, coord: Fragment) {
        self.variable = variable
        self.coord = coord
    }
}
