import SwiftUI

// MARK: - Boton de intercambiar generaciones con rotacion

struct SwapButton: View {

    let action: () -> Void
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                rotation += 180
            }
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .bold))
                    .rotationEffect(.degrees(rotation))

                Text("Intercambiar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.accent.opacity(0.1))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Intercambiar generaciones de origen y destino")
    }
}

// MARK: - Preview

#Preview {
    SwapButton(action: {})
}
