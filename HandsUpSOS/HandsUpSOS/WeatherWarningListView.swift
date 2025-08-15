import SwiftUI

struct WeatherWarningListView: View {
    let warnings: [EmergencyWarning]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(warnings.prefix(2).enumerated()), id: \.offset) { _, warning in
                HStack {
                    Text(warning.type.icon)
                    Text(warning.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    Spacer()
                    Text(warning.severity.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(warning.severity.color.opacity(0.2))
                        .foregroundColor(warning.severity.color)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}
