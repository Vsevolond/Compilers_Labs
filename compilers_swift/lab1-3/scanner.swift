import Foundation

protocol ScannerDelegate {
    
    func addMessage(_ message: String)
}

class Scanner {
    
    private let handle: FileHandle
    var compiler: ScannerDelegate?
    
    private var currentPos: Position = .init(line: 1, pos: 0)
    private var currentChar: Character = .empty
    
    init(fileName: String) throws {
        guard let fileHandle = FileHandle(forReadingAtPath: fileName) else {
            throw CompilerError.cannotOpenFile
        }
        
        self.handle = fileHandle
        updateCurrent()
    }
    
    func nextToken() -> Token {
        skipEmpty()
        
        switch currentChar {
            
        case "/":
            let start = currentPos
            updateCurrent()
            
            guard currentChar == "*" else {
                return error(text: .syntaxError(pos: currentPos), pos: currentPos)
            }
            
            updateCurrent()
            
            while currentChar != .empty, currentChar != "*" {
                updateCurrent()
            }
            
            guard currentChar == "*" else {
                return error(text: .syntaxError(pos: currentPos), pos: currentPos)
            }
            
            updateCurrent()
            
            guard currentChar == "/" else {
                return error(text: .syntaxError(pos: currentPos), pos: currentPos)
            }
            
            let end = currentPos
            updateCurrent()
            
            let token = Token(tag: .comment, coords: .init(start: start, end: end))
            return token
            
        default:
            if currentChar.isNumber || currentChar.isLetter {
                let start = currentPos
                var value: String = ""
                
                var end: Position = currentPos
                
                while currentChar != .empty && !currentChar.isWhiteSpaceOrNewLine && !value.isKeyword {
                    value.append(currentChar)
                    end = currentPos
                    updateCurrent()
                }
                
                if value.isKeyword {
                    let token = Token(tag: .keyword(value: value), coords: .init(start: start, end: end))
                    return token
                    
                } else if value.isIdent {
                    while currentChar != .empty, !currentChar.isWhiteSpaceOrNewLine, value.isIdent {
                        value.append(currentChar)
                        end = currentPos
                        updateCurrent()
                    }
                    
                    if value.isIdent {
                        let token = Token(tag: .ident(value: value), coords: .init(start: start, end: end))
                        return token
                        
                    } else {
                        skipSymbols()
                        return error(text: .syntaxError(pos: end), pos: end)
                    }
                    
                } else {
                    return error(text: .syntaxError(pos: end), pos: end)
                }
                
            } else if currentChar == .empty {
                return .init(tag: .endOfProgram, coords: .init(start: currentPos, end: currentPos))
                
            } else {
                return error(text: .syntaxError(pos: currentPos), pos: currentPos)
            }
        }
    }
    
    func end() {
        handle.closeFile()
    }
    
    private func error(text: String, pos: Position) -> Token {
        compiler?.addMessage(.syntaxError(pos: currentPos))
        updateCurrent()
        return .init(tag: .unrecognized, coords: .init(start: pos, end: pos))
    }
    
    private func updateCurrent() {
        currentChar.isNewline ? currentPos+++ : currentPos++
        currentChar = nextChar()
    }
    
    private func skipSymbols() {
        while currentChar != .empty, !currentChar.isWhiteSpaceOrNewLine {
            updateCurrent()
        }
    }
    
    private func skipEmpty() {
        while currentChar != .empty, currentChar.isWhiteSpaceOrNewLine {
            updateCurrent()
        }
    }
    
    private func nextChar() -> Character {
        guard let code = handle.readData(ofLength: 1).first else {
            return .empty
        }
        
        let char = Character(UnicodeScalar(code))
        return char
    }
}
