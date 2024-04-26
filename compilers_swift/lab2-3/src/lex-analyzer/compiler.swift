import Foundation

enum CompilerError: Error {
    
    case cannotOpenFile
    case cannotReadFile
}

class Compiler {
    
    private let scanner: Scanner
    
    var tokens: [Token]
    
    init(fileName: String) throws {
        scanner = try Scanner(fileName: fileName)
        tokens = []
    }
    
    func compile() {
        var token = scanner.nextToken()
        
        while !token.isEnd {
            guard !token.isUnrecognized else {
                print("unrecognized token: \(token.value)")
                token = scanner.nextToken()
                continue
            }
            
            tokens.append(token)
            
            token = scanner.nextToken()
        }
        
        tokens.append(token)
        scanner.end()
    }
}
