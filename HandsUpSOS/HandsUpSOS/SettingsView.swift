import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationHelper: LocationHelper
    @ObservedObject var contactHelper: ContactHelper
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // App Title
                Text("⚙️ Settings & Status")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                // Status Section
                VStack(spacing: 15) {
                    StatusCard(
                        title: "Location Status",
                        content: locationHelper.locationText,
                        isGood: locationHelper.hasPermission && locationHelper.currentLocation != nil
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Helper Views
struct StatusCard: View {
    let title: String
    let content: String
    let isGood: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(isGood ? "✅" : "⚠️")
            }
            Text(content)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SettingsView(
        locationHelper: LocationHelper(),
        contactHelper: ContactHelper()
    )
}
