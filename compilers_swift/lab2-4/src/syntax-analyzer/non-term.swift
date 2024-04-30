import Foundation

infix operator =>: AssignmentPrecedence

final class NonTerm: GrammarElem {
    
    var disclosures: Set<[GrammarElem]> = .init()
    var parents: Set<NonTerm> = .init()
    
    override var isNonTerm: Bool { true }
    
    var firstSet: Set<GrammarElem> {
        disclosures.map { disclosure in
            Self.getFirstSet(of: disclosure)
            
        }.unionAll()
    }
    
    static func getFirstSet(of disclosure: [GrammarElem]) -> Set<GrammarElem> {
        guard let firstElem = disclosure.first else { return [.eps] }
        guard let nonTerm = firstElem as? NonTerm else { return [firstElem] }
        
        if nonTerm.firstSet.contains(.eps) {
            return nonTerm.firstSet.withRemoving(.eps)
                   .union(getFirstSet(of: disclosure.withRemovingFirst()))
            
        } else {
            return nonTerm.firstSet
        }
    }
    
    static func =>(lhs: inout NonTerm, rhs: [GrammarElem]) {
        lhs.disclosures.insert(rhs)
        for elem in rhs {
            guard elem.isNonTerm, let nonTerm = elem as? NonTerm else { continue }
            nonTerm.parents.insert(lhs)
        }
    }
    
    static func =>(lhs: inout NonTerm, rhs: [[GrammarElem]]) {
        rhs.forEach { elements in
            lhs.disclosures.insert(elements)
            for elem in elements {
                guard elem.isNonTerm, let nonTerm = elem as? NonTerm else { continue }
                nonTerm.parents.insert(lhs)
            }
        }
    }
}

extension NonTerm: ExpressibleByStringLiteral {

    convenience init(stringLiteral value: StringLiteralType) {
        self.init(id: value)
    }
}
