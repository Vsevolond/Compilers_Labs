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
    
    var followSet: Set<GrammarElem> {
        guard !parents.isEmpty else { return [Term.end] }
        
        return parents.map { parent in
            let disclosures = parent.disclosures.filter { $0.contains(self) }
            
            return disclosures.map { disclosure in
                let followings = disclosure.suffixes(after: self)
                
                return followings.map { following in
                    let first = Self.getFirstSet(of: following)
                    
                    if first.contains(.eps) {
                        guard parent != self else { return [] }
                        return first.withRemoving(.eps).union(parent.followSet)
                        
                    } else { return first }
                    
                }.unionAll()

            }.unionAll()
            
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
