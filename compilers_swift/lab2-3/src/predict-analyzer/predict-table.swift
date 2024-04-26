import Foundation

final class PredictTable {
    
    private var table: [NonTerm : PredictTableRow] = [:]
    
    func set(for nonTerm: NonTerm, by term: Term, rule elements: [GrammarElem]) {
        if table[nonTerm] == nil {
            table[nonTerm] = .init()
        }
        
        table[nonTerm]?.set(for: term, rule: elements)
    }
    
    func get(for nonTerm: NonTerm, by term: Term) -> [GrammarElem] {
        guard let grammarRule = table[nonTerm]?.get(by: term) else {
            return []
        }
        
        return grammarRule
    }
    
    func possible(for nonTerm: NonTerm) -> [Term] { table[nonTerm]?.possible() ?? [] }
    
    func isEmpty(for nonTerm: NonTerm, by term: Term) -> Bool { table[nonTerm]?.isEmpty(by: term) ?? true }
}

struct PredictTableRow {
    
    private var row: [Term : [GrammarElem]] = [:]
    
    mutating func set(for term: Term, rule elements: [GrammarElem]) {
        row.updateValue(elements, forKey: term)
    }
    
    func get(by term: Term) -> [GrammarElem] { row[term] ?? [] }
    
    func isEmpty(by term: Term) -> Bool { row[term] == nil }
    
    func possible() -> [Term] { row.keys.map { $0 } }
}
