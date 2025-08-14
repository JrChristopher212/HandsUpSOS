import Foundation
import CoreLocation
import SwiftUI

struct Campsite: Identifiable, Codable {
    let id = UUID()
    var name: String
    var location: CLLocationCoordinate2D
    var notes: String
    var category: CampsiteCategory
    var rating: Int // 1-5 stars
    var dateAdded: Date
    var photos: [String] // File paths to saved photos
    
    init(name: String, location: CLLocationCoordinate2D, notes: String = "", category: CampsiteCategory = .bushCamping, rating: Int = 3) {
        self.name = name
        self.location = location
        self.notes = notes
        self.category = category
        self.rating = max(1, min(5, rating))
        self.dateAdded = Date()
        self.photos = []
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
