import Foundation

func readFromFile(fileName: String) -> [String] {
    guard let text = try? String(contentsOfFile: fileName) else {
        return []
    }
    let split = text.split(separator: "\n").map { String($0) }
    
    return split
}

extension NSRegularExpression {
    
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
}


extension NSRegularExpression {
    
    func matches(_ string: String) -> (first: Int, last: Int) {
        let range = NSRange(location: 0, length: string.utf8.count)
        guard let match = firstMatch(in: string, range: range) else {
            return (0, 0)
        }
        return (match.range.lowerBound, match.range.upperBound)
    }
}

enum Lexem: CaseIterable {
    
    case keyWord
    case comment
    case ident
    case operation
    case space
    
    var string: String {
        switch self {
        case .ident: return "IDENT"
        case .keyWord: return "KEYWORD"
        case .comment: return "COMMENT"
        case .operation: return "OPERATION"
        case .space: return ""
        }
    }
    
    var expression: NSRegularExpression {
        switch self {
        case .ident: return .init("^\\p{L}[\\p{L}\\d]*(?:[%$#&!])?")
        case .keyWord: return .init("(FOR|NEXT|for|next)")
        case .comment: return .init("REM\\b.*")
        case .operation: return .init("[+\\-/\\\\]")
        case .space: return .init("\\s")
        }
    }
    
    static func getLexemType(by string: String) -> (Lexem, String, Int)? {
        let lexems = Lexem.allCases.filter { type in
            let range = type.expression.matches(string)
            return range.first == 0 && range.last != 0
        }
        
        guard var lexem = lexems.first else { return nil }
        var range = lexem.expression.matches(string)
        
        for i in 1..<lexems.count {
            let currentRange = lexems[i].expression.matches(string)
            
            if (range.last - range.first) < (currentRange.last - currentRange.first) {
                lexem = lexems[i]
                range = currentRange
            }
        }
        
        let value = string[..<string.index(string.startIndex, offsetBy: range.last)]
        return (lexem, String(value), range.last)
    }
}

let fileName = "/Users/vsevolond/UNIVERSITY/compilers_swift/lab1-2/input.txt"
let rows = readFromFile(fileName: fileName)

for (i, row) in rows.enumerated() {
    
    var j = 0
    var errorPos: Int? = nil
    
    while j < row.count {
        let startIndex = row.index(row.startIndex, offsetBy: j)
        if let (lexem, value, index) = Lexem.getLexemType(by: String(row[startIndex...])) {
            if lexem != .space {
                print("\(lexem.string) (\(i), \(j)): \(value)")
            }
            j += index
            errorPos = nil
            
        } else {
            if errorPos == nil {
                print("syntax error (\(i), \(j))")
            }
            errorPos = j
            j += 1
        }
    }
}





