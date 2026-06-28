import SwiftUI

// MARK: - Colour Palette

extension Color {
    static let flAccent     = Color(red: 0.13, green: 0.69, blue: 0.76)  // teal
    static let flBackground = Color(UIColor.systemGroupedBackground)
    static let flCard       = Color(UIColor.secondarySystemGroupedBackground)
    static let flDanger     = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let flSuccess    = Color(red: 0.22, green: 0.78, blue: 0.50)
    static let flWarning    = Color(red: 1.00, green: 0.65, blue: 0.10)
}

// MARK: - Card modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.flCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

// MARK: - Status colour

extension EventStatus {
    var color: Color {
        switch self {
        case .draft:      return .flWarning
        case .submitted:  return .flAccent
        case .reviewed:   return .flSuccess
        }
    }
    var icon: String {
        switch self {
        case .draft:      return "pencil.circle.fill"
        case .submitted:  return "arrow.up.circle.fill"
        case .reviewed:   return "checkmark.circle.fill"
        }
    }
}

// MARK: - Reusable pill badge

struct PillBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}
