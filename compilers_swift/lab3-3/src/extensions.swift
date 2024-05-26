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

extension Array {
    
    func withInserting(at: Int, elem: Element) -> Array<Element> {
        var result = self
        result.insert(elem, at: 0)
        return result
    }
    
    func withAppending(_ sequence: Array<Element>) -> Array<Element> {
        var result = self
        result.append(contentsOf: sequence)
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
