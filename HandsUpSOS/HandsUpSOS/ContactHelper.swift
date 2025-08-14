import Foundation
import Contacts

class ContactHelper: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadContacts()
    }
    
    func addContact(_ contact: CNContact) {
        // Check if contact already exists
        if !contacts.contains(where: { $0.identifier == contact.identifier }) {
            // Verify the contact has a phone number
            if !contact.phoneNumbers.isEmpty {
                DispatchQueue.main.async {
                    self.contacts.append(contact)
                    self.saveContacts()
                    self.errorMessage = nil
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Selected contact has no phone number"
                }
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Contact already in emergency list"
            }
        }
    }
    
    func removeContact(_ contact: CNContact) {
        DispatchQueue.main.async {
            self.contacts.removeAll { $0.identifier == contact.identifier }
            self.saveContacts()
        }
    }
    
    func removeContact(at indexSet: IndexSet) {
        DispatchQueue.main.async {
            self.contacts.remove(atOffsets: indexSet)
            self.saveContacts()
        }
    }
    
    func clearAllContacts() {
        DispatchQueue.main.async {
            self.contacts.removeAll()
            self.saveContacts()
        }
    }
    
    func getPhoneNumbers() -> [String] {
        return contacts.compactMap { contact in
            contact.phoneNumbers.first?.value.stringValue
        }
    }
    
    private func saveContacts() {
        let identifiers = contacts.map { $0.identifier }
        UserDefaults.standard.set(identifiers, forKey: "EmergencyContactIdentifiers")
        print("Saved \(identifiers.count) emergency contact identifiers")
    }
    
    private func loadContacts() {
        guard let identifiers = UserDefaults.standard.array(forKey: "EmergencyContactIdentifiers") as? [String],
              !identifiers.isEmpty else {
            print("No emergency contact identifiers found")
            return
        }
        
        isLoading = true
        
        let store = CNContactStore()
        let request = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ])
        
        // Clear existing contacts before loading
        DispatchQueue.main.async {
            self.contacts.removeAll()
        }
        
        do {
            try store.enumerateContacts(with: request) { contact, stop in
                if identifiers.contains(contact.identifier) {
                    DispatchQueue.main.async {
                        self.contacts.append(contact)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                print("Loaded \(self.contacts.count) emergency contacts")
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error loading contacts: \(error.localizedDescription)"
                print("Error loading contacts: \(error)")
            }
        }
    }
    
    func refreshContacts() {
        loadContacts()
    }
}
