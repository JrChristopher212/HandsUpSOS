import Foundation
import CoreLocation
import SwiftUI

struct Campsite: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: CLLocationCoordinate2D
    var notes: String
    var category: CampsiteCategory
    var rating: Int // 1-5 stars
    var dateAdded: Date
    var photos: [String] // File paths to saved photos
    
    // Phase 2: Enhanced campsite data
    var address: String
    var phoneNumber: String?
    var website: String?
    var cost: String?
    var maxOccupancy: Int?
    var hasWater: Bool
    var hasElectricity: Bool
    var hasToilets: Bool
    var hasShowers: Bool
    var hasFirePit: Bool
    var hasBBQ: Bool
    var hasParking: Bool
    var isAccessible: Bool
    var emergencyContact: String?
    var nearestHospital: String?
    var nearestPolice: String?
    var cellReception: CellReceptionLevel
    var accessibilityNotes: String
    var emergencyNotes: String
    var campingType: CampingType
    var seasonAvailability: [Season]
    
    init(name: String, location: CLLocationCoordinate2D, notes: String = "", category: CampsiteCategory = .bushCamping, rating: Int = 3) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.notes = notes
        self.category = category
        self.rating = max(1, min(5, rating))
        self.dateAdded = Date()
        self.photos = []
        
        // Phase 2: Initialize new fields with defaults
        self.address = ""
        self.phoneNumber = nil
        self.website = nil
        self.cost = nil
        self.maxOccupancy = nil
        self.hasWater = false
        self.hasElectricity = false
        self.hasToilets = false
        self.hasShowers = false
        self.hasFirePit = false
        self.hasBBQ = false
        self.hasParking = false
        self.isAccessible = false
        self.emergencyContact = nil
        self.nearestHospital = nil
        self.nearestPolice = nil
        self.cellReception = .unknown
        self.accessibilityNotes = ""
        self.emergencyNotes = ""
        self.campingType = .tent
        self.seasonAvailability = [.spring, .summer, .autumn, .winter]
    }
    
    // Convenience initializer for Phase 2 with all fields
    init(name: String, location: CLLocationCoordinate2D, address: String, category: CampsiteCategory, notes: String = "", rating: Int = 3, phoneNumber: String? = nil, website: String? = nil, cost: String? = nil, maxOccupancy: Int? = nil, hasWater: Bool = false, hasElectricity: Bool = false, hasToilets: Bool = false, hasShowers: Bool = false, hasFirePit: Bool = false, hasBBQ: Bool = false, hasParking: Bool = false, isAccessible: Bool = false, emergencyContact: String? = nil, nearestHospital: String? = nil, nearestPolice: String? = nil, cellReception: CellReceptionLevel = .unknown, accessibilityNotes: String = "", emergencyNotes: String = "", campingType: CampingType = .tent, seasonAvailability: [Season] = [.spring, .summer, .autumn, .winter]) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.address = address
        self.category = category
        self.notes = notes
        self.rating = max(1, min(5, rating))
        self.dateAdded = Date()
        self.photos = []
        self.phoneNumber = phoneNumber
        self.website = website
        self.cost = cost
        self.maxOccupancy = maxOccupancy
        self.hasWater = hasWater
        self.hasElectricity = hasElectricity
        self.hasToilets = hasToilets
        self.hasShowers = hasShowers
        self.hasFirePit = hasFirePit
        self.hasBBQ = hasBBQ
        self.hasParking = hasParking
        self.isAccessible = isAccessible
        self.emergencyContact = emergencyContact
        self.nearestHospital = nearestHospital
        self.nearestPolice = nearestPolice
        self.cellReception = cellReception
        self.accessibilityNotes = accessibilityNotes
        self.emergencyNotes = emergencyNotes
        self.campingType = campingType
        self.seasonAvailability = seasonAvailability
    }
}

enum CampsiteCategory: String, CaseIterable, Codable {
    case bushCamping = "Bush Camping"
    case caravanPark = "Caravan Park"
    case freeCamping = "Free Camping"
    case nationalPark = "National Park"
    case privateProperty = "Private Property"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .bushCamping: return "🌲"
        case .caravanPark: return "🚐"
        case .freeCamping: return "🏕️"
        case .nationalPark: return "🏞️"
        case .privateProperty: return "🏠"
        case .other: return "📍"
        }
    }
    
    var color: Color {
        switch self {
        case .bushCamping: return .green
        case .caravanPark: return .blue
        case .freeCamping: return .orange
        case .nationalPark: return .purple
        case .privateProperty: return .red
        case .other: return .gray
        }
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Phase 2: New Enums and Extensions

enum CellReceptionLevel: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case none = "No Reception"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .excellent: return "📶"
        case .good: return "📶"
        case .fair: return "📶"
        case .poor: return "📶"
        case .none: return "❌"
        case .unknown: return "❓"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .none: return .gray
        case .unknown: return .gray
        }
    }
}

enum CampingType: String, CaseIterable, Codable {
    case tent = "Tent"
    case caravan = "Caravan"
    case motorhome = "Motorhome"
    case cabin = "Cabin"
    case glamping = "Glamping"
    case hammock = "Hammock"
    case bivvy = "Bivvy"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .tent: return "⛺"
        case .caravan: return "🚐"
        case .motorhome: return "🏠"
        case .cabin: return "🏡"
        case .glamping: return "✨"
        case .hammock: return "🪑"
        case .bivvy: return "🛏️"
        case .other: return "📍"
        }
    }
}

enum Season: String, CaseIterable, Codable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"
    
    var icon: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        }
    }
}
