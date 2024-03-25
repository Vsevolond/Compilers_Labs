import Foundation

struct FSMTransition {
    
    let to: Int
    let by: (Character) -> Bool
}
