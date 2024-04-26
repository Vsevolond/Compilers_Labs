import Foundation

final class Stack<T> {

    private var items: [T] = []
    
    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }
    var top: T? { items.last }

    func push(_ item: T) { items.append(item) }
    
    func push(_ items: [T]) {
        items.forEach { item in
            push(item)
        }
    }

    @discardableResult
    func pop() -> T { items.removeLast() }
    
    @discardableResult
    func pop(count: Int) -> [T] {
        guard count <= items.count else {
            fatalError("count is more than count of exist items")
        }
        
        var top = [T]()
        (0..<count).forEach { _ in
            top.append(pop())
        }
        
        return top
    }
}
