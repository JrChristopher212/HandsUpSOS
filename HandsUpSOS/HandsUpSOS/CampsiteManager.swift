import Foundation
import CoreLocation

class CampsiteManager: ObservableObject {
    @Published var campsites: [Campsite] = []
    
    private let userDefaults = UserDefaults.standard
    private let campsitesKey = "SavedCampsites"
    
    init() {
        loadCampsites()
        // Phase 2: Add sample data if no campsites exist
        // Temporarily disabled to prevent crash - will re-enable after testing
        // if campsites.isEmpty {
        //     addSampleCampsites()
        // }
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
            campsite.category.rawValue.localizedCaseInsensitiveContains(query) ||
            campsite.address.localizedCaseInsensitiveContains(query)
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
    
    // Phase 2: Enhanced filtering methods
    
    func filterCampsitesByAmenities(hasWater: Bool? = nil, hasElectricity: Bool? = nil, hasToilets: Bool? = nil, hasShowers: Bool? = nil, hasFirePit: Bool? = nil, hasBBQ: Bool? = nil, hasParking: Bool? = nil) -> [Campsite] {
        return campsites.filter { campsite in
            var matches = true
            
            if let hasWater = hasWater {
                matches = matches && campsite.hasWater == hasWater
            }
            if let hasElectricity = hasElectricity {
                matches = matches && campsite.hasElectricity == hasElectricity
            }
            if let hasToilets = hasToilets {
                matches = matches && campsite.hasToilets == hasToilets
            }
            if let hasShowers = hasShowers {
                matches = matches && campsite.hasShowers == hasShowers
            }
            if let hasFirePit = hasFirePit {
                matches = matches && campsite.hasFirePit == hasFirePit
            }
            if let hasBBQ = hasBBQ {
                matches = matches && campsite.hasBBQ == hasBBQ
            }
            if let hasParking = hasParking {
                matches = matches && campsite.hasParking == hasParking
            }
            
            return matches
        }
    }
    
    func filterCampsitesByAccessibility(isAccessible: Bool) -> [Campsite] {
        return campsites.filter { $0.isAccessible == isAccessible }
    }
    
    func filterCampsitesByCellReception(_ level: CellReceptionLevel) -> [Campsite] {
        return campsites.filter { $0.cellReception == level }
    }
    
    func filterCampsitesByCampingType(_ type: CampingType) -> [Campsite] {
        return campsites.filter { $0.campingType == type }
    }
    
    func filterCampsitesBySeason(_ season: Season) -> [Campsite] {
        return campsites.filter { $0.seasonAvailability.contains(season) }
    }
    
    func filterCampsitesByCost(maxCost: String? = nil, isFree: Bool? = nil) -> [Campsite] {
        if let isFree = isFree {
            if isFree {
                return campsites.filter { $0.cost == "Free" || $0.cost == nil }
            } else {
                return campsites.filter { $0.cost != "Free" && $0.cost != nil }
            }
        }
        
        // For now, return all campsites if no cost filter specified
        // This could be enhanced with actual cost parsing logic
        return campsites
    }
    
    func getCampsitesWithEmergencyInfo() -> [Campsite] {
        return campsites.filter { campsite in
            campsite.emergencyContact != nil || 
            campsite.nearestHospital != nil || 
            campsite.nearestPolice != nil ||
            !campsite.emergencyNotes.isEmpty
        }
    }
    
    func getCampsitesByAccessibilityFeatures() -> [Campsite] {
        return campsites.filter { $0.isAccessible == true }
    }
    
    // MARK: - Phase 2: Sample Data
    
    private func addSampleCampsites() {
        let sampleCampsites = [
            Campsite(
                name: "Blue Mountains Bush Camp",
                location: CLLocationCoordinate2D(latitude: -33.7128, longitude: 150.3119),
                address: "Blue Mountains National Park, NSW",
                category: .bushCamping,
                notes: "Beautiful bush camping with stunning mountain views",
                rating: 4,
                hasWater: true,
                hasToilets: true,
                hasFirePit: true,
                hasParking: true,
                isAccessible: false,
                emergencyContact: "Blue Mountains Police: 02 4782 8199",
                nearestHospital: "Blue Mountains District ANZAC Memorial Hospital",
                cellReception: .good,
                accessibilityNotes: "Not wheelchair accessible, steep terrain",
                emergencyNotes: "Emergency services accessible via main road",
                campingType: .tent,
                seasonAvailability: [.spring, .summer, .autumn]
            ),
            
            Campsite(
                name: "Jervis Bay Caravan Park",
                location: CLLocationCoordinate2D(latitude: -35.0748, longitude: 150.6681),
                address: "Jervis Bay, NSW",
                category: .caravanPark,
                notes: "Family-friendly caravan park near beautiful beaches",
                rating: 5,
                hasWater: true,
                hasElectricity: true,
                hasToilets: true,
                hasShowers: true,
                hasFirePit: false,
                hasBBQ: true,
                hasParking: true,
                isAccessible: true,
                emergencyContact: "Jervis Bay Police: 02 4441 9400",
                nearestHospital: "Shoalhaven District Memorial Hospital",
                cellReception: .excellent,
                accessibilityNotes: "Wheelchair accessible facilities, accessible toilets and showers",
                emergencyNotes: "24/7 on-site staff, emergency phone available",
                campingType: .caravan,
                seasonAvailability: [.spring, .summer, .autumn, .winter]
            ),
            
            Campsite(
                name: "Kosciuszko Alpine Camp",
                location: CLLocationCoordinate2D(latitude: -36.4500, longitude: 148.2633),
                address: "Kosciuszko National Park, NSW",
                category: .nationalPark,
                notes: "High altitude camping with spectacular alpine views",
                rating: 4,
                hasWater: true,
                hasToilets: true,
                hasFirePit: false,
                hasParking: true,
                isAccessible: false,
                emergencyContact: "Kosciuszko Police: 02 6456 2044",
                nearestHospital: "Cooma Hospital",
                cellReception: .poor,
                accessibilityNotes: "High altitude, not suitable for those with respiratory conditions",
                emergencyNotes: "Weather dependent access, check conditions before travel",
                campingType: .tent,
                seasonAvailability: [.summer, .autumn]
            )
        ]
        
        for campsite in sampleCampsites {
            addCampsite(campsite)
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
