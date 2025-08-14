import Foundation
import CoreLocation

// MARK: - Campsite Data Utilities for Phase 2

struct CampsiteDataUtilities {
    
    // MARK: - Data Validation
    
    static func validateCampsiteData(_ campsite: Campsite) -> [String] {
        var errors: [String] = []
        
        if campsite.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Campsite name is required")
        }
        
        if campsite.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Address is required")
        }
        
        if campsite.rating < 1 || campsite.rating > 5 {
            errors.append("Rating must be between 1 and 5")
        }
        
        if campsite.maxOccupancy != nil && campsite.maxOccupancy! < 1 {
            errors.append("Maximum occupancy must be at least 1")
        }
        
        return errors
    }
    
    // MARK: - Data Formatting
    
    static func formatDistance(from coordinate: CLLocationCoordinate2D, to campsite: Campsite) -> String {
        let distance = calculateDistance(from: coordinate, to: campsite.location)
        
        if distance < 1 {
            return "\(Int(distance * 1000))m away"
        } else if distance < 10 {
            return String(format: "%.1fkm away", distance)
        } else {
            return String(format: "%.0fkm away", distance)
        }
    }
    
    static func formatAmenities(_ campsite: Campsite) -> [String] {
        var amenities: [String] = []
        
        if campsite.hasWater { amenities.append("💧 Water") }
        if campsite.hasElectricity { amenities.append("⚡ Electricity") }
        if campsite.hasToilets { amenities.append("🚽 Toilets") }
        if campsite.hasShowers { amenities.append("🚿 Showers") }
        if campsite.hasFirePit { amenities.append("🔥 Fire Pit") }
        if campsite.hasBBQ { amenities.append("🍖 BBQ") }
        if campsite.hasParking { amenities.append("🅿️ Parking") }
        
        return amenities
    }
    
    static func formatAccessibilityInfo(_ campsite: Campsite) -> String {
        if campsite.isAccessible {
            return "♿ Wheelchair Accessible"
        } else {
            return "⚠️ Not wheelchair accessible"
        }
    }
    
    static func formatEmergencyInfo(_ campsite: Campsite) -> [String] {
        var emergencyInfo: [String] = []
        
        if let emergencyContact = campsite.emergencyContact {
            emergencyInfo.append("🚨 Emergency: \(emergencyContact)")
        }
        
        if let nearestHospital = campsite.nearestHospital {
            emergencyInfo.append("🏥 Hospital: \(nearestHospital)")
        }
        
        if let nearestPolice = campsite.nearestPolice {
            emergencyInfo.append("👮 Police: \(nearestPolice)")
        }
        
        if !campsite.emergencyNotes.isEmpty {
            emergencyInfo.append("📝 Notes: \(campsite.emergencyNotes)")
        }
        
        return emergencyInfo
    }
    
    static func formatSeasonAvailability(_ campsite: Campsite) -> String {
        let seasons = campsite.seasonAvailability.map { $0.rawValue }.joined(separator: ", ")
        return "📅 Available: \(seasons)"
    }
    
    // MARK: - Search and Filter Helpers
    
    static func getSearchSuggestions(from campsites: [Campsite]) -> [String] {
        var suggestions: Set<String> = []
        
        for campsite in campsites {
            suggestions.insert(campsite.name)
            suggestions.insert(campsite.category.rawValue)
            suggestions.insert(campsite.campingType.rawValue)
            
            // Add location-based suggestions
            let components = campsite.address.components(separatedBy: ",")
            for component in components {
                let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 2 {
                    suggestions.insert(trimmed)
                }
            }
        }
        
        return Array(suggestions).sorted()
    }
    
    static func getFilterOptions(from campsites: [Campsite]) -> CampsiteFilterOptions {
        var options = CampsiteFilterOptions()
        
        for campsite in campsites {
            // Categories
            options.availableCategories.insert(campsite.category)
            
            // Camping types
            options.availableCampingTypes.insert(campsite.campingType)
            
            // Seasons
            options.availableSeasons.formUnion(campsite.seasonAvailability)
            
            // Amenities
            if campsite.hasWater { options.availableAmenities.insert(.water) }
            if campsite.hasElectricity { options.availableAmenities.insert(.electricity) }
            if campsite.hasToilets { options.availableAmenities.insert(.toilets) }
            if campsite.hasShowers { options.availableAmenities.insert(.showers) }
            if campsite.hasFirePit { options.availableAmenities.insert(.firePit) }
            if campsite.hasBBQ { options.availableAmenities.insert(.bbq) }
            if campsite.hasParking { options.availableAmenities.insert(.parking) }
            
            // Cell reception
            options.availableCellReception.insert(campsite.cellReception)
            
            // Accessibility
            if campsite.isAccessible {
                options.hasAccessibleCampsites = true
            }
        }
        
        return options
    }
    
    // MARK: - Private Methods
    
    private static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to kilometers
    }
}

// MARK: - Supporting Structures

struct CampsiteFilterOptions {
    var availableCategories: Set<CampsiteCategory> = []
    var availableCampingTypes: Set<CampingType> = []
    var availableSeasons: Set<Season> = []
    var availableAmenities: Set<AmenityType> = []
    var availableCellReception: Set<CellReceptionLevel> = []
    var hasAccessibleCampsites: Bool = false
}

enum AmenityType: String, CaseIterable {
    case water = "Water"
    case electricity = "Electricity"
    case toilets = "Toilets"
    case showers = "Showers"
    case firePit = "Fire Pit"
    case bbq = "BBQ"
    case parking = "Parking"
    
    var icon: String {
        switch self {
        case .water: return "💧"
        case .electricity: return "⚡"
        case .toilets: return "🚽"
        case .showers: return "🚿"
        case .firePit: return "🔥"
        case .bbq: return "🍖"
        case .parking: return "🅿️"
        }
    }
}
