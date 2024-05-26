import Foundation

enum KeywordType: String, CaseIterable {
    
    case type_kw    = "TYPE"
    case record_kw  = "RECORD"
    case end_kw     = "END"
    case var_kw     = "VAR"
    case begin_kw   = "BEGIN"
    case new_kw     = "NEW"
    case while_kw   = "WHILE"
    case do_kw      = "DO"
    case if_kw      = "IF"
    case then_kw    = "THEN"
    case else_kw    = "ELSE"
    case pointer_kw = "POINTER"
    case to_kw      = "TO"
}

enum AssignmentOperationType: String {
    
    case typeAssignment_op = "="
    case varAssignment_op = ":="
}

enum PointerOperationType: String {
    
    case dereference_op = "^"
}

enum ArithmeticOperationType: String, CaseIterable {
    
    case div_op            = "DIV"
    case mod_op            = "MOD"
    case and_op            = "AND"
    case not_op            = "NOT"
    case or_op             = "OR"
    case addition_op       = "+"
    case substraction_op   = "-"
    case multiplication_op = "*"
    case division_op       = "/"
}

enum CompareOperationType: String {
    
    case equal_op          = "=="
    case less_op           = "<"
    case lessOrEqual_op    = "<="
    case greater_op        = ">"
    case greaterOrEqual_op = ">="
    case notEqual_op       = "#"
}

enum OperationType: Equatable {
    
    case assignment(_ operation: AssignmentOperationType)
    case pointer(_ operation: PointerOperationType)
    case arithmetic(_ operation: ArithmeticOperationType)
    case compare(_ operation: CompareOperationType)
}

enum SymbolType: String {
    
    case dot_sym = "."
    case comma_sym        = ","
    case colon_sym        = ":"
    case semicolon_sym    = ";"
    case openBracket_sym  = "("
    case closeBracket_sym = ")"
}

enum GlobalType: String, CaseIterable {
    
    case integer_type = "INTEGER"
    case real_type    = "REAL"
    case boolean_type = "BOOLEAN"
}

enum VariableType: Equatable {
    
    case global(_ type: GlobalType)
    case local_type
}

enum ConstType: String {
    
    case integer_const
    case real_const
    case boolean_const
}

enum DomainTag: Equatable {
    
    case ident
    case keyword(_ type: KeywordType)
    case operation(_ type: OperationType)
    case symbol(_ type: SymbolType)
    case typeDeclare(_ type: VariableType)
    case const(_ type: ConstType)
    
    case comment
    case unrecognized
    case endOfInput
    
    var value: String {
        switch self {
        case .ident: "ident"
        case .keyword(let keyword): keyword.rawValue
        case .symbol(let symbol): symbol.rawValue
        case .const(let const): const.rawValue
        case .comment: "comment"
        case .unrecognized: "unrecognized"
        case .endOfInput: "endOfInput"
            
        case .typeDeclare(let type):
            switch type {
            case .global(let globalType): globalType.rawValue
            case .local_type: "local_type"
            }
            
        case .operation(let operation):
            switch operation {
            case .assignment(let assignmentType): assignmentType.rawValue
            case .pointer(let pointerType): pointerType.rawValue
            case .arithmetic(let arithmeticType): arithmeticType.rawValue
            case .compare(let compareType): compareType.rawValue
            }
        }
    }
}
