import SwiftUI

// MARK: - Tema visual centralizado

enum AppTheme {

    // MARK: Colores

    static let background       = Color(.systemGroupedBackground)
    static let cardBackground   = Color.white
    static let primaryText      = Color(.label)
    static let secondaryText    = Color(.secondaryLabel)
    static let accent           = Color.indigo

    // MARK: Espaciado y radios

    static let cardPadding:  CGFloat = 14
    static let cornerRadius: CGFloat = 18
    static let spacing:      CGFloat = 10

    // MARK: Sombras

    static let shadowColor:  Color   = .black.opacity(0.06)
    static let shadowRadius: CGFloat = 10
    static let shadowY:      CGFloat = 4
}

// MARK: - Modificador reutilizable para tarjetas

struct CardModifier: ViewModifier {
    var color: Color = AppTheme.cardBackground

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: AppTheme.shadowColor,
                    radius: AppTheme.shadowRadius,
                    y: AppTheme.shadowY)
    }
}

extension View {
    func cardStyle(color: Color = AppTheme.cardBackground) -> some View {
        modifier(CardModifier(color: color))
    }
}
