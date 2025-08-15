import SwiftUI

struct WeatherWarningSection: View {
    @ObservedObject var warningService: EmergencyWarningService
    @ObservedObject var stateManager: StateManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("🌦️ Emergency Weather Warnings")
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
                WeatherWarningLoadingView()
            } else {
                let weatherWarnings = warningService.activeWarnings.filter { $0.type == .severeWeather }
                
                if weatherWarnings.isEmpty {
                    WeatherWarningEmptyView(stateName: stateManager.selectedState)
                } else {
                    WeatherWarningListView(warnings: weatherWarnings)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
