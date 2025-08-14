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
        NavigationView {
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
    @State private var notes = ""
    @State private var category: CampsiteCategory = .bushCamping
    @State private var rating = 3
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Campsite Details") {
                    TextField("Campsite Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(CampsiteCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    Stepper("Rating: \(rating) stars", value: $rating, in: 1...5)
                    
                    HStack {
                        Text("Rating:")
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section("Location") {
                    Text("Latitude: \(location.latitude, specifier: "%.6f")")
                    Text("Longitude: \(location.longitude, specifier: "%.6f")")
                }
            }
            .navigationTitle("Add Campsite")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveCampsite()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveCampsite() {
        let campsite = Campsite(
            name: name,
            location: location,
            notes: notes,
            category: category,
            rating: rating
        )
        
        campsiteManager.addCampsite(campsite)
        dismiss()
    }
}

#Preview {
    CampsiteMapView(campsiteManager: CampsiteManager())
}
