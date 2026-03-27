import SwiftUI

// MARK: - Tarjeta de resultado de la traduccion

struct OutputCard: View {

    @ObservedObject var viewModel: TranslatorViewModel

    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera: generacion destino + indicador IA
            HStack {
                Label(viewModel.targetGeneration.rawValue, systemImage: "text.bubble.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.targetGeneration.color)

                Spacer()

                // Indicador de fuente de traduccion
                if !viewModel.translatedText.isEmpty {
                    if viewModel.isAITranslation {
                        Label("IA", systemImage: "brain")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accent.opacity(0.7))
                            .transition(.opacity)
                    } else {
                        Label("Local", systemImage: "book.closed")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                            .transition(.opacity)
                    }
                }
            }
            .padding(.bottom, 4)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isTranslating)

            // Texto traducido
            Group {
                if viewModel.translatedText.isEmpty {
                    Text("La traduccion aparecera aqui...")
                        .foregroundStyle(Color(.placeholderText))
                } else {
                    Text(viewModel.translatedText)
                        .foregroundStyle(AppTheme.primaryText)
                        .textSelection(.enabled)
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)

            Divider()
                .padding(.vertical, 6)

            // Barra de acciones
            HStack(spacing: 16) {
                Button {
                    viewModel.toggleSpeaking()
                } label: {
                    Label(
                        viewModel.isSpeaking ? "Parar" : "Escuchar",
                        systemImage: viewModel.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.targetGeneration.color)
                }
                .disabled(viewModel.translatedText.isEmpty)

                Spacer()

                if !viewModel.translatedText.isEmpty {
                    Button {
                        UIPasteboard.general.string = viewModel.translatedText
                        withAnimation { showCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showCopied = false }
                        }
                    } label: {
                        Label(
                            showCopied ? "Copiado" : "Copiar",
                            systemImage: showCopied ? "checkmark.circle.fill" : "doc.on.doc"
                        )
                        .font(.subheadline)
                        .foregroundStyle(showCopied ? .green : AppTheme.secondaryText)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .cardStyle(color: viewModel.targetGeneration.color.opacity(0.04))
    }
}
