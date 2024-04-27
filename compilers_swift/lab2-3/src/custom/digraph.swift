import Foundation

final class Node {
    
    let id: String
    let name: String
    var parent: Node?
    
    var offset: String {
        guard let parent else { return .empty }
        return parent.offset + "    "
    }
    
    private var childs: Set<Node> = .init()
    
    init(_ name: String) {
        self.id = UUID().uuidString
        self.name = name
    }
    
    func addChild(_ node: Node) {
        childs.insert(node)
    }
    
    func printNode() {
        if childs.isEmpty {
            print(offset, name, separator: .empty)
            
        } else {
            print(offset, name, ":", separator: .empty)
        }
        
        for child in childs {
            child.printNode()
        }
    }
}

extension Node: Hashable {
    
    static func == (lhs: Node, rhs: Node) -> Bool { lhs.id == rhs.id && lhs.name == rhs.name }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

final class Digraph {
    
    private var root: Node?
    private var nodesByID: [String : Node] = [:]
    
    func printGraph() {
        guard let root else { return }
        root.printNode()
    }
    
    func set(root name: String) -> String {
        let node = Node(name)
        nodesByID[node.id] = node
        root = node
        
        return node.id
    }
    
    func add(toNode id: String, nodes: [String]) -> [String] {
        guard let node = nodesByID[id] else { fatalError("there is no node with id: \(id)") }
        var nodesID: [String] = []
        
        for name in nodes {
            let child = Node(name)
            child.parent = node
            nodesByID[child.id] = child
            
            node.addChild(child)
            nodesID.append(child.id)
        }
        
        return nodesID
    }
}
