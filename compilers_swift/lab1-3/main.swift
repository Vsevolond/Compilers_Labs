import Foundation

let fileName = "/Users/vsevolond/UNIVERSITY/compilers_swift/lab1-3/input.txt"


let compiler = try Compiler(fileName: fileName)
compiler.compile()

compiler.printMessages()
