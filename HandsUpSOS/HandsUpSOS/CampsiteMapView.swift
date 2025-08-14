import SwiftUI
import MapKit

struct CampsiteMapView: View {
    @ObservedObject var campsiteManager: CampsiteManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631), // Melbourne
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var showingAddCampsite = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var selectedCategory: CampsiteCategory?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: campsiteManager.campsites) { campsite in
                    MapAnnotation(coordinate: campsite.location) {
                        CampsiteAnnotationView(campsite: campsite)
                            .onTapGesture {
                                // Handle tap on annotation
                            }
                    }
                }
                .onTapGesture { location in
                    // Handle map tap to add pin
                    handleMapTap(at: location)
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Search and Filter Controls
                VStack {
                    HStack {
                        TextField("Search campsites...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("Filter") {
                            // Show filter options
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Add Campsite Button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingAddCampsite = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Campsites")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddCampsite) {
                AddCampsiteView(
                    campsiteManager: campsiteManager,
                    location: selectedLocation ?? region.center
                )
            }
        }
    }
    
    private func handleMapTap(at location: CGPoint) {
        // Convert screen coordinates to map coordinates
        // This is a simplified version - in a real app you'd use MKMapView's convert method
        selectedLocation = region.center
        showingAddCampsite = true
    }
}

struct CampsiteAnnotationView: View {
    let campsite: Campsite
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(campsite.category.color)
            
            Text(campsite.name)
                .font(.caption)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
}

struct AddCampsiteView: View {
    @ObservedObject var campsiteManager: CampsiteManager
    let location: CLLocationCoordinate2D
    
    @State private var name = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var category: CampsiteCategory = .bushCamping
    @State private var rating = 3
    
    // Phase 2: Enhanced fields
    @State private var phoneNumber = ""
    @State private var website = ""
    @State private var cost = ""
    @State private var maxOccupancy = ""
    @State private var hasWater = false
    @State private var hasElectricity = false
    @State private var hasToilets = false
    @State private var hasShowers = false
    @State private var hasFirePit = false
    @State private var hasBBQ = false
    @State private var hasParking = false
    @State private var isAccessible = false
    @State private var emergencyContact = ""
    @State private var nearestHospital = ""
    @State private var nearestPolice = ""
    @State private var cellReception: CellReceptionLevel = .unknown
    @State private var accessibilityNotes = ""
    @State private var emergencyNotes = ""
    @State private var campingType: CampingType = .tent
    @State private var selectedSeasons: Set<Season> = [.spring, .summer, .autumn, .winter]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section("📍 Basic Information") {
                    TextField("Campsite Name *", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Address *", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Category", selection: $category) {
                        ForEach(CampsiteCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    HStack {
                        Text("Rating:")
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                // Contact & Cost Section
                Section("📞 Contact & Cost") {
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    TextField("Website", text: $website)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Cost (e.g., Free, $20/night)", text: $cost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Max Occupancy", text: $maxOccupancy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // Amenities Section
                Section("🏕️ Amenities") {
                    Toggle("💧 Water", isOn: $hasWater)
                    Toggle("⚡ Electricity", isOn: $hasElectricity)
                    Toggle("🚽 Toilets", isOn: $hasToilets)
                    Toggle("🚿 Showers", isOn: $hasShowers)
                    Toggle("🔥 Fire Pit", isOn: $hasFirePit)
                    Toggle("🍖 BBQ", isOn: $hasBBQ)
                    Toggle("🅿️ Parking", isOn: $hasParking)
                }
                
                // Accessibility Section
                Section("♿ Accessibility") {
                    Toggle("Wheelchair Accessible", isOn: $isAccessible)
                    
                    if isAccessible {
                        TextField("Accessibility Notes", text: $accessibilityNotes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Emergency Information Section
                Section("🚨 Emergency Information") {
                    TextField("Emergency Contact", text: $emergencyContact)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Nearest Hospital", text: $nearestHospital)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Nearest Police Station", text: $nearestPolice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Emergency Notes", text: $emergencyNotes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Camping Details Section
                Section("⛺ Camping Details") {
                    Picker("Camping Type", selection: $campingType) {
                        ForEach(CampingType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    Picker("Cell Reception", selection: $cellReception) {
                        ForEach(CellReceptionLevel.allCases, id: \.self) { level in
                            HStack {
                                Text(level.icon)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seasonal Availability:")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(Season.allCases, id: \.self) { season in
                                Button(action: {
                                    if selectedSeasons.contains(season) {
                                        selectedSeasons.remove(season)
                                    } else {
                                        selectedSeasons.insert(season)
                                    }
                                }) {
                                    HStack {
                                        Text(season.icon)
                                        Text(season.rawValue)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedSeasons.contains(season) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedSeasons.contains(season) ? .white : .primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Notes Section
                Section("📝 Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Location Section
                Section("📍 Location") {
                    Text("Latitude: \(location.latitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Longitude: \(location.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Campsite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCampsite()
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
        }
    }
    
    private func saveCampsite() {
        let campsite = Campsite(
            name: name,
            location: location,
            address: address,
            category: category,
            notes: notes,
            rating: rating,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            website: website.isEmpty ? nil : website,
            cost: cost.isEmpty ? nil : cost,
            maxOccupancy: Int(maxOccupancy),
            hasWater: hasWater,
            hasElectricity: hasElectricity,
            hasToilets: hasToilets,
            hasShowers: hasShowers,
            hasFirePit: hasFirePit,
            hasBBQ: hasBBQ,
            hasParking: hasParking,
            isAccessible: isAccessible,
            emergencyContact: emergencyContact.isEmpty ? nil : emergencyContact,
            nearestHospital: nearestHospital.isEmpty ? nil : nearestHospital,
            nearestPolice: nearestPolice.isEmpty ? nil : nearestPolice,
            cellReception: cellReception,
            accessibilityNotes: accessibilityNotes,
            emergencyNotes: emergencyNotes,
            campingType: campingType,
            seasonAvailability: Array(selectedSeasons)
        )
        
        campsiteManager.addCampsite(campsite)
        dismiss()
    }
}

#Preview {
    CampsiteMapView(campsiteManager: CampsiteManager())
}
