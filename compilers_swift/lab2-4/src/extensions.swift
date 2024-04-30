import Foundation

extension NSRegularExpression {
    
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
    
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}

extension String {
    
    static let empty: String = ""
    
    var isIdent: Bool { Constants.identRegex.matches(self) }
    var isKeyword: Bool { KeywordType.allCases.map { $0.rawValue }.contains(self) }
    var isArithmOp: Bool { ArithmeticOperationType.allCases.map { $0.rawValue }.contains(self) }
    var isGlobalType: Bool { GlobalType.allCases.map { $0.rawValue }.contains(self) }
    var isLocalType: Bool { Constants.localTypeRegex.matches(self) }
    var isBoolean: Bool { self == "TRUE" || self == "FALSE" }
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

// MARK: - Constants

private enum Constants {
    
    static let identRegex: NSRegularExpression = .init("^[a-z][0-9a-zA-Z]*$")
    static let localTypeRegex: NSRegularExpression = .init("^[A-Z][0-9a-zA-Z]*$")
}
