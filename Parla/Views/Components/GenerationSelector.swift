import SwiftUI

// MARK: - Indicador de direccion de traduccion

/// Muestra la direccion actual (origen → destino) con boton de intercambio.
/// Disenado para solo 2 generaciones.
struct DirectionHeader: View {

    let source: Generation
    let target: Generation
    let onSwap: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 0) {
            // Generacion origen
            generationBadge(source)

            Spacer()

            // Boton de intercambio
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    rotation += 180
                }
                onSwap()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .rotationEffect(.degrees(rotation))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Intercambiar direccion")

            Spacer()

            // Generacion destino
            generationBadge(target)
        }
        .padding(.vertical, 4)
    }

    private func generationBadge(_ gen: Generation) -> some View {
        HStack(spacing: 6) {
            Text(gen.emoji)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 1) {
                Text(gen.shortName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(gen.color)

                Text(gen.yearRange)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(gen.color.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    DirectionHeader(source: .newGen, target: .boomer, onSwap: {})
        .padding()
}
