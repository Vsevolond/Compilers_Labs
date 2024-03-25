import Foundation

extension String {
    
    static let empty: String = ""
    
    static func syntaxError(pos: Position) -> String { "syntax error \(pos.stringValue)" }
    
    var isKeyword: Bool { Constants.keywords.contains(self) }
    
    var isIdent: Bool {
        guard !isEmpty else { return false }
        
        let satisfies: [Int] = map { $0.isLetter ? 1 : ($0.isNumber ? 0 : -1) }
        guard satisfies[0] != -1 else {
            return false
        }
        
        for i in 1..<count {
            guard satisfies[i] != -1, satisfies[i] != satisfies[i - 1] else {
                return false
            }
        }
        
        return true
    }
}

extension Character {
    
    static let empty: Character = Character(UnicodeScalar(0))
    
    var isWhiteSpaceOrNewLine: Bool {
        isWhitespace || isNewline
    }
}

private enum Constants {
    
    static let keywords: [String] = ["for", "if", "m1"]
}
