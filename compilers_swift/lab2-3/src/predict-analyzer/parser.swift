import Foundation

enum ParseError: Error {
    
    case invalid(expected: [String], given: String, coord: Fragment)
}

final class Parser {
    
    private let predictTable: PredictTable = .init()
    private let axiome: NonTerm
    
    init(by axiome: NonTerm) {
        self.axiome = axiome
        setupPredictTable(by: axiome)
    }
    
    private func setupPredictTable(by axiome: NonTerm) {
        let queue = UniqueQueue<NonTerm>()
        queue.push(axiome)
        
        while !queue.isEmpty {
            let nonTerm = queue.pop()
            
            for disclosure in nonTerm.disclosures {
                let newNonTerms = disclosure.filter { $0.isNonTerm }.compactMap { $0 as? NonTerm }
                newNonTerms.forEach { newNonTerm in
                    queue.push(newNonTerm)
                }
                
                let first = NonTerm.getFirstSet(of: disclosure)
                for grammarElem in first {
                    guard let term = grammarElem as? Term else { continue }
                    guard predictTable.isEmpty(for: nonTerm, by: term) else { fatalError("this is not LL1 grammar") }
                    
                    predictTable.set(for: nonTerm, by: term, rule: disclosure)
                }
                
                if first.contains(.eps) {
                    for term in nonTerm.followSet.compactMap({ $0 as? Term }) {
                        guard predictTable.isEmpty(for: nonTerm, by: term) else { fatalError("this is not LL1 grammar") }
                        
                        predictTable.set(for: nonTerm, by: term, rule: disclosure)
                    }
                }
            }
        }
    }
    
    func parse(tokens: [Token]) -> Result<Digraph, ParseError> {
        let digraph = Digraph()
        
        let stack = Stack<(graphID: String, elem: GrammarElem)>()
        stack.push([("$", Term.end), (digraph.set(root: axiome.id), axiome)])
        
        var tokenPoint: Int = 0
        var token: Token { tokens[tokenPoint] }
        
        while let top = stack.top, top.elem != Term.end {
            let (grammarElem, elemID) = (top.elem, top.graphID)
            let tokenTerm = Term(domain: token.tag)
            
            if grammarElem.isTerm, let term = grammarElem as? Term {
                guard term == tokenTerm else {
                    return .failure(.invalid(expected: [term.domain.value], given: token.value, coord: token.coord))
                }
                
                stack.pop()
                tokenPoint += 1
                
            } else if grammarElem.isNonTerm, let nonTerm = grammarElem as? NonTerm, !predictTable.isEmpty(for: nonTerm, by: tokenTerm) {
                let disclosure = predictTable.get(for: nonTerm, by: tokenTerm)
                stack.pop()
                
                let graphIDs = digraph.add(toNode: elemID, nodes: disclosure.map { $0.id })
                guard disclosure != [.eps] else { continue }
                
                let newElements: [(graphID: String, elem: GrammarElem)] = disclosure.enumerated().map { index, elem in
                    (graphIDs[index], elem)
                }.reversed()
                
                stack.push(newElements)
                
            } else {
                if grammarElem.isNonTerm, let nonTerm = grammarElem as? NonTerm {
                    return .failure(.invalid(expected: predictTable.possible(for: nonTerm).map { $0.id }, given: token.value, coord: token.coord))
                    
                } else { return .failure(.invalid(expected: [grammarElem.id], given: token.value, coord: token.coord)) }
            }
        }
        
        return .success(digraph)
    }
}
