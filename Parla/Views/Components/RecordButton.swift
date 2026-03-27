import SwiftUI

// MARK: - Boton de grabacion con animacion de pulso

struct RecordButton: View {

    let isRecording: Bool
    let action: () -> Void

    @State private var pulsate = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Halo pulsante cuando esta grabando
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulsate ? 1.3 : 1.0)
                        .opacity(pulsate ? 0 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: pulsate
                        )
                }

                Circle()
                    .fill(isRecording ? Color.red : AppTheme.accent)
                    .frame(width: 34, height: 34)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .onChange(of: isRecording) { _, recording in
            pulsate = recording
        }
        .accessibilityLabel(isRecording ? "Detener grabacion" : "Grabar voz")
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 32) {
        RecordButton(isRecording: false, action: {})
        RecordButton(isRecording: true, action: {})
    }
    .padding()
}
