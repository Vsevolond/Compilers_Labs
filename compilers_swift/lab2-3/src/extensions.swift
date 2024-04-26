import Foundation

extension String {
    
    static let empty: String = ""
}

extension Character {
    
    static let empty: Character = Character(UnicodeScalar(0))
    
    var isWhiteSpaceOrNewLine: Bool { isWhitespace || isNewline }
}

extension Array where Element: SetAlgebra, Element.Element: Hashable {
    
    func unionAll() -> Element {
        var result: Element = .init()
        
        forEach { array in
            result.formUnion(array)
        }
        
        return result
    }
}

extension Array where Element: Hashable {
    
    func suffixes(after elem: Element) -> Set<[Element]> {
        var follows: Set<[Element]> = .init()
        var elements = self
        
        while !elements.isEmpty {
            let removed = elements.removeFirst()
            if removed == elem {
                follows.insert(elements)
            }
        }
        
        return follows
    }
}

extension Array {
    
    func withRemovingFirst() -> Array<Element> {
        var result = self
        result.removeFirst()
        return result
    }
}

extension Set {
    
    func withRemoving(_ elem: Element) -> Set<Element> {
        var result = self
        result.remove(elem)
        return result
    }
}
