import Foundation

class Scanner {
    
    private let handle: FileHandle
    
    private var currentChar: Character = .empty
    private var currentPos: Position = .init(line: 1, col: 0)
    
    init(fileName: String) throws {
        guard let fileHandle = FileHandle(forReadingAtPath: fileName) else {
            throw CompilerError.cannotOpenFile
        }
        
        self.handle = fileHandle
    }
    
    func nextToken() -> Token {
        updateCurrent()
        
        switch currentChar {
            
        case "*": return .init(tag: .star, value: "*", coord: .init(pos: currentPos))
        case "+": return .init(tag: .plus, value: "+", coord: .init(pos: currentPos))
        case "'": return .init(tag: .mark, value: "'", coord: .init(pos: currentPos))
        case "(": return .init(tag: .openBracket, value: "(", coord: .init(pos: currentPos))
        case ")": return .init(tag: .closeBracket, value: ")", coord: .init(pos: currentPos))
        case "\"": return .init(tag: .quote, value: "\"", coord: .init(pos: currentPos))
        default:
            if currentChar.isLetter, currentChar.isUppercase {
                return .init(tag: .ident, value: currentChar, coord: .init(pos: currentPos))
                
            } else if currentChar.isLetter, currentChar.isLowercase {
                return .init(tag: .char, value: currentChar, coord: .init(pos: currentPos))
                
            } else if currentChar == .empty {
                return .init(tag: .endOfGrammar, value: currentChar, coord: .init(pos: currentPos))
                
            } else if currentChar.isWhiteSpaceOrNewLine {
                return nextToken()
                
            } else {
                return .init(tag: .unrecognized, value: currentChar, coord: .init(pos: currentPos))
            }
        }
    }
    
    func end() {
        handle.closeFile()
    }
    
    private func updateCurrent() {
        currentChar.isNewline ? currentPos+++ : currentPos++
        currentChar = nextChar()
    }
    
    private func nextChar() -> Character {
        guard let code = handle.readData(ofLength: 1).first else {
            return .empty
        }
        
        let char = Character(UnicodeScalar(code))
        return char
    }
}
