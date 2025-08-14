import SwiftUI

struct CampsiteListView: View {
    @ObservedObject var campsiteManager: CampsiteManager
    @State private var searchText = ""
    @State private var selectedCategory: CampsiteCategory?
    @State private var showingSortOptions = false
    @State private var sortOption: SortOption = .dateAdded
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Date Added"
        case rating = "Rating"
        case category = "Category"
    }
    
    var filteredCampsites: [Campsite] {
        var campsites = campsiteManager.campsites
        
        // Apply search filter
        if !searchText.isEmpty {
            campsites = campsiteManager.searchCampsites(query: searchText)
        }
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            campsites = campsiteManager.filterCampsites(by: selectedCategory)
        }
        
        // Apply sorting
        switch sortOption {
        case .name:
            campsites.sort { $0.name < $1.name }
        case .dateAdded:
            campsites.sort { $0.dateAdded > $1.dateAdded }
        case .rating:
            campsites.sort { $0.rating > $1.rating }
        case .category:
            campsites.sort { $0.category.rawValue < $1.category.rawValue }
        }
        
        return campsites
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search and Filter Bar
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search campsites...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Category Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryFilterPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(CampsiteCategory.allCases, id: \.self) { category in
                                CategoryFilterPill(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    color: category.color,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                // Campsite List
                if filteredCampsites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No campsites found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        if searchText.isEmpty && selectedCategory == nil {
                            Text("Tap the + button on the map to add your first campsite!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Try adjusting your search or filters")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCampsites) { campsite in
                            CampsiteRowView(campsite: campsite)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        campsiteManager.deleteCampsite(campsite)
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("My Campsites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSortOptions = true }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .confirmationDialog("Sort Campsites", isPresented: $showingSortOptions) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            }
        }
    }
}

struct CategoryFilterPill: View {
    let title: String
    var icon: String = ""
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if !icon.isEmpty {
                    Text(icon)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct CampsiteRowView: View {
    let campsite: Campsite
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(campsite.category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(campsite.name)
                        .font(.headline)
                    
                    HStack {
                        Text(campsite.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !campsite.address.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(campsite.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
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
                    
                    Text(campsite.dateAdded, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Phase 2: Amenities display
            if hasAnyAmenities {
                HStack(spacing: 12) {
                    ForEach(getAmenityIcons(), id: \.self) { icon in
                        Text(icon)
                            .font(.caption)
                    }
                }
                .padding(.leading, 4)
            }
            
            // Phase 2: Accessibility and emergency info
            HStack {
                if campsite.isAccessible {
                    Text("♿ Accessible")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if campsite.emergencyContact != nil || campsite.nearestHospital != nil {
                    Text("🚨 Emergency Info")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text("📶 \(campsite.cellReception.rawValue)")
                    .font(.caption2)
                    .foregroundColor(campsite.cellReception.color)
            }
            
            if !campsite.notes.isEmpty {
                Text(campsite.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("📍 \(campsite.location.latitude, specifier: "%.4f"), \(campsite.location.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Added \(campsite.dateAdded, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper computed properties
    private var hasAnyAmenities: Bool {
        campsite.hasWater || campsite.hasElectricity || campsite.hasToilets || 
        campsite.hasShowers || campsite.hasFirePit || campsite.hasBBQ || campsite.hasParking
    }
    
    private func getAmenityIcons() -> [String] {
        var icons: [String] = []
        
        if campsite.hasWater { icons.append("💧") }
        if campsite.hasElectricity { icons.append("⚡") }
        if campsite.hasToilets { icons.append("🚽") }
        if campsite.hasShowers { icons.append("🚿") }
        if campsite.hasFirePit { icons.append("🔥") }
        if campsite.hasBBQ { icons.append("🍖") }
        if campsite.hasParking { icons.append("🅿️") }
        
        return icons
    }
}

#Preview {
    CampsiteListView(campsiteManager: CampsiteManager())
}
