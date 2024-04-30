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
        
        if currentChar.isSymbol || currentChar.isPunctuation {
            switch currentChar {
                
            case ".": return .init(tag: .symbol(.dot_sym), value: currentChar, coord: .init(pos: currentPos))
            case ",": return .init(tag: .symbol(.comma_sym), value: currentChar, coord: .init(pos: currentPos))
            case ";": return .init(tag: .symbol(.semicolon_sym), value: currentChar, coord: .init(pos: currentPos))
            case ")": return .init(tag: .symbol(.closeBracket_sym), value: currentChar, coord: .init(pos: currentPos))
            case "^": return .init(tag: .operation(.pointer(.dereference_op)), value: currentChar, coord: .init(pos: currentPos))
            case "#": return .init(tag: .operation(.compare(.notEqual_op)), value: currentChar, coord: .init(pos: currentPos))
            case "+": return .init(tag: .operation(.arithmetic(.addition_op)), value: currentChar, coord: .init(pos: currentPos))
            case "-": return .init(tag: .operation(.arithmetic(.substraction_op)), value: currentChar, coord: .init(pos: currentPos))
            case "*": return .init(tag: .operation(.arithmetic(.multiplication_op)), value: currentChar, coord: .init(pos: currentPos))
            case "/": return .init(tag: .operation(.arithmetic(.division_op)), value: currentChar, coord: .init(pos: currentPos))
                
            case "=":
                let startSym = currentChar
                let startPos = currentPos
                
                updateCurrent()
                
                if currentChar == "=" {
                    let sym = "\(startSym)\(currentChar)"
                    return .init(tag: .operation(.compare(.equal_op)), value: sym, coord: .init(start: startPos, end: currentPos))
                    
                } else {
                    needToUpdate = false
                    return .init(tag: .operation(.assignment(.typeAssignment_op)), value: startSym, coord: .init(pos: startPos))
                }
                
            case ":":
                let startSym = currentChar
                let startPos = currentPos
                
                updateCurrent()
                
                if currentChar == "=" {
                    let sym = "\(startSym)\(currentChar)"
                    return .init(tag: .operation(.assignment(.varAssignment_op)), value: sym, coord: .init(start: startPos, end: currentPos))
                    
                } else {
                    needToUpdate = false
                    return .init(tag: .symbol(.colon_sym), value: startSym, coord: .init(pos: startPos))
                }
                
            case "(":
                let startSym = currentChar
                let startPos = currentPos
                
                updateCurrent()
                
                if currentChar == "*" {
                    updateCurrent()
                    var comment = ""
                    
                    while currentChar != "*", currentChar != .empty {
                        comment.append(currentChar)
                        updateCurrent()
                    }
                    
                    guard currentChar != .empty else {
                        throw CompilerError.unexpected(coord: .init(pos: currentPos))
                    }
                    
                    updateCurrent()
                    guard currentChar == ")" else {
                        throw CompilerError.unexpected(coord: .init(pos: currentPos))
                    }
                    
                    return .init(tag: .comment, value: comment, coord: .init(start: startPos, end: currentPos))
                    
                } else {
                    needToUpdate = false
                    return .init(tag: .symbol(.openBracket_sym), value: startSym, coord: .init(pos: startPos))
                }
                
            case "<", ">":
                let startSym = currentChar
                let startPos = currentPos
                
                updateCurrent()
                
                if currentChar == "=" {
                    let sym = "\(startSym)\(currentChar)"
                    
                    if sym == "<=" {
                        return .init(tag: .operation(.compare(.lessOrEqual_op)), value: sym, coord: .init(start: startPos, end: currentPos))
                        
                    } else {
                        return .init(tag: .operation(.compare(.greaterOrEqual_op)), value: sym, coord: .init(start: startPos, end: currentPos))
                    }
                    
                } else {
                    needToUpdate = false
                    
                    if startSym == "<" {
                        return .init(tag: .operation(.compare(.less_op)), value: startSym, coord: .init(pos: startPos))
                        
                    } else {
                        return .init(tag: .operation(.compare(.greater_op)), value: startSym, coord: .init(pos: startPos))
                    }
                }
                
            default:
                return .init(tag: .unrecognized, value: currentChar, coord: .init(pos: currentPos))
            }
            
        } else if currentChar.isNumber {
            var numberString = ""
            let startPos = currentPos
            
            while currentChar.isNumber, currentChar != .empty {
                numberString.append(currentChar)
                updateCurrent()
            }
            
            if currentChar == "." {
                numberString.append(currentChar)
                updateCurrent()
                
                guard currentChar.isNumber else {
                    throw CompilerError.unexpected(coord: .init(pos: currentPos))
                }
                
                while currentChar.isNumber, currentChar != .empty {
                    numberString.append(currentChar)
                    updateCurrent()
                }
                
                needToUpdate = false
                guard let number = Float(numberString) else { fatalError("can't convert string to number") }
                
                return .init(tag: .const(.real_const), value: number, coord: .init(start: startPos, end: currentPos))
                
            } else {
                needToUpdate = false
                guard let number = Int(numberString) else { fatalError("can't convert string to number") }
                
                return .init(tag: .const(.integer_const), value: number, coord: .init(start: startPos, end: currentPos))
            }
            
        } else if currentChar.isLetter {
            var nameString = ""
            let startPos = currentPos
            
            while currentChar.isLetter || currentChar.isNumber, currentChar != .empty {
                nameString.append(currentChar)
                updateCurrent()
            }
            
            needToUpdate = false
            
            if nameString.isKeyword {
                guard let keywordType = KeywordType.allCases.first(where: { $0.rawValue == nameString }) else {
                    throw CompilerError.unexpected(coord: .init(start: startPos, end: currentPos))
                }
                
                return .init(tag: .keyword(keywordType), value: nameString, coord: .init(start: startPos, end: currentPos))
                
            } else if nameString.isArithmOp {
                guard let operationType = ArithmeticOperationType.allCases.first(where: { $0.rawValue == nameString }) else {
                    throw CompilerError.unexpected(coord: .init(start: startPos, end: currentPos))
                }
                
                return .init(tag: .operation(.arithmetic(operationType)), value: nameString, coord: .init(start: startPos, end: currentPos))
                
            } else if nameString.isGlobalType {
                guard let type = GlobalType.allCases.first(where: { $0.rawValue == nameString }) else {
                    throw CompilerError.unexpected(coord: .init(start: startPos, end: currentPos))
                }
                
                return .init(tag: .typeDeclare(.global(type)), value: nameString, coord: .init(start: startPos, end: currentPos))
                
            } else if nameString.isBoolean {
                if nameString == "TRUE" {
                    return .init(tag: .const(.boolean_const), value: true, coord: .init(start: startPos, end: currentPos))
                    
                } else {
                    return .init(tag: .const(.boolean_const), value: false, coord: .init(start: startPos, end: currentPos))
                }
                
            } else if nameString.isIdent {
                return .init(tag: .ident, value: nameString, coord: .init(start: startPos, end: currentPos))
                
            } else if nameString.isLocalType {
                return .init(tag: .typeDeclare(.local_type), value: nameString, coord: .init(start: startPos, end: currentPos))
                
            } else {
                throw CompilerError.unexpected(coord: .init(start: startPos, end: currentPos))
            }
            
        } else {
            if currentChar == .empty {
                return .init(tag: .endOfInput, value: currentChar, coord: .init(pos: currentPos))
                
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
