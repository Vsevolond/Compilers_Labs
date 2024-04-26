import Foundation

struct Token {
    
    let tag: DomainTag
    let value: Character
    let coord: Fragment
    
    var isUnrecognized: Bool { tag == .unrecognized }
    var isEnd: Bool { tag == .endOfGrammar }
    
    init(tag: DomainTag, value: Character, coord: Fragment) {
        self.tag = tag
        self.value = value
        self.coord = coord
    }
}
