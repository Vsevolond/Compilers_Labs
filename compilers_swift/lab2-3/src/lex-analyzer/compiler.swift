import Foundation

enum CompilerError: Error {
    
    case cannotOpenFile
    case cannotReadFile
    case unexpected(coord: Fragment)
}

class Compiler {
    
    private let scanner: Scanner
    
    var tokens: [Token]
    
    init(fileName: String) throws {
        scanner = try Scanner(fileName: fileName)
        tokens = []
    }
    
    func compile() throws {
        var token = try scanner.nextToken()
        
        while !token.isEnd {
            guard !token.isUnrecognized else {
                print("unrecognized token: \(token.value)")
                
                token = try scanner.nextToken()
                continue
            }
            
            tokens.append(token)
            
            token = try scanner.nextToken()
        }
        
        tokens.append(token)
        scanner.end()
    }
}
