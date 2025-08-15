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
                        Text("📱 Select Emergency Contacts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Choose contacts who should receive your emergency SOS messages")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("📋 Select from Contacts") {
                            safelyShowContactPicker()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Text("Tap to see all your contacts with phone numbers")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
        print("📱 Opening contact picker...")
        print("📱 Current contact permission status: \(CNContactStore.authorizationStatus(for: .contacts).rawValue)")
        
        // Force the contact picker to open - this will trigger permission request if needed
        showingContactPicker = true
    }
    
    private func deleteContact(offsets: IndexSet) {
        contactHelper.removeContact(at: offsets)
    }
    
    private func testContactAccess() {
        print("🔍 Testing contact access...")
        let store = CNContactStore()
        
        let request = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ])
        
        do {
            var contactCount = 0
            var phoneContactCount = 0
            
            try store.enumerateContacts(with: request) { contact, stop in
                contactCount += 1
                if !contact.phoneNumbers.isEmpty {
                    phoneContactCount += 1
                    print("📱 Found contact with phone: \(contact.givenName) \(contact.familyName)")
                }
            }
            
            print("🔍 Total contacts: \(contactCount)")
            print("🔍 Contacts with phones: \(phoneContactCount)")
            
        } catch {
            print("❌ Error testing contacts: \(error)")
        }
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

struct ContactPickerView: View {
    @ObservedObject var contactHelper: ContactHelper
    @Environment(\.dismiss) var dismiss
    @State private var allContacts: [CNContact] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return allContacts
        }
        return allContacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading contacts...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allContacts.isEmpty {
                    VStack(spacing: 20) {
                        Text("📱 No Contacts Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Make sure you have contacts with phone numbers in your phone")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredContacts, id: \.identifier) { contact in
                            ContactSelectionRow(contact: contact) {
                                addContact(contact)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search contacts")
                }
            }
            .navigationTitle("Select Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAllContacts()
        }
    }
    
    private func loadAllContacts() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let store = CNContactStore()
            let request = CNContactFetchRequest(keysToFetch: [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ])
            
            var contacts: [CNContact] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    // Only include contacts that have phone numbers
                    if !contact.phoneNumbers.isEmpty {
                        contacts.append(contact)
                    }
                }
                
                DispatchQueue.main.async {
                    self.allContacts = contacts.sorted { 
                        "\($0.givenName) \($0.familyName)" < "\($1.givenName) \($1.familyName)" 
                    }
                    self.isLoading = false
                    print("📱 Loaded \(contacts.count) contacts with phone numbers")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ Error loading contacts: \(error)")
                }
            }
        }
    }
    
    private func addContact(_ contact: CNContact) {
        print("📱 Adding contact: \(contact.givenName) \(contact.familyName)")
        contactHelper.addContact(contact)
        dismiss()
    }
}

struct ContactSelectionRow: View {
    let contact: CNContact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(contact.givenName) \(contact.familyName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
        .buttonStyle(PlainButtonStyle())
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
