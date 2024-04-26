import Foundation

postfix operator +++

struct Position {
    
    private let line: Int
    private let col: Int
    
    var stringValue: String { "(\(line), \(col))"}
    
    init(line: Int, col: Int) {
        self.line = line
        self.col = col
    }
    
    static postfix func ++(position: inout Position) {
        position = .init(line: position.line, col: position.col + 1)
    }
    
    static postfix func +++(position: inout Position) {
        position = .init(line: position.line + 1, col: 1)
    }
}
