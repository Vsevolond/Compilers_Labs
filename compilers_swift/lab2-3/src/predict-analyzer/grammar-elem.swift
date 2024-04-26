import Foundation

class GrammarElem: Hashable {
    
    let id: String
    
    var isNonTerm: Bool { false }
    var isTerm: Bool { false }
    var isEmpty: Bool { self == .eps }
    
    static let eps: GrammarElem = .init(id: "𝛆")
    
    init(id: String) {
        self.id = id
    }
    
    static func == (lhs: GrammarElem, rhs: GrammarElem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func | (lhs: GrammarElem, rhs: GrammarElem) -> [[GrammarElem]] {
        [[lhs], [rhs]]
    }
}

infix operator |: AdditionPrecedence

extension Array where Element == GrammarElem {
    
    static func | (lhs: [GrammarElem], rhs: [GrammarElem]) -> [[GrammarElem]] {
        [lhs, rhs]
    }
    
    static func | (lhs: [GrammarElem], rhs: GrammarElem) -> [[GrammarElem]] {
        [lhs, [rhs]]
    }
}

extension Array where Element == [GrammarElem] {
    
    static func | (lhs: [[GrammarElem]], rhs: GrammarElem) -> [[GrammarElem]] {
        var result: [[GrammarElem]] = lhs
        result.append([rhs])
        
        return result
    }
}
