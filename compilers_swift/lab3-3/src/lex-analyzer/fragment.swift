import Foundation

struct Fragment {
    
    let start: Position
    let end: Position
    
    var stringValue: String { "\(start.stringValue) - \(end.stringValue)"}
    
    init(start: Position, end: Position) {
        self.start = start
        self.end = end
    }
    
    init(pos: Position) {
        self.init(start: pos, end: pos)
    }
    
    static func + (lhs: Fragment, rhs: Int) -> Fragment {
        .init(start: lhs.start, end: lhs.end + rhs)
    }
    
    static let zero: Fragment = .init(pos: .zero)
}
