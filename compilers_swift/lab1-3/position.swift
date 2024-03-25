import Foundation

postfix operator +++ 

struct Position {
    
    private let line: Int
    private let pos: Int
    
    var stringValue: String { "(\(line), \(pos))"}
    
    init(line: Int, pos: Int) {
        self.line = line
        self.pos = pos
    }
    
    static postfix func ++(position: inout Position) {
        position = .init(line: position.line, pos: position.pos + 1)
    }
    
    static postfix func +++(position: inout Position) {
        position = .init(line: position.line + 1, pos: -1)
    }
}
