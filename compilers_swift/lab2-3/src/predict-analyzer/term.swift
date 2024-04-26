import Foundation

final class Term: GrammarElem {
    
    let domain: DomainTag
    
    override var isTerm: Bool { true }
    
    static let end: Term = .init(domain: .endOfGrammar)
    
    init(domain: DomainTag) {
        self.domain = domain
        super.init(id: domain.rawValue)
    }
}
