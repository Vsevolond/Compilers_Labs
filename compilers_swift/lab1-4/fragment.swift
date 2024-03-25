import Foundation

struct Fragment {
    
    private let start: Position
    private let end: Position
    
    var stringValue: String { "\(start.stringValue)-\(end.stringValue)" }
    
    init(start: Position, end: Position) {
        self.start = start
        self.end = end
    }
    
    init(pos: Position) {
        self.init(start: pos, end: pos)
    }
}
