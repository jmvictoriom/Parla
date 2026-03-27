import SwiftUI

// MARK: - Indicador visual de grabacion con barras animadas

/// Muestra barras verticales que oscilan simulando una forma de onda.
/// Se usa como feedback visual mientras el microfono esta activo.
struct WaveformView: View {

    let isActive: Bool
    let color: Color
    let barCount: Int

    @State private var phases: [CGFloat] = []

    init(isActive: Bool, color: Color = .red, barCount: Int = 24) {
        self.isActive = isActive
        self.color = color
        self.barCount = barCount
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.gradient)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(
                        .easeInOut(duration: randomDuration(for: index))
                            .repeatForever(autoreverses: true),
                        value: isActive
                    )
            }
        }
        .frame(height: 30)
        .onAppear { phases = (0..<barCount).map { _ in CGFloat.random(in: 0.3...1.0) } }
        .onChange(of: isActive) { _, active in
            if active {
                phases = (0..<barCount).map { _ in CGFloat.random(in: 0.3...1.0) }
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard isActive, index < phases.count else { return 4 }
        return phases[index] * 28 + 4
    }

    private func randomDuration(for index: Int) -> Double {
        0.2 + Double(index % 5) * 0.08
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WaveformView(isActive: true, color: .red)
        WaveformView(isActive: false, color: .red)
    }
    .padding()
}
