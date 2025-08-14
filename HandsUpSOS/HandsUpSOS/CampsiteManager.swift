import Foundation
import CoreLocation

class CampsiteManager: ObservableObject {
    @Published var campsites: [Campsite] = []
    
    private let userDefaults = UserDefaults.standard
    private let campsitesKey = "SavedCampsites"
    
    init() {
        loadCampsites()
    }
    
    // MARK: - CRUD Operations
    
    func addCampsite(_ campsite: Campsite) {
        campsites.append(campsite)
        saveCampsites()
    }
    
    func updateCampsite(_ campsite: Campsite) {
        if let index = campsites.firstIndex(where: { $0.id == campsite.id }) {
            campsites[index] = campsite
            saveCampsites()
        }
    }
    
    func deleteCampsite(_ campsite: Campsite) {
        campsites.removeAll { $0.id == campsite.id }
        saveCampsites()
    }
    
    func deleteCampsite(at indexSet: IndexSet) {
        campsites.remove(atOffsets: indexSet)
        saveCampsites()
    }
    
    // MARK: - Search and Filter
    
    func searchCampsites(query: String) -> [Campsite] {
        if query.isEmpty {
            return campsites
        }
        
        return campsites.filter { campsite in
            campsite.name.localizedCaseInsensitiveContains(query) ||
            campsite.notes.localizedCaseInsensitiveContains(query) ||
            campsite.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterCampsites(by category: CampsiteCategory?) -> [Campsite] {
        guard let category = category else { return campsites }
        return campsites.filter { $0.category == category }
    }
    
    func getCampsitesNearby(coordinate: CLLocationCoordinate2D, radius: Double = 50.0) -> [Campsite] {
        return campsites.filter { campsite in
            let distance = calculateDistance(from: coordinate, to: campsite.location)
            return distance <= radius
        }
    }
    
    // MARK: - Private Methods
    
    private func saveCampsites() {
        if let encoded = try? JSONEncoder().encode(campsites) {
            userDefaults.set(encoded, forKey: campsitesKey)
        }
    }
    
    private func loadCampsites() {
        if let data = userDefaults.data(forKey: campsitesKey),
           let decoded = try? JSONDecoder().decode([Campsite].self, from: data) {
            campsites = decoded
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to kilometers
    }
}
