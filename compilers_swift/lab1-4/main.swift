import Foundation

let fileName = "/Users/vsevolond/UNIVERSITY/compilers_swift/lab1-4/input.txt"

let states: [FSMState] = [
    .init(id: 0, tag: .start, isFinal: false, transitions: [
        .init(to: 1, by: { $0 == "r" }),
        .init(to: 5, by: { $0 == "l" }),
        .init(to: 15, by: { $0.isNumber }),
        .init(to: 9, by: { $0 == ">" }),
        .init(to: 11, by: { $0 == ":" }),
        .init(to: 14, by: { $0.isLetter && $0 != "l" && $0 != "r" })
    ]),
    .init(id: 15, tag: .number, isFinal: true, transitions: [
        .init(to: 15, by: { $0.isNumber })
    ]),
    .init(id: 9, tag: .none, isFinal: false, transitions: [
        .init(to: 10, by: { $0 == "=" })
    ]),
    .init(id: 11, tag: .none, isFinal: false, transitions: [
        .init(to: 10, by: { $0 == "=" }),
        .init(to: 12, by: { $0 == ":" })
    ]),
    .init(id: 10, tag: .operation, isFinal: true, transitions: []),
    .init(id: 12, tag: .comment, isFinal: false, transitions: [
        .init(to: 12, by: { !$0.isNewline && $0 != .empty }),
        .init(to: 13, by: { $0.isNewline || $0 == .empty })
    ]),
    .init(id: 13, tag: .comment, isFinal: true, transitions: []),
    .init(id: 5, tag: .ident, isFinal: true, transitions: [
        .init(to: 6, by: { $0 == "o" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "o") })
    ]),
    .init(id: 6, tag: .ident, isFinal: true, transitions: [
        .init(to: 7, by: { $0 == "n" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "n") })
    ]),
    .init(id: 7, tag: .ident, isFinal: true, transitions: [
        .init(to: 8, by: { $0 == "g" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "g") })
    ]),
    .init(id: 8, tag: .ident, isFinal: true, transitions: [
        .init(to: 1, by: { $0 == "r" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "r") })
    ]),
    .init(id: 1, tag: .ident, isFinal: true, transitions: [
        .init(to: 2, by: { $0 == "e" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "e") })
    ]),
    .init(id: 2, tag: .ident, isFinal: true, transitions: [
        .init(to: 3, by: { $0 == "a" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "a") })
    ]),
    .init(id: 3, tag: .ident, isFinal: true, transitions: [
        .init(to: 4, by: { $0 == "l" }),
        .init(to: 14, by: { $0.isNumber || ($0.isLetter && $0 != "l") })
    ]),
    .init(id: 4, tag: .keyword, isFinal: true, transitions: [
        .init(to: 14, by: { $0.isLetter || $0.isNumber })
    ]),
    .init(id: 14, tag: .ident, isFinal: true, transitions: [
        .init(to: 14, by: { $0.isLetter || $0.isNumber })
    ])
]

let fsm = FSM(array: states)

let compiler = try Compiler(fileName: fileName, fsm: fsm)
compiler.compile()

compiler.printMessages()




