import SwiftUI

struct ProfileView: View {
    @State private var userName = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var medicalConditions = ""
    @State private var allergies = ""
    @State private var medications = ""
    @State private var bloodType = "Unknown"
    @State private var emergencyNotes = ""
    
    let bloodTypes = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        Form {
            // Personal Information Section
            Section("👤 Personal Information") {
                TextField("Your name (for emergency services)", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Emergency contact name", text: $emergencyContactName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Emergency contact phone", text: $emergencyContactPhone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            // Medical Information Section
            Section("🏥 Medical Information") {
                Picker("Blood Type", selection: $bloodType) {
                    ForEach(bloodTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                TextField("Medical conditions", text: $medicalConditions)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Allergies", text: $allergies)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Current medications", text: $medications)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Emergency Notes Section
            Section("🚨 Emergency Notes") {
                TextEditor(text: $emergencyNotes)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Save Button
            Section {
                Button("💾 Save Profile") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private func saveProfile() {
        UserDefaults.standard.set(userName, forKey: "UserName")
        UserDefaults.standard.set(emergencyContactName, forKey: "EmergencyContactName")
        UserDefaults.standard.set(emergencyContactPhone, forKey: "EmergencyContactPhone")
        UserDefaults.standard.set(medicalConditions, forKey: "MedicalConditions")
        UserDefaults.standard.set(allergies, forKey: "Allergies")
        UserDefaults.standard.set(medications, forKey: "Medications")
        UserDefaults.standard.set(bloodType, forKey: "BloodType")
        UserDefaults.standard.set(emergencyNotes, forKey: "EmergencyNotes")
    }
    
    private func loadProfile() {
        userName = UserDefaults.standard.string(forKey: "UserName") ?? ""
        emergencyContactName = UserDefaults.standard.string(forKey: "EmergencyContactName") ?? ""
        emergencyContactPhone = UserDefaults.standard.string(forKey: "EmergencyContactPhone") ?? ""
        medicalConditions = UserDefaults.standard.string(forKey: "MedicalConditions") ?? ""
        allergies = UserDefaults.standard.string(forKey: "Allergies") ?? ""
        medications = UserDefaults.standard.string(forKey: "Medications") ?? ""
        bloodType = UserDefaults.standard.string(forKey: "BloodType") ?? "Unknown"
        emergencyNotes = UserDefaults.standard.string(forKey: "EmergencyNotes") ?? ""
    }
}

#Preview {
    ProfileView()
}
