import Foundation

let fileName = "/Users/vsevolond/UNIVERSITY/Compilers_Labs/compilers_swift/lab3-3/input.txt"

let compiler = try Compiler(fileName: fileName)

do {
    try compiler.compile()
    
    let parser = Parser(tokens: compiler.tokens)
    do {
        try parser.parse()
        print("Семантических ошибок не найдено")
        
    } catch {
        if let error = error as? ParserError {
            switch error {
                
            case .invalid(let expected, let given, let coord):
                print("expected: \(expected), but given: \"\(given)\" in coord: \(coord.stringValue)")
            }
            
        } else if let error = error as? SemanticError {
            print(error.message)
        }
    }
    
} catch {
    if let error = error as? CompilerError {
        switch error {
            
        case .cannotOpenFile:
            print("can't open file")
            
        case .cannotReadFile:
            print("can't read file")
            
        case .unexpected(let coord):
            print("unexpected token in: \(coord.stringValue)")
        }
    }
}
