import Foundation
import CoreLocation
import SwiftUI

// MARK: - Emergency Warning Models
struct EmergencyWarning: Identifiable, Codable {
    let id: UUID
    let type: WarningType
    let severity: WarningSeverity
    let title: String
    let description: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let issuedDate: Date
    let expiresDate: Date?
    let source: String
    
    var coordinates: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
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
        
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .severe: return .red
            case .critical: return .purple
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
        
        do {
            // Fetch weather warnings from BOM
            let weatherWarnings = try await fetchBOMWeatherWarnings()
            
            // Fetch fire warnings from state services (placeholder for now)
            let fireWarnings = try await fetchStateFireWarnings()
            
            // Combine all warnings
            activeWarnings = weatherWarnings + fireWarnings
            
            isLoading = false
            lastUpdated = Date()
            errorMessage = nil
            
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch warnings: \(error.localizedDescription)"
            print("❌ Error fetching warnings: \(error)")
        }
    }
    
    // MARK: - Mock Data (Temporary for testing)
    
    private func loadMockWarnings() {
        let mockWarnings = [
            EmergencyWarning(
                id: UUID(),
                type: .fire,
                severity: .critical,
                title: "Bushfire Warning - Blue Mountains",
                description: "Extreme fire danger in Blue Mountains National Park. Evacuate immediately if in affected areas.",
                location: "Blue Mountains, NSW",
                latitude: -33.7128,
                longitude: 150.3119,
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
                source: "NSW Rural Fire Service"
            ),
            EmergencyWarning(
                id: UUID(),
                type: .severeWeather,
                severity: .high,
                title: "Severe Storm Warning - Sydney Region",
                description: "Heavy rainfall, damaging winds, and large hail expected across Sydney metropolitan area.",
                location: "Sydney Region, NSW",
                latitude: -33.8688,
                longitude: 151.2093,
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
                source: "Bureau of Meteorology"
            ),
            EmergencyWarning(
                id: UUID(),
                type: .heatwave,
                severity: .moderate,
                title: "Heatwave Warning - Victoria",
                description: "Extended period of hot weather expected across Victoria with temperatures above 35°C.",
                location: "Victoria",
                latitude: -37.8136,
                longitude: 144.9631,
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
    
    // MARK: - BOM API Integration
    
    private func fetchBOMWeatherWarnings() async throws -> [EmergencyWarning] {
        // BOM API endpoint for warnings
        let baseURL = "https://www.bom.gov.au/fwo/IDZ00054.warnings_ww.xml"
        
        guard let url = URL(string: baseURL) else {
            throw WarningError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WarningError.networkError
        }
        
        // Parse XML response (simplified for now)
        return try parseBOMWarnings(from: data)
    }
    
    private func parseBOMWarnings(from data: Data) throws -> [EmergencyWarning] {
        // For now, return a sample warning to test the flow
        // TODO: Implement proper XML parsing
        let sampleWarning = EmergencyWarning(
            id: UUID(),
            type: .severeWeather,
            severity: .high,
            title: "Severe Weather Warning - BOM Data",
            description: "Real-time weather warning from Bureau of Meteorology",
            location: "Victoria",
            latitude: -37.8136,
            longitude: 144.9631,
            issuedDate: Date(),
            expiresDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            source: "Bureau of Meteorology"
        )
        
        return [sampleWarning]
    }
    
    private func fetchStateFireWarnings() async throws -> [EmergencyWarning] {
        // Placeholder for state fire service APIs
        // TODO: Implement actual state fire service calls
        return []
    }
}

// MARK: - Error Types

enum WarningError: Error, LocalizedError {
    case invalidURL
    case networkError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for warning service"
        case .networkError:
            return "Network error while fetching warnings"
        case .parsingError:
            return "Error parsing warning data"
        }
    }
}

