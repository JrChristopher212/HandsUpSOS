//
//  ContentView.swift
//  HandsUpSOS
//
//  Created by Jedda Tuuta on 10/8/2025.
//

import SwiftUI
import MessageUI

struct ContentView: View {
    @ObservedObject var locationHelper: LocationHelper
    @ObservedObject var contactHelper: ContactHelper
    
    @State private var showingContactSheet = false
    @State private var showingEmergencyOptions = false
    @State private var showingMessageComposer = false
    @State private var userName = ""
    @State private var selectedTemplate: EmergencyTemplate?
    @State private var emergencyMessage = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Performance optimization: cache computed values
    @State private var cachedCanSendSOS = false
    @State private var cachedCanSendSMS = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                
                // App Title
                Text("🚨 HandsUpSOS ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("For Deaf Campers & Hikers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
                    Text("⚠️ Setup needed: Add contacts & enable location")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Settings Section
                VStack(spacing: 15) {
                    Button("👥 Manage Emergency Contacts") {
                        showingContactSheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    TextField("Your name (for emergency services)", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Copy Emergency Message Button
                    if !emergencyMessage.isEmpty {
                        Button("📋 Copy Emergency Message") {
                            UIPasteboard.general.string = emergencyMessage
                            alertMessage = "Emergency message copied to clipboard!"
                            showingAlert = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .foregroundColor(.green)
                    }
                }
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
            .navigationTitle("Emergency Helper")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingContactSheet) {
            ContactManagementView(contactHelper: contactHelper)
        }
        .actionSheet(isPresented: $showingEmergencyOptions) {
            createEmergencyActionSheet()
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
            // Cache computed values for performance
            updateCache()
        }
        .onChange(of: contactHelper.contacts.count) { _, _ in
            // Update cache when contacts change
            updateCache()
        }
        .onChange(of: locationHelper.hasPermission) { _, _ in
            // Update cache when location permission changes
            updateCache()
        }
        .onAppear {
            locationHelper.getCurrentLocation()
            loadUserName()
        }
        .onChange(of: userName) { _, _ in
            saveUserName()
        }
    }
    
    var canSendSMS: Bool {
        #if targetEnvironment(simulator)
        return true // Override for simulator testing
        #else
        return MFMessageComposeViewController.canSendText()
        #endif
    }
    
    var canSendSMSText: String {
        cachedCanSendSMS ? "Ready to send messages" : "SMS not available"
    }
    
    var canSendSOS: Bool {
        cachedCanSendSOS
    }
    
    func handleEmergencyPressed() {
        locationHelper.getCurrentLocation()
        showingEmergencyOptions = true
    }
    
    private func updateCache() {
        cachedCanSendSMS = canSendSMS
        cachedCanSendSOS = !contactHelper.contacts.isEmpty && cachedCanSendSMS && locationHelper.hasPermission
    }
    
    func createEmergencyActionSheet() -> ActionSheet {
        var buttons: [ActionSheet.Button] = []
        
        // Add template buttons
        for template in EmergencyTemplate.campingTemplates {
            buttons.append(.destructive(Text("\(template.emoji) \(template.title)")) {
                sendEmergencyMessage(template: template)
            })
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text("🚨 SELECT EMERGENCY TYPE"),
            message: Text("This will send SMS to all your emergency contacts"),
            buttons: buttons
        )
    }
    
    func sendEmergencyMessage(template: EmergencyTemplate) {
        let locationText = locationHelper.getEmergencyLocationText()
        
        emergencyMessage = EmergencyMessageBuilder.createMessage(
            template: template,
            userName: userName,
            location: locationText
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

struct SimulatorMessagePreview: View {
    let message: String
    let recipients: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
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

#Preview {
    ContentView(
        locationHelper: LocationHelper(),
        contactHelper: ContactHelper()
    )
}
