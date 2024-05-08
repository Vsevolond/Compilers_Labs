import Foundation

class Scanner {
    
    private let handle: FileHandle
    
    private var currentChar: Character = .empty
    private var currentPos: Position = .init(line: 1, col: 0)
    
    private var needToUpdate: Bool = true
    
    init(fileName: String) throws {
        guard let fileHandle = FileHandle(forReadingAtPath: fileName) else {
            throw CompilerError.cannotOpenFile
        }
        
        self.handle = fileHandle
    }
    
    func nextToken() throws -> Token {
        if needToUpdate { updateCurrent() } else { needToUpdate = true }
        skipEmpty()
        
        switch currentChar {
            
        case "*": return .init(tag: .star, value: "*", coord: .init(pos: currentPos))
        case "(": return .init(tag: .openBracket, value: "(", coord: .init(pos: currentPos))
        case ")": return .init(tag: .closeBracket, value: ")", coord: .init(pos: currentPos))
            
        default:
            
            if currentChar == "\"" {
                let startPos = currentPos
                var char = ""
                
                updateCurrent()
                
                while currentChar != .empty, currentChar != "\"" {
                    char.append(currentChar)
                    updateCurrent()
                }
                
                guard currentChar != .empty else {
                    throw CompilerError.unexpected(coord: .init(start: startPos, end: currentPos))
                }
                
                return .init(tag: .char, value: char, coord: .init(start: startPos, end: currentPos))
                
            } else if currentChar.isLetter, currentChar.isUppercase {
                let startPos = currentPos
                var ident = ""
                
                while currentChar != .empty, currentChar.isLetter {
                    ident.append(currentChar)
                    updateCurrent()
                }
                
                needToUpdate = false
                
                guard currentChar != .empty else {
                    return .init(tag: .ident, value: ident, coord: .init(start: startPos, end: currentPos))
                }
                
                if currentChar == "'" {
                    ident.append(currentChar)
                    updateCurrent()
                    
                    return .init(tag: .ident, value: ident, coord: .init(start: startPos, end: currentPos))
                    
                } else {
                    return .init(tag: .ident, value: ident, coord: .init(start: startPos, end: currentPos))
                }
                
            } else if currentChar == .empty {
                return .init(tag: .endOfInput, value: "\(currentChar)", coord: .init(pos: currentPos))
                
            } else {
                throw CompilerError.unexpected(coord: .init(pos: currentPos))
            }
        }
    }
    
    func end() {
        handle.closeFile()
    }
    
    private func skipEmpty() {
        while currentChar != .empty, currentChar.isWhiteSpaceOrNewLine {
            updateCurrent()
        }
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
