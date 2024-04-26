import Foundation

final class UniqueQueue<T: Hashable> {
    
    private var items: Set<T> = .init()
    private var queue: [T] = .init()
    
    var isEmpty: Bool { queue.isEmpty }
    
    func push(_ elem: T) {
        guard !items.contains(elem) else { return }
        
        items.insert(elem)
        queue.append(elem)
    }
    
    func pop() -> T { queue.removeFirst() }
}
