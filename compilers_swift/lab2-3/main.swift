import Foundation

let fileName = "/Users/vsevolond/UNIVERSITY/Compilers_Labs/compilers_swift/lab2-3/input.txt"
let compiler = try Compiler(fileName: fileName)
compiler.compile()

var (NGrammar, NRules, NAxiomeRule, NRule): (NonTerm, NonTerm, NonTerm, NonTerm) = ("Grammar", "Rules", "AxiomeRule", "Rule")
var (NGroups, NGroup, NSequence, NElement): (NonTerm, NonTerm, NonTerm, NonTerm) = ("Groups", "Group", "Sequence", "Element")
var (NTerm, NNonTerm, NSymbol, NMark): (NonTerm, NonTerm, NonTerm, NonTerm) = ("Term", "NonTerm", "Symbol", "Mark")

let star = Term(domain: .star)
let openBracket = Term(domain: .openBracket)
let closeBracket = Term(domain: .closeBracket)
let quote = Term(domain: .quote)
let ident = Term(domain: .ident)
let plus = Term(domain: .plus)
let char = Term(domain: .char)
let mark = Term(domain: .mark)

NGrammar => [NRules, NAxiomeRule, NRules]

NRules => [NRule, NRules] | .eps
NAxiomeRule => [star, NRule]
NRule => [NNonTerm, NGroup, NGroups]

NGroups => [NGroup, NGroups] | .eps
NGroup => [openBracket, NSequence, closeBracket]

NSequence => [NElement, NSequence] | .eps
NElement => NTerm | NNonTerm

NTerm => [quote, NSymbol, quote]
NNonTerm => [ident, NMark]

NSymbol => plus | star | openBracket | closeBracket | char
NMark => mark | .eps

let parser = Parser(by: NGrammar)
let result = parser.parse(tokens: compiler.tokens)

switch result {
case .success(let graph):
    graph.printGraph()
    
case .failure(let failure):
    switch failure {
        
    case .invalid(let expected, let given, let coord):
        print("expected: \(expected), but given: \"\(given)\" in \(coord.stringValue)")
    }
}
