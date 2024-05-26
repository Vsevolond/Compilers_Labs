import Foundation

struct Token {
    
    let tag: DomainTag
    let value: Any
    let coord: Fragment
    
    var isComment: Bool { tag == .comment }
    var isUnrecognized: Bool { tag == .unrecognized }
    var isEnd: Bool { tag == .endOfInput }
    
    init(tag: DomainTag, value: Any, coord: Fragment) {
        self.tag = tag
        self.value = value
        self.coord = coord
    }
}
