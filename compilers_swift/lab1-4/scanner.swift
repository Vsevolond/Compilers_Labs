import Foundation

protocol ScannerDelegate {
    
    func addMessage(_ message: String)
}

class Scanner {
    
    private let handle: FileHandle
    var compiler: ScannerDelegate?
    
    private var currentPos: Position = .init(line: 1, pos: 0)
    private var currentChar: Character = .empty
    
    private var fsm: FSM
    
    init(fileName: String, fsm: FSM) throws {
        guard let fileHandle = FileHandle(forReadingAtPath: fileName) else {
            throw CompilerError.cannotOpenFile
        }
        
        self.handle = fileHandle
        self.fsm = fsm
        updateCurrent()
    }
    
    func nextToken() -> Token {
        fsm.refresh()
        skipEmpty()
        
        guard currentChar != .empty else {
            return .init(tag: .endOfProgram, coords: .init(pos: currentPos))
        }
        
        let start = currentPos
        var value: String = ""
        
        guard var state = fsm.goto(by: currentChar) else {
            return error(in: currentPos)
        }
        value.append(currentChar)
        updateCurrent()
        
        while !state.isFinal {
            guard state.tag == .comment || (!currentChar.isWhiteSpaceOrNewLine && currentChar != .empty) else {
                break
            }
            
            guard let newState = fsm.goto(by: currentChar) else {
                if state.tag == .comment { break }
                else { return error(in: currentPos) }
            }
            value.append(currentChar)
            state = newState
            
            updateCurrent()
        }
        
        while state.isFinal {
            guard state.tag == .comment || (!currentChar.isWhiteSpaceOrNewLine && currentChar != .empty) else {
                break
            }
            
            guard let newState = fsm.goto(by: currentChar) else {
                if state.tag == .comment { break }
                else { return error(in: currentPos) }
            }
            value.append(currentChar)
            state = newState
            
            updateCurrent()
        }
        
        let end = currentPos
        
        let token: Token
        
        switch state.tag {
        case .ident:
            token = Token(tag: .ident(value: value), coords: .init(start: start, end: end))
        case .number:
            token = Token(tag: .number(value: value), coords: .init(start: start, end: end))
        case .keyword:
            token = Token(tag: .keyword(value: value), coords: .init(start: start, end: end))
        case .operation:
            token = Token(tag: .operation(value: value), coords: .init(start: start, end: end))
        case .comment:
            token = Token(tag: .comment, coords: .init(start: start, end: end))
        case .none, .start:
            return error(in: end)
        }
        
        return token
    }
    
    func end() {
        handle.closeFile()
    }
    
    private func error(in pos: Position) -> Token {
        compiler?.addMessage(.syntaxError(pos: currentPos))
        skipSymbols()
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
