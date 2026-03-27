import SwiftUI

// MARK: - Splash animada

struct SplashView: View {

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var finished = false

    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Icono
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)
                    .scaleEffect(showIcon ? 1.0 : 0.3)
                    .opacity(showIcon ? 1 : 0)

                // Titulo
                Text("Parla")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 10)

                // Subtitulo
                Text("Traductor generacional")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 8)

                // Badges de generaciones
                HStack(spacing: 20) {
                    generationPill(emoji: "⚡", name: "Nuevas gen.", color: .purple)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    generationPill(emoji: "📰", name: "Boomer", color: .orange)
                }
                .opacity(showSubtitle ? 1 : 0)
                .scaleEffect(showSubtitle ? 1 : 0.8)
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
                showSubtitle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    finished = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onFinish()
                }
            }
        }
        .opacity(finished ? 0 : 1)
        .scaleEffect(finished ? 1.1 : 1.0)
    }

    private func generationPill(emoji: String, name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(emoji).font(.caption)
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    SplashView(onFinish: {})
}
