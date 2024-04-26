import Foundation

final class Node: Hashable {
    
    private let id: String
    private let label: Int
    private var childs: Set<Node> = .init()
    
    var name: String { "\(id)\(label)" }
    var property: String { "\(name) [label=\"\(id) (\(label))\"]" }
    var selfEdges: [String] { childs.map { "\(name) -> \($0.name)" } }
    
    var properties: Set<String> {
        childs.map { $0.properties }.unionAll().union([property])
    }
    var edges: Set<String> {
        childs.map { $0.edges }.unionAll().union(selfEdges)
    }
    
    init(_ id: String, _ label: Int) {
        self.id = id
        self.label = label
    }
    
    func addChild(_ node: Node) {
        childs.insert(node)
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool { lhs.id == rhs.id && lhs.label == rhs.label }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(label)
    }
}

final class Digraph {
    
    private var root: Node?
    private var nodesByID: [String : Node] = [:]
    private var nodesCountByGrammarID: [String : Int] = [:]
    
    func printGraph() {
        guard let root else { return }
        let properties = root.properties
        let edges = root.edges
        
        properties.forEach { property in
            print(property)
        }
        
        edges.forEach { edge in
            print(edge)
        }
    }
    
    func set(root rootID: String) -> String {
        let num = (nodesCountByGrammarID[rootID] ?? 0) + 1
        let graphID: String = rootID + "\(num)"
        
        let node = Node(rootID, num)
        nodesByID[graphID] = node
        nodesCountByGrammarID[rootID] = num
        root = node
        
        return graphID
    }
    
    func add(to rootID: String, nodes: [String]) -> [String] {
        guard let root = nodesByID[rootID] else { fatalError("there is no node with id: \(rootID)") }
        var nodesID: [String] = []
        
        for nodeID in nodes {
            let num = (nodesCountByGrammarID[nodeID] ?? 0) + 1
            let graphID: String = nodeID + "\(num)"
            
            let node = Node(nodeID, num)
            nodesByID[graphID] = node
            nodesCountByGrammarID[nodeID] = num
            
            root.addChild(node)
            nodesID.append(graphID)
        }
        
        return nodesID
    }
}
