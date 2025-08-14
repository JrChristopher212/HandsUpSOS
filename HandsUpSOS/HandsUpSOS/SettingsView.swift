import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationHelper: LocationHelper
    @ObservedObject var contactHelper: ContactHelper
    @State private var showingContactSheet = false
    
    // SMS capability logic
    var canSendSMS: Bool {
        #if targetEnvironment(simulator)
        return true // Override for simulator testing
        #else
        return MFMessageComposeViewController.canSendText()
        #endif
    }
    
    var canSendSMSText: String {
        canSendSMS ? "Ready to send messages" : "SMS not available"
    }
    
    var body: some View {
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
                
                StatusCard(
                    title: "Emergency Contacts",
                    content: "\(contactHelper.contacts.count) contacts saved",
                    isGood: !contactHelper.contacts.isEmpty
                )
                
                StatusCard(
                    title: "SMS Capability",
                    content: canSendSMSText,
                    isGood: canSendSMS
                )
            }
            
            // Contact Management Section
            VStack(spacing: 15) {
                Button("👥 Manage Emergency Contacts") {
                    showingContactSheet = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingContactSheet) {
            ContactManagementView(contactHelper: contactHelper)
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
