import Foundation

struct Token {
    
    private let tag: DomainTag
    private let coords: Fragment
    
    var stringValue: String { "\(tag.key) \(coords.stringValue): \(tag.value)" }
    
    var isUnrecognized: Bool { tag == .unrecognized }
    var isEnd: Bool { tag == .endOfProgram }
    
    init(tag: DomainTag, coords: Fragment) {
        self.tag = tag
        self.coords = coords
    }
}
