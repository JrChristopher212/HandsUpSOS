import SwiftUI

struct FireRatingSection: View {
    @ObservedObject var warningService: EmergencyWarningService
    @ObservedObject var stateManager: StateManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("🔥 Fire Rating")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if let highestRating = warningService.getHighestFireDangerRating() {
                    HStack(spacing: 4) {
                        Text(highestRating.rating.emoji)
                            .font(.title3)
                        Text(highestRating.rating.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(highestRating.rating.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(highestRating.rating.color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("\(stateManager.selectedState) - \(stateManager.fireServiceName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !warningService.getTotalFireBans().isEmpty {
                    Text("🚫 Total Fire Ban")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            // Show current fire danger ratings for nearby regions
            if !warningService.fireDangerRatings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Regional Ratings:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    ForEach(warningService.fireDangerRatings.prefix(3)) { rating in
                        HStack {
                            Text(rating.rating.emoji)
                                .font(.caption)
                            Text(rating.region)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(rating.rating.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(rating.rating.color)
                            
                            if rating.isTotalFireBan {
                                Text("🚫")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
