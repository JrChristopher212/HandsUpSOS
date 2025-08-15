import Foundation
import CoreLocation
import SwiftUI

// MARK: - Emergency Warning Models
struct EmergencyWarning: Identifiable, Codable {
    let id = UUID()
    let type: WarningType
    let severity: WarningSeverity
    let title: String
    let description: String
    let location: String
    let coordinates: CLLocationCoordinate2D?
    let issuedDate: Date
    let expiresDate: Date?
    let source: String
    
    enum WarningType: String, CaseIterable, Codable {
        case fire = "Fire"
        case severeWeather = "Severe Weather"
        case flood = "Flood"
        case storm = "Storm"
        case heatwave = "Heatwave"
        case medical = "Medical Emergency"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .fire: return "🔥"
            case .severeWeather: return "⛈️"
            case .flood: return "🌊"
            case .storm: return "🌩️"
            case .heatwave: return "🌡️"
            case .medical: return "🚨"
            case .other: return "⚠️"
            }
        }
        
        var color: Color {
            switch self {
            case .fire: return .red
            case .severeWeather: return .orange
            case .flood: return .blue
            case .storm: return .purple
            case .heatwave: return .orange
            case .medical: return .red
            case .other: return .yellow
            }
        }
    }
    
    enum WarningSeverity: String, CaseIterable, Codable, Comparable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case severe = "Severe"
        case critical = "Critical"
        
        var priority: Int {
            switch self {
            case .low: return 1
            case .moderate: return 2
            case .high: return 3
            case .severe: return 4
            case .critical: return 5
            }
        }
        
        static func < (lhs: WarningSeverity, rhs: WarningSeverity) -> Bool {
            return lhs.priority < rhs.priority
        }
    }
}

// MARK: - Emergency Warning Service
class EmergencyWarningService: ObservableObject {
    @Published var activeWarnings: [EmergencyWarning] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private var updateTimer: Timer?
    
    init() {
        startPeriodicUpdates()
        loadMockWarnings() // Temporary for testing
    }
    
    deinit {
        stopPeriodicUpdates()
    }
    
    // MARK: - Public Methods
    
    func refreshWarnings() {
        Task {
            await fetchEmergencyWarnings()
        }
    }
    
    func getWarningsForLocation(_ location: CLLocationCoordinate2D) -> [EmergencyWarning] {
        // Filter warnings by proximity to user location
        return activeWarnings.filter { warning in
            guard let warningCoords = warning.coordinates else { return true }
            let distance = calculateDistance(from: location, to: warningCoords)
            return distance <= 100.0 // Within 100km
        }
    }
    
    func getCriticalWarnings() -> [EmergencyWarning] {
        return activeWarnings.filter { $0.severity >= .severe }
    }
    
    // MARK: - Private Methods
    
    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.refreshWarnings()
        }
    }
    
    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @MainActor
    private func fetchEmergencyWarnings() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual API calls to emergency warning services
        // For now, we'll use mock data
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        isLoading = false
        lastUpdated = Date()
    }
    
    // MARK: - Mock Data (Temporary for testing)
    
    private func loadMockWarnings() {
        let mockWarnings = [
            EmergencyWarning(
                type: .fire,
                severity: .critical,
                title: "Bushfire Warning - Blue Mountains",
                description: "Extreme fire danger in Blue Mountains National Park. Evacuate immediately if in affected areas.",
                location: "Blue Mountains, NSW",
                coordinates: CLLocationCoordinate2D(latitude: -33.7128, longitude: 150.3119),
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
                source: "NSW Rural Fire Service"
            ),
            EmergencyWarning(
                type: .severeWeather,
                severity: .high,
                title: "Severe Storm Warning - Sydney Region",
                description: "Heavy rainfall, damaging winds, and large hail expected across Sydney metropolitan area.",
                location: "Sydney Region, NSW",
                coordinates: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
                source: "Bureau of Meteorology"
            ),
            EmergencyWarning(
                type: .heatwave,
                severity: .moderate,
                title: "Heatwave Warning - Victoria",
                description: "Extended period of hot weather expected across Victoria with temperatures above 35°C.",
                location: "Victoria",
                coordinates: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631),
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                source: "Bureau of Meteorology"
            )
        ]
        
        activeWarnings = mockWarnings
        lastUpdated = Date()
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to kilometers
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
