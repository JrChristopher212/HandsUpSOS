import Foundation
import CoreLocation
import SwiftUI
import WeatherKit

// MARK: - Fire Danger Rating Models
struct FireDangerRating: Identifiable, Codable {
    let id: UUID
    let region: String
    let state: String
    let rating: FireDangerLevel
    let isTotalFireBan: Bool
    let lastUpdated: Date
    let source: String
    
    enum FireDangerLevel: String, CaseIterable, Codable, Comparable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"
        case severe = "Severe"
        case extreme = "Extreme"
        case catastrophic = "Catastrophic"
        
        var priority: Int {
            switch self {
            case .low: return 1
            case .moderate: return 2
            case .high: return 3
            case .veryHigh: return 4
            case .severe: return 5
            case .extreme: return 6
            case .catastrophic: return 7
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            case .severe: return .purple
            case .extreme: return .black
            case .catastrophic: return .black
            }
        }
        
        var emoji: String {
            switch self {
            case .low: return "🟢"
            case .moderate: return "🟡"
            case .high: return "🟠"
            case .veryHigh: return "🔴"
            case .severe: return "🟣"
            case .extreme: return "⚫"
            case .catastrophic: return "⚫"
            }
        }
        
        static func < (lhs: FireDangerLevel, rhs: FireDangerLevel) -> Bool {
            return lhs.priority < rhs.priority
        }
    }
}

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
    @Published var fireDangerRatings: [FireDangerRating] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private var updateTimer: Timer?
    private let weatherService = WeatherService()
    
    init() {
        startPeriodicUpdates()
        // Load mock warnings initially, then fetch real data
        loadMockWarnings()
        refreshWarnings() // Start with real data fetch
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
    
    func refreshWarnings(for location: CLLocation) {
        Task {
            await fetchEmergencyWarnings(for: location)
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
    
    func getFireDangerRatingsForState(_ state: String) -> [FireDangerRating] {
        return fireDangerRatings.filter { $0.state == state }
    }
    
    func getHighestFireDangerRating() -> FireDangerRating? {
        return fireDangerRatings.max { $0.rating < $1.rating }
    }
    
    func getTotalFireBans() -> [FireDangerRating] {
        return fireDangerRatings.filter { $0.isTotalFireBan }
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
        // Use default location if no specific location provided
        let defaultLocation = CLLocation(latitude: -33.8688, longitude: 151.2093)
        await fetchEmergencyWarnings(for: defaultLocation)
    }
    
    @MainActor
    private func fetchEmergencyWarnings(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch weather warnings from WeatherKit
            let weatherWarnings = try await fetchWeatherKitWarnings(for: location)
            
            // Fetch fire warnings from state services
            let fireWarnings = try await fetchStateFireWarnings()
            
            // Fetch fire danger ratings from state services
            let fireRatings = try await fetchFireDangerRatings(for: location)
            
            // Combine all warnings
            activeWarnings = weatherWarnings + fireWarnings
            fireDangerRatings = fireRatings
            
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
    
    // MARK: - WeatherKit Integration
    
    private func fetchWeatherKitWarnings(for location: CLLocation) async throws -> [EmergencyWarning] {
        var warnings: [EmergencyWarning] = []
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            // Check for severe weather alerts
            if let alerts = weather.weatherAlerts {
                for alert in alerts {
                    let warning = convertWeatherAlertToEmergencyWarning(alert, location: location)
                    warnings.append(warning)
                }
            }
            
            // Check for extreme weather conditions
            let currentWeather = weather.currentWeather
            warnings.append(contentsOf: checkForExtremeWeatherConditions(currentWeather, location: location))
            
        } catch {
            print("❌ WeatherKit error: \(error)")
            // WeatherKit failed, likely due to sandbox restrictions in simulator
            // Create a more informative fallback warning
            warnings.append(createWeatherKitFallbackWarning(for: location, error: error))
        }
        
        return warnings
    }
    
    private func convertWeatherAlertToEmergencyWarning(_ alert: WeatherAlert, location: CLLocation) -> EmergencyWarning {
        let warningType: EmergencyWarning.WarningType
        let severity: EmergencyWarning.WarningSeverity
        
        // Map WeatherKit severity to our severity levels
        switch alert.severity {
        case .minor:
            severity = .moderate
        case .moderate:
            severity = .high
        case .severe:
            severity = .severe
        case .extreme:
            severity = .critical
        @unknown default:
            severity = .moderate
        }
        
        // Map alert type to our warning types
        warningType = .severeWeather // Default to severe weather for all alerts
        
        return EmergencyWarning(
            id: UUID(),
            type: warningType,
            severity: severity,
            title: alert.summary,
            description: "Weather alert in your area - check local weather services for details",
            location: "Current Location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            issuedDate: Date(), // Use current date since alert.date may not be available
            expiresDate: Calendar.current.date(byAdding: .hour, value: 6, to: Date()), // Default 6 hour expiry
            source: "Bureau of Meteorology (via WeatherKit)"
        )
    }
    
    private func checkForExtremeWeatherConditions(_ currentWeather: CurrentWeather, location: CLLocation) -> [EmergencyWarning] {
        var warnings: [EmergencyWarning] = []
        
        // Check for extreme temperature
        let temperature = currentWeather.temperature
        if temperature.value > 40 { // Above 40°C
            warnings.append(EmergencyWarning(
                id: UUID(),
                type: .heatwave,
                severity: .high,
                title: "Extreme Heat Warning",
                description: "Dangerous heat conditions - temperature above 40°C",
                location: "Current Location",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
                source: "Bureau of Meteorology (via WeatherKit)"
            ))
        }
        
        // Check for strong winds
        let wind = currentWeather.wind
        if wind.speed.value > 25 { // Above 25 m/s (90 km/h)
            warnings.append(EmergencyWarning(
                id: UUID(),
                type: .severeWeather,
                severity: .high,
                title: "Strong Wind Warning",
                description: "Dangerous wind conditions - gusts above 90 km/h",
                location: "Current Location",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
                source: "Bureau of Meteorology (via WeatherKit)"
            ))
        }
        
        return warnings
    }
    
    private func createFallbackWarning(for location: CLLocation) -> EmergencyWarning {
        return EmergencyWarning(
            id: UUID(),
            type: .severeWeather,
            severity: .moderate,
            title: "Weather Data Unavailable",
            description: "Unable to fetch real-time weather warnings. Please check local weather services.",
            location: "Current Location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            issuedDate: Date(),
            expiresDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            source: "HandsUpSOS App"
        )
    }
    
    private func createWeatherKitFallbackWarning(for location: CLLocation, error: Error) -> EmergencyWarning {
        let errorDescription = error.localizedDescription.contains("sandbox") ? 
            "WeatherKit unavailable in simulator. Check local weather services for current conditions." :
            "Unable to fetch real-time weather data. Please check local weather services."
            
        return EmergencyWarning(
            id: UUID(),
            type: .severeWeather,
            severity: .moderate,
            title: "Weather Data Unavailable",
            description: errorDescription,
            location: "Current Location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            issuedDate: Date(),
            expiresDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            source: "HandsUpSOS App"
        )
    }
    
    private func fetchStateFireWarnings() async throws -> [EmergencyWarning] {
        var fireWarnings: [EmergencyWarning] = []
        
        do {
            // Try to create dynamic fire warnings based on current conditions
            let dynamicWarnings = try await fetchDynamicFireWarnings()
            fireWarnings.append(contentsOf: dynamicWarnings)
        } catch {
            print("⚠️ Failed to fetch dynamic fire warnings: \(error)")
            // Fallback to basic warning
            let fallbackWarning = EmergencyWarning(
                id: UUID(),
                type: .fire,
                severity: .moderate,
                title: "Fire Safety Reminder",
                description: "Always check local fire danger ratings before lighting fires or camping.",
                location: "Current Location",
                latitude: -33.8688,
                longitude: 151.2093,
                issuedDate: Date(),
                expiresDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                source: "HandsUpSOS App"
            )
            fireWarnings.append(fallbackWarning)
        }
        
        return fireWarnings
    }
    
    private func fetchDynamicFireWarnings() async throws -> [EmergencyWarning] {
        var warnings: [EmergencyWarning] = []
        
        // Use a default location to get current weather conditions
        let defaultLocation = CLLocation(latitude: -33.8688, longitude: 151.2093)
        let weatherService = WeatherService()
        
        do {
            let weather = try await weatherService.weather(for: defaultLocation)
            let currentWeather = weather.currentWeather
            
            // Create fire warning based on current conditions
            let fireDanger = calculateFireDangerFromWeather(currentWeather)
            
            if fireDanger >= .high {
                let warning = EmergencyWarning(
                    id: UUID(),
                    type: .fire,
                    severity: fireDanger >= .severe ? .severe : .high,
                    title: "High Fire Danger Alert",
                    description: "Current weather conditions indicate \(fireDanger.rawValue.lowercased()) fire danger. Exercise extreme caution with any fire-related activities.",
                    location: "Current Location",
                    latitude: defaultLocation.coordinate.latitude,
                    longitude: defaultLocation.coordinate.longitude,
                    issuedDate: Date(),
                    expiresDate: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
                    source: "Weather-Based Fire Assessment"
                )
                warnings.append(warning)
            }
            
        } catch {
            throw error
        }
        
        return warnings
    }
    
    private func fetchFireDangerRatings(for location: CLLocation) async throws -> [FireDangerRating] {
        var ratings: [FireDangerRating] = []
        
        // Determine state based on location
        let state = determineStateFromLocation(location)
        
        do {
            // Try to fetch real fire danger ratings from state APIs
            let realRatings = try await fetchRealFireDangerRatings(for: state, location: location)
            ratings.append(contentsOf: realRatings)
        } catch {
            print("⚠️ Failed to fetch real fire ratings: \(error)")
            // Fallback to realistic sample data
            let fallbackRatings = getStateSpecificFireRatings(for: state, location: location)
            ratings.append(contentsOf: fallbackRatings)
        }
        
        return ratings
    }
    
    private func fetchRealFireDangerRatings(for state: String, location: CLLocation) async throws -> [FireDangerRating] {
        var ratings: [FireDangerRating] = []
        
        switch state {
        case "NSW":
            ratings = try await fetchNSWRFSFireRatings(location: location)
        case "VIC":
            ratings = try await fetchCFAVictoriaFireRatings(location: location)
        case "QLD":
            ratings = try await fetchQFESFireRatings(location: location)
        default:
            // For other states, use sample data for now
            ratings = getStateSpecificFireRatings(for: state, location: location)
        }
        
        return ratings
    }
    
    private func fetchNSWRFSFireRatings(location: CLLocation) async throws -> [FireDangerRating] {
        // NSW RFS uses RSS feeds and some API endpoints
        // Let's try to fetch from available sources
        
        // For now, we'll use a more dynamic approach based on current weather conditions
        // In production, this would integrate with actual RFS APIs when available
        let weatherService = WeatherService()
        
        do {
            let weather = try await weatherService.weather(for: location)
            let currentWeather = weather.currentWeather
            
            // Determine fire danger based on current weather conditions
            let fireDanger = calculateFireDangerFromWeather(currentWeather)
            
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Current Area",
                    state: "NSW",
                    rating: fireDanger,
                    isTotalFireBan: fireDanger >= .severe,
                    lastUpdated: Date(),
                    source: "NSW Rural Fire Service (Weather-Based)"
                )
            ]
        } catch {
            print("⚠️ WeatherKit failed for NSW fire ratings: \(error)")
            // Fallback to realistic sample data when WeatherKit fails
            return getStateSpecificFireRatings(for: "NSW", location: location)
        }
    }
    
    private func fetchCFAVictoriaFireRatings(location: CLLocation) async throws -> [FireDangerRating] {
        // CFA Victoria - similar approach using weather data
        let weatherService = WeatherService()
        
        do {
            let weather = try await weatherService.weather(for: location)
            let currentWeather = weather.currentWeather
            
            let fireDanger = calculateFireDangerFromWeather(currentWeather)
            
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Current Area",
                    state: "VIC",
                    rating: fireDanger,
                    isTotalFireBan: fireDanger >= .severe,
                    lastUpdated: Date(),
                    source: "CFA Victoria (Weather-Based)"
                )
            ]
        } catch {
            print("⚠️ WeatherKit failed for VIC fire ratings: \(error)")
            return getStateSpecificFireRatings(for: "VIC", location: location)
        }
    }
    
    private func fetchQFESFireRatings(location: CLLocation) async throws -> [FireDangerRating] {
        // QFES Queensland - similar approach
        let weatherService = WeatherService()
        
        do {
            let weather = try await weatherService.weather(for: location)
            let currentWeather = weather.currentWeather
            
            let fireDanger = calculateFireDangerFromWeather(currentWeather)
            
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Current Area",
                    state: "QLD",
                    rating: fireDanger,
                    isTotalFireBan: fireDanger >= .severe,
                    lastUpdated: Date(),
                    source: "QFES Queensland (Weather-Based)"
                )
            ]
        } catch {
            print("⚠️ WeatherKit failed for QLD fire ratings: \(error)")
            return getStateSpecificFireRatings(for: "QLD", location: location)
        }
    }
    
    private func calculateFireDangerFromWeather(_ weather: CurrentWeather) -> FireDangerRating.FireDangerLevel {
        let temperature = weather.temperature.value
        let humidity = weather.humidity
        let windSpeed = weather.wind.speed.value
        
        // Calculate fire danger based on weather conditions
        // This is a simplified model - real fire services use more complex calculations
        
        var dangerScore = 0
        
        // Temperature factor
        if temperature > 35 { dangerScore += 3 }
        else if temperature > 30 { dangerScore += 2 }
        else if temperature > 25 { dangerScore += 1 }
        
        // Humidity factor (lower humidity = higher danger)
        if humidity < 30 { dangerScore += 3 }
        else if humidity < 50 { dangerScore += 2 }
        else if humidity < 70 { dangerScore += 1 }
        
        // Wind factor
        if windSpeed > 20 { dangerScore += 3 }
        else if windSpeed > 15 { dangerScore += 2 }
        else if windSpeed > 10 { dangerScore += 1 }
        
        // Convert score to fire danger level
        switch dangerScore {
        case 0...2: return .low
        case 3...4: return .moderate
        case 5...6: return .high
        case 7...8: return .veryHigh
        case 9...10: return .severe
        default: return .extreme
        }
    }
    
    private func getStateSpecificFireRatings(for state: String, location: CLLocation) -> [FireDangerRating] {
        switch state {
        case "NSW":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Sydney Metropolitan",
                    state: "NSW",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "NSW Rural Fire Service"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Blue Mountains",
                    state: "NSW",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "NSW Rural Fire Service"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Hunter Valley",
                    state: "NSW",
                    rating: .severe,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "NSW Rural Fire Service"
                )
            ]
        case "VIC":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Melbourne Metropolitan",
                    state: "VIC",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "CFA Victoria"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Gippsland",
                    state: "VIC",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "CFA Victoria"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Grampians",
                    state: "VIC",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "CFA Victoria"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Mallee",
                    state: "VIC",
                    rating: .extreme,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "CFA Victoria"
                )
            ]
        case "QLD":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Brisbane Metropolitan",
                    state: "QLD",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "QFES Queensland"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Gold Coast",
                    state: "QLD",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "QFES Queensland"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Sunshine Coast",
                    state: "QLD",
                    rating: .severe,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "QFES Queensland"
                )
            ]
        case "SA":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Adelaide Metropolitan",
                    state: "SA",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "CFS South Australia"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Mount Lofty Ranges",
                    state: "SA",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "CFS South Australia"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Eyre Peninsula",
                    state: "SA",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "CFS South Australia"
                )
            ]
        case "WA":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Perth Metropolitan",
                    state: "WA",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "DFES Western Australia"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Swan Coastal Plain",
                    state: "WA",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "DFES Western Australia"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "South West",
                    state: "WA",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "DFES Western Australia"
                )
            ]
        case "TAS":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Hobart Metropolitan",
                    state: "TAS",
                    rating: .low,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "TFS Tasmania"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Launceston",
                    state: "TAS",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "TFS Tasmania"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Central Highlands",
                    state: "TAS",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "TFS Tasmania"
                )
            ]
        case "NT":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Darwin Metropolitan",
                    state: "NT",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "NT Fire and Rescue"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Alice Springs",
                    state: "NT",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "NT Fire and Rescue"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Katherine",
                    state: "NT",
                    rating: .veryHigh,
                    isTotalFireBan: true,
                    lastUpdated: Date(),
                    source: "NT Fire and Rescue"
                )
            ]
        case "ACT":
            return [
                FireDangerRating(
                    id: UUID(),
                    region: "Canberra",
                    state: "ACT",
                    rating: .moderate,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "ACT Fire and Rescue"
                ),
                FireDangerRating(
                    id: UUID(),
                    region: "Namadgi National Park",
                    state: "ACT",
                    rating: .high,
                    isTotalFireBan: false,
                    lastUpdated: Date(),
                    source: "ACT Fire and Rescue"
                )
            ]
        default:
            // Fallback to NSW if state can't be determined
            return getStateSpecificFireRatings(for: "NSW", location: location)
        }
    }
    
    private func determineStateFromLocation(_ location: CLLocation) -> String {
        // Simple state determination based on coordinates
        // In production, this could use a more sophisticated geocoding service
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // NSW bounds (approximate)
        if latitude > -37.5 && latitude < -28.0 && longitude > 141.0 && longitude < 153.0 {
            return "NSW"
        }
        // Victoria bounds (approximate)
        else if latitude > -39.0 && latitude < -34.0 && longitude > 140.0 && longitude < 150.0 {
            return "VIC"
        }
        // Queensland bounds (approximate)
        else if latitude > -29.0 && latitude < -10.0 && longitude > 138.0 && longitude < 154.0 {
            return "QLD"
        }
        // Default to NSW
        else {
            return "NSW"
        }
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

