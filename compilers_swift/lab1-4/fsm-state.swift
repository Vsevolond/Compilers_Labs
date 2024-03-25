import Foundation

enum FSMStateTag {
    
    case start
    case ident
    case number
    case keyword
    case operation
    case comment
    case none
}

struct FSMState {
    
    let id: Int
    let tag: FSMStateTag
    let isFinal: Bool
    let transitions: [FSMTransition]
    
    init(id: Int, tag: FSMStateTag, isFinal: Bool, transitions: [FSMTransition]) {
        self.id = id
        self.tag = tag
        self.isFinal = isFinal
        self.transitions = transitions
    }
    
    func goto(by char: Character) -> Int? {
        let states: [Int] = transitions.compactMap { $0.by(char) ? $0.to : nil }
        return states.first
    }
}
