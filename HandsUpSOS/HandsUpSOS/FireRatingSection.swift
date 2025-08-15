import SwiftUI

struct FireRatingSection: View {
    @ObservedObject var stateManager: StateManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("🔥 Fire Rating")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("Moderate")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text("\(stateManager.selectedState) - \(stateManager.fireServiceName)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
