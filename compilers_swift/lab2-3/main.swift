import Foundation

let fileName = "/Users/vsevolond/UNIVERSITY/Compilers_Labs/compilers_swift/lab2-3/input.txt"
do {
    let compiler = try Compiler(fileName: fileName)
    try compiler.compile()
    
    var (NGrammar, NRules, NAxiomeRule, NRule): (NonTerm, NonTerm, NonTerm, NonTerm) = ("Grammar", "Rules", "AxiomeRule", "Rule")
    var (NGroups, NGroup, NSequence, NElement): (NonTerm, NonTerm, NonTerm, NonTerm) = ("Groups", "Group", "Sequence", "Element")

    let star = Term(domain: .star)
    let openBracket = Term(domain: .openBracket)
    let closeBracket = Term(domain: .closeBracket)
    let ident = Term(domain: .ident)
    let char = Term(domain: .char)

    NGrammar => [NRules, NAxiomeRule, NRules]

    NRules => [NRule, NRules] | .eps
    NAxiomeRule => [star, NRule]
    NRule => [ident, NGroup, NGroups]

    NGroups => [NGroup, NGroups] | .eps
    NGroup => [openBracket, NSequence, closeBracket]

    NSequence => [NElement, NSequence] | .eps
    NElement => ident | char

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
    
} catch {
    if let error = error as? CompilerError {
        switch error {
            
        case .cannotOpenFile:
            print("can't open file")
            
        case .cannotReadFile:
            print("can't read file")
            
        case .unexpected(let coord):
            print("unexpected token in: \(coord.stringValue)")
        }
    }
}
