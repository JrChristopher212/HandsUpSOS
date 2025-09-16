//
//  ContentView.swift
//  HandsUpSOS
//
//  Created by Jedda Tuuta on 10/8/2025.
//

import SwiftUI
import MessageUI
import Contacts

struct ContentView: View {
    @ObservedObject var locationHelper: LocationHelper
    @ObservedObject var contactHelper: ContactHelper
    @ObservedObject var campsiteManager: CampsiteManager
    @ObservedObject var stateManager: StateManager
    @StateObject private var warningService = EmergencyWarningService()
    
    @State private var showingContactSheet = false
    @State private var showingEmergencyOptions = false
    @State private var showingMessageComposer = false
    @State private var userName = ""
    @State private var selectedTemplate: EmergencyTemplate?
    @State private var emergencyMessage = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Removed complex caching - using direct computed properties instead
    
    var body: some View {
        VStack(spacing: 25) {
                
                // App Title
                Text("🚨 HandsUpSOS ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("For Deaf Campers & Hikers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                

                
                // Big Emergency Button
                Button(action: {
                    handleEmergencyPressed()
                }) {
                    VStack(spacing: 8) {
                        Text("🚨")
                            .font(.system(size: 40))
                        Text("EMERGENCY")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("SEND SOS")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(width: 280, height: 120)
                    .background(canSendSOS ? Color.red : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(!canSendSOS)
                .scaleEffect(canSendSOS ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.3).speed(0.8), value: canSendSOS)
                
                if !canSendSOS {
                    VStack(spacing: 8) {
                        Text("⚠️ Setup needed:")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                        
                        if contactHelper.contacts.isEmpty {
                            Text("• Add emergency contacts")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        if !locationHelper.hasPermission {
                            Text("• Enable location access")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        Button("Manage Emergency Contacts") {
                            showingContactSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                // Fire Rating Section
                FireRatingSection(warningService: warningService, stateManager: stateManager)
                
                                // Emergency Fire Warnings Section
                FireWarningSection(warningService: warningService, stateManager: stateManager)
                
                // Weather Warnings Section
                WeatherWarningSection(warningService: warningService, stateManager: stateManager)
                
                // Nearby Emergency Resources Section
                NearbyResourcesSection(campsiteManager: campsiteManager, locationHelper: locationHelper)
                
                Spacer()
                

            }
            .padding()
            .background(
                ZStack {
                    Image("HushSOS")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .clipped()
                    
                    // Semi-transparent overlay for better text readability
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
            )
        .sheet(isPresented: $showingContactSheet) {
            ContactManagementView(contactHelper: contactHelper)
        }
        .confirmationDialog("🚨 SELECT EMERGENCY TYPE", isPresented: $showingEmergencyOptions) {
            createEmergencyButtons()
        } message: {
            Text("This will send SMS to all your emergency contacts")
        }
        .sheet(isPresented: $showingMessageComposer) {
            if canSendSMS {
                #if targetEnvironment(simulator)
                // Simulator preview - show what the SMS would look like
                SimulatorMessagePreview(
                    message: emergencyMessage,
                    recipients: contactHelper.getPhoneNumbers()
                )
                #else
                // Real device - use actual SMS composer
                MessageComposeView(
                    message: emergencyMessage,
                    recipients: contactHelper.getPhoneNumbers()
                ) { result in
                    handleMessageResult(result)
                }
                #endif
            }
        }
        .alert("Emergency Status", isPresented: $showingAlert) {
            Button("OK") { }
            Button("Copy Message") {
                UIPasteboard.general.string = emergencyMessage
            }
        }
        .onAppear {
            locationHelper.getCurrentLocation()
            loadUserName()
            
            // Automatically request contact permission if not granted
            requestContactPermissionIfNeeded()
            
            // Refresh warnings with current location when available
            if let location = locationHelper.currentLocation {
                warningService.refreshWarnings(for: location)
            }
        }
        .onChange(of: userName) { _, _ in
            saveUserName()
        }
        .onChange(of: locationHelper.currentLocation) { _, newLocation in
            // Update warnings when location changes
            if let location = newLocation {
                warningService.refreshWarnings(for: location)
            }
        }
        }
    
    var canSendSMS: Bool {
        #if targetEnvironment(simulator)
        return true // Override for simulator testing
        #else
        return MFMessageComposeViewController.canSendText()
        #endif
    }
    
    var canSendSOS: Bool {
        return !contactHelper.contacts.isEmpty && canSendSMS && locationHelper.hasPermission
    }
    

    
    func handleEmergencyPressed() {
        print("🚨 Emergency button tapped!")
        print("📱 canSendSOS: \(canSendSOS)")
        print("📱 contacts count: \(contactHelper.contacts.count)")
        print("📱 canSendSMS: \(canSendSMS)")
        print("📱 location permission: \(locationHelper.hasPermission)")
        
        locationHelper.getCurrentLocation()
        showingEmergencyOptions = true
    }
    
    // Removed complex caching - canSendSOS is now a simple computed property
    
    func createEmergencyButtons() -> some View {
        ForEach(EmergencyTemplate.campingTemplates, id: \.title) { template in
            Button("\(template.emoji) \(template.title)", role: .destructive) {
                sendEmergencyMessage(template: template)
            }
        }
    }
    
    func sendEmergencyMessage(template: EmergencyTemplate) {
        let locationText = locationHelper.getEmergencyLocationText()
        
        emergencyMessage = EmergencyMessageBuilder.createMessage(
            template: template,
            userName: userName,
            location: locationText,
            campsiteManager: campsiteManager,
            userLocation: locationHelper.currentLocation?.coordinate
        )
        
        showingMessageComposer = true
    }
    
    func handleMessageResult(_ result: MessageComposeResult) {
        switch result {
        case .sent:
            alertMessage = "✅ Emergency SOS sent successfully!\n\nYour emergency contacts have been notified and should call 000 for you."
        case .failed:
            alertMessage = "❌ Failed to send emergency message.\n\nTry again or call 000 directly if possible."
        case .cancelled:
            alertMessage = "Emergency message cancelled."
        @unknown default:
            alertMessage = "Unknown result from message sending."
        }
        showingAlert = true
    }
    
    func saveUserName() {
        UserDefaults.standard.set(userName, forKey: "UserName")
    }
    
    func loadUserName() {
        userName = UserDefaults.standard.string(forKey: "UserName") ?? ""
    }
    
    private func requestContactPermissionIfNeeded() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .notDetermined:
            print("📱 Requesting contact permission...")
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Contact permission granted automatically!")
                    } else {
                        print("❌ Contact permission denied automatically")
                    }
                }
            }
        case .authorized, .limited:
            print("✅ Contact permission already granted")
        case .denied, .restricted:
            print("❌ Contact permission denied or restricted - User needs to enable in Settings")
        @unknown default:
            print("❓ Unknown contact permission status")
        }
    }
}





struct SimulatorMessagePreview: View {
    let message: String
    let recipients: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("📱 SMS Preview (Simulator)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("To:")
                        .font(.headline)
                    ForEach(recipients, id: \.self) { recipient in
                        Text("📞 \(recipient)")
                            .font(.body)
                            .padding(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Message:")
                        .font(.headline)
                    Text(message)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text("💡 This is a simulator preview. On a real device, this would open the SMS composer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Close Preview") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
            .navigationTitle("SMS Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct NearbyCampsiteRow: View {
    let campsite: Campsite
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(campsite.category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(campsite.name)
                        .font(.headline)
                    
                    Text(campsite.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= campsite.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("📶 \(campsite.cellReception.rawValue)")
                        .font(.caption2)
                        .foregroundColor(campsite.cellReception.color)
                }
            }
            
            // Emergency info if available
            if campsite.emergencyContact != nil || campsite.nearestHospital != nil {
                HStack {
                    Text("🚨 Emergency Info Available")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Helper Views
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView(
        locationHelper: LocationHelper(),
        contactHelper: ContactHelper(),
        campsiteManager: CampsiteManager(),
        stateManager: StateManager()
    )
}
