import Foundation

struct EmergencyMessageBuilder {
    static func createMessage(template: EmergencyTemplate, userName: String, location: String) -> String {
        let name = userName.isEmpty ? "Emergency Contact" : userName
        
        let message = """
        🚨 EMERGENCY SOS 🚨
        
        \(template.emoji) \(template.title)
        \(template.message)
        
        Person: \(name)
        Location: \(location)
        Time: \(formatCurrentTime())
        
        This is an automated emergency message from HandsUpSOS app.
        Please call emergency services (000) immediately.
        
        If you receive this message, please:
        1. Call 000 for emergency services
        2. Provide the location coordinates above
        3. Contact the person if possible
        """
        
        return message
    }
    
    private static func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "en_AU")
        return formatter.string(from: Date())
    }
}
