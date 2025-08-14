import SwiftUI
import Contacts
import ContactsUI
import Foundation

struct ContactManagementView: View {
    @ObservedObject var contactHelper: ContactHelper
    @Environment(\.dismiss) var dismiss
    @State private var showingContactPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasContactPermission = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Checking permissions...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !hasContactPermission {
                    VStack(spacing: 20) {
                        Text("📱 Contact Permission Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This app needs access to your contacts to add emergency contacts for SOS messages.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Current Status: \(CNContactStore.authorizationStatus(for: .contacts).rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                        
                        Button("Grant Permission") {
                            requestContactAccess()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                        
                        Button("Check Permission Status") {
                            checkContactPermission()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                    }
                    .padding()
                } else if contactHelper.contacts.isEmpty {
                    VStack(spacing: 20) {
                        Text("📱 No Emergency Contacts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add contacts who should receive your emergency SOS messages")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("➕ Add Contact") {
                            safelyShowContactPicker()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("🔄 Refresh") {
                            contactHelper.refreshContacts()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                } else {
                    VStack {
                        HStack {
                            Text("Emergency Contacts (\(contactHelper.contacts.count))")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("🔄") {
                                contactHelper.refreshContacts()
                            }
                            .font(.title2)
                        }
                        .padding(.horizontal)
                        
                        List {
                            ForEach(contactHelper.contacts, id: \.identifier) { contact in
                                ContactRow(contact: contact)
                            }
                            .onDelete(perform: deleteContact)
                        }
                        
                        Button("➕ Add More Contacts") {
                            safelyShowContactPicker()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Emergency Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !contactHelper.contacts.isEmpty {
                        Button("Clear All") {
                            contactHelper.clearAllContacts()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView(contactHelper: contactHelper)
        }
        .alert("Contact Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            checkContactPermission()
        }
        .onChange(of: contactHelper.errorMessage) { _, errorMessage in
            if let errorMessage = errorMessage {
                alertMessage = errorMessage
                showingAlert = true
            }
        }
    }
    
    private func checkContactPermission() {
        isLoading = true
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            hasContactPermission = true
            isLoading = false
        case .denied, .restricted:
            hasContactPermission = false
            isLoading = false
        case .notDetermined:
            requestContactAccess()
        case .limited:
            hasContactPermission = true
            isLoading = false
        @unknown default:
            hasContactPermission = false
            isLoading = false
        }
    }
    
    private func requestContactAccess() {
        isLoading = true
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                isLoading = false
                hasContactPermission = granted
                
                if granted {
                    print("✅ Contact permission granted!")
                } else {
                    print("❌ Contact permission denied")
                }
                
                if let error = error {
                    alertMessage = "Error accessing contacts: \(error.localizedDescription)"
                    showingAlert = true
                } else if !granted {
                    alertMessage = "Contact permission denied. Please go to Settings → Privacy & Security → Contacts and enable access for HandsUpSOS."
                    showingAlert = true
                }
            }
        }
    }
    

    
    private func safelyShowContactPicker() {
        // Force the contact picker to open - this will trigger permission request if needed
        showingContactPicker = true
    }
    
    private func deleteContact(offsets: IndexSet) {
        contactHelper.removeContact(at: offsets)
    }
}

struct ContactRow: View {
    let contact: CNContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.givenName) \(contact.familyName)")
                    .font(.headline)
                
                if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                    Text(phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("📱")
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    @ObservedObject var contactHelper: ContactHelper
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if !contact.phoneNumbers.isEmpty {
                parent.contactHelper.addContact(contact)
            }
            parent.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
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
    ContactManagementView(contactHelper: ContactHelper())
}
