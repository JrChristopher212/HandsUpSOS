import SwiftUI
import CoreLocation

struct NearbyResourcesSection: View {
    @ObservedObject var campsiteManager: CampsiteManager
    @ObservedObject var locationHelper: LocationHelper
    
    private var nearbyCampsites: [Campsite] {
        // Get campsites within 50km of current location
        guard locationHelper.hasPermission else { return [] }
        
        return campsiteManager.campsites.filter { campsite in
            guard let currentLocation = locationHelper.currentLocation else { return false }
            let distance = calculateDistance(
                from: currentLocation.coordinate,
                to: campsite.location
            )
            return distance <= 50.0 // Within 50km
        }
        .sorted { $0.rating > $1.rating } // Sort by rating
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("🏕️ Nearby Emergency Resources")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if nearbyCampsites.isEmpty {
                Text("No campsites found nearby. Enable location services to see nearby resources.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(nearbyCampsites.prefix(3)) { campsite in
                    HStack {
                        Text(campsite.category.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(campsite.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(campsite.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= campsite.rating ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Text("📶 \(campsite.cellReception.rawValue)")
                                .font(.caption2)
                                .foregroundColor(campsite.cellReception.color)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to kilometers
    }
}
