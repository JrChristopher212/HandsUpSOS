import Foundation
import CoreLocation

struct EmergencyMessageBuilder {
    static func createMessage(template: EmergencyTemplate, userName: String, location: String, campsiteManager: CampsiteManager? = nil, userLocation: CLLocationCoordinate2D? = nil) -> String {
        let name = userName.isEmpty ? "Emergency Contact" : userName
        
        // Get nearby campsite emergency info if available
        var campsiteEmergencyInfo = ""
        if let campsiteManager = campsiteManager, let userLocation = userLocation {
            if let nearestCampsite = campsiteManager.getNearestCampsiteWithEmergencyInfo(coordinate: userLocation) {
                campsiteEmergencyInfo = buildCampsiteEmergencySection(nearestCampsite)
            }
        }
        
        let message = """
        🚨 EMERGENCY SOS 🚨
        
        \(template.emoji) \(template.title)
        \(template.message)
        
        Person: \(name)
        Location: \(location)
        Time: \(formatCurrentTime())
        \(campsiteEmergencyInfo)
        
        This is an automated emergency message from HandsUpSOS app.
        Please call emergency services (000) immediately.
        
        If you receive this message, please:
        1. Call 000 for emergency services
        2. Provide the location coordinates above
        3. Contact the person if possible
        """
        
        return message
    }
    
    private static func buildCampsiteEmergencySection(_ campsite: Campsite) -> String {
        var section = "\n🏕️ NEARBY CAMPSITE EMERGENCY INFO:\n"
        section += "Campsite: \(campsite.name)\n"
        section += "Address: \(campsite.address)\n"
        
        if let emergencyContact = campsite.emergencyContact {
            section += "Emergency Contact: \(emergencyContact)\n"
        }
        
        if let nearestHospital = campsite.nearestHospital {
            section += "Nearest Hospital: \(nearestHospital)\n"
        }
        
        if let nearestPolice = campsite.nearestPolice {
            section += "Nearest Police: \(nearestPolice)\n"
        }
        
        // Add available amenities
        var amenities: [String] = []
        if campsite.hasWater { amenities.append("Water") }
        if campsite.hasElectricity { amenities.append("Electricity") }
        if campsite.hasToilets { amenities.append("Toilets") }
        if campsite.hasShowers { amenities.append("Showers") }
        if campsite.hasFirePit { amenities.append("Fire Pit") }
        if campsite.hasBBQ { amenities.append("BBQ") }
        if campsite.hasParking { amenities.append("Parking") }
        
        if !amenities.isEmpty {
            section += "Available Amenities: \(amenities.joined(separator: ", "))\n"
        }
        
        if !campsite.emergencyNotes.isEmpty {
            section += "Emergency Notes: \(campsite.emergencyNotes)\n"
        }
        
        return section
    }
    
    private static func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "en_AU")
        return formatter.string(from: Date())
    }
}
