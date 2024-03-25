import Foundation

class FSM {
    
    private var states: [Int: FSMState] = [:]
    private var initialState: FSMState
    private var currentState: FSMState
    
    init(array: [FSMState]) {
        guard let start = array.first(where: { $0.tag == .start }) else {
            fatalError("there aren't start state")
        }
        initialState = start
        currentState = start
        
        array.forEach { state in
            states.updateValue(state, forKey: state.id)
        }
    }
    
    func refresh() {
        currentState = initialState
    }
    
    func goto(by char: Character) -> FSMState? {
        guard let stateID = currentState.goto(by: char) else {
            return .none
        }
        
        guard let state = states[stateID] else {
            fatalError("there are no states with id: \(stateID)")
        }
        
        currentState = state
        return state
    }
}
