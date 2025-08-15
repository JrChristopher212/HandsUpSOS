import Foundation

class StateManager: ObservableObject {
    @Published var selectedState: String = "Victoria"
    
    let australianStates = [
        "Australian Capital Territory",
        "New South Wales", 
        "Northern Territory",
        "Queensland",
        "South Australia",
        "Tasmania",
        "Victoria",
        "Western Australia"
    ]
    
    init() {
        // Load saved state from UserDefaults
        selectedState = UserDefaults.standard.string(forKey: "SelectedState") ?? "Victoria"
    }
    
    func updateState(_ newState: String) {
        selectedState = newState
        // Save to UserDefaults
        UserDefaults.standard.set(newState, forKey: "SelectedState")
    }
    
    // Get abbreviated state name for display
    var abbreviatedState: String {
        switch selectedState {
        case "Australian Capital Territory": return "ACT"
        case "New South Wales": return "NSW"
        case "Northern Territory": return "NT"
        case "Queensland": return "QLD"
        case "South Australia": return "SA"
        case "Tasmania": return "TAS"
        case "Victoria": return "VIC"
        case "Western Australia": return "WA"
        default: return selectedState
        }
    }
    
    // Get fire service name for the selected state
    var fireServiceName: String {
        switch selectedState {
        case "Victoria": return "CFA (Country Fire Authority)"
        case "New South Wales": return "RFS (Rural Fire Service)"
        case "Queensland": return "QFES (Queensland Fire and Emergency Services)"
        case "Western Australia": return "DFES (Department of Fire and Emergency Services)"
        case "South Australia": return "CFS (Country Fire Service)"
        case "Tasmania": return "TFS (Tasmania Fire Service)"
        case "Northern Territory": return "NT Fire and Rescue"
        case "Australian Capital Territory": return "ACT Fire and Rescue"
        default: return "State Fire Service"
        }
    }
}
