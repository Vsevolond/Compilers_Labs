import Foundation

struct Token {
    
    let tag: DomainTag
    let value: String
    let coord: Fragment
    
    var isUnrecognized: Bool { tag == .unrecognized }
    var isEnd: Bool { tag == .endOfInput }
    
    init(tag: DomainTag, value: String, coord: Fragment) {
        self.tag = tag
        self.value = value
        self.coord = coord
    }
}
