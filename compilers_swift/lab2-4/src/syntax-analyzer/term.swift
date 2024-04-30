import Foundation

final class Term: GrammarElem {
    
    let domain: DomainTag
    
    override var isTerm: Bool { true }
    
    init(domain: DomainTag) {
        self.domain = domain
        super.init(id: domain.value)
    }
}
