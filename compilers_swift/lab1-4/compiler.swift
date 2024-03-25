import Foundation

enum CompilerError: Error {
    
    case cannotOpenFile
    case cannotReadFile
}

class Compiler {
    
    private let scanner: Scanner
    private var messages: [String]
    private var tokens: [Token]
    
    init(fileName: String, fsm: FSM) throws {
        scanner = try Scanner(fileName: fileName, fsm: fsm)
        messages = []
        tokens = []
        
        scanner.compiler = self
    }
    
    func compile() {
        var token = scanner.nextToken()
        
        while !token.isEnd {
            guard !token.isUnrecognized else {
                token = scanner.nextToken()
                continue
            }
            
            tokens.append(token)
            addMessage(token.stringValue)
            
            token = scanner.nextToken()
        }
        
        scanner.end()
    }
    
    func printMessages() {
        messages.forEach { message in
            print(message)
        }
    }
}

extension Compiler: ScannerDelegate {
    
    func addMessage(_ message: String) {
        messages.append(message)
    }
}
