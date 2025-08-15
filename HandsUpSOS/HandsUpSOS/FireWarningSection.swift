import SwiftUI

struct FireWarningSection: View {
    @ObservedObject var warningService: EmergencyWarningService
    @ObservedObject var stateManager: StateManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("🚨 Emergency Fire Warnings")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    warningService.refreshWarnings()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .disabled(warningService.isLoading)
            }
            
                        if warningService.isLoading {
                FireWarningLoadingView()
            } else {
                let fireWarnings = warningService.activeWarnings.filter { $0.type == .fire }
                
                if fireWarnings.isEmpty {
                    FireWarningEmptyView(stateName: stateManager.selectedState)
                } else {
                    FireWarningListView(warnings: fireWarnings)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
