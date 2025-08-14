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
        NavigationView {
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
            .navigationBarItems(
                trailing: Button(action: { showingSortOptions = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                }
            )
            .actionSheet(isPresented: $showingSortOptions) {
                ActionSheet(
                    title: Text("Sort Campsites"),
                    buttons: SortOption.allCases.map { option in
                        .default(Text(option.rawValue)) {
                            sortOption = option
                        }
                    } + [.cancel()]
                )
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
                    
                    Text(campsite.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
}

#Preview {
    CampsiteListView(campsiteManager: CampsiteManager())
}
