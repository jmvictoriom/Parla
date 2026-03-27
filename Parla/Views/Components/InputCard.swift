import SwiftUI

// MARK: - Tarjeta de entrada de texto

/// Muestra un TextEditor con placeholder, boton de micro, boton de traducir IA y boton de limpiar.
struct InputCard: View {

    @ObservedObject var viewModel: TranslatorViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera: generacion origen + contador de caracteres
            HStack {
                Label(viewModel.sourceGeneration.rawValue, systemImage: "text.bubble")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.sourceGeneration.color)

                Spacer()

                if !viewModel.inputText.isEmpty {
                    Text("\(viewModel.inputText.count)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.bottom, 4)

            // Area de texto
            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text(viewModel.placeholderExample)
                        .foregroundStyle(Color(.placeholderText))
                        .font(.callout)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $viewModel.inputText)
                    .font(.callout)
                    .frame(minHeight: 44, maxHeight: 100)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
            }

            Divider()
                .padding(.vertical, 6)

            // Barra de acciones
            HStack(spacing: 12) {
                // Boton de micro
                RecordButton(
                    isRecording: viewModel.isRecording,
                    action: { viewModel.toggleRecording() }
                )

                // Boton traducir con IA
                if viewModel.geminiAvailable && !viewModel.inputText.isEmpty {
                    Button {
                        isFocused = false
                        viewModel.translateWithAI()
                    } label: {
                        HStack(spacing: 5) {
                            if viewModel.isTranslating {
                                ProgressView()
                                    .controlSize(.mini)
                            } else if viewModel.isCooldown {
                                cooldownIndicator
                            } else {
                                Image(systemName: "brain")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text(viewModel.isTranslating ? "Traduciendo..." : viewModel.isCooldown ? "\(Int(viewModel.cooldownRemaining.rounded(.up)))s" : "Traducir IA")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            viewModel.isCooldown || viewModel.isTranslating
                                ? AppTheme.secondaryText.opacity(0.1)
                                : AppTheme.accent.opacity(0.12)
                        )
                        .foregroundStyle(
                            viewModel.isCooldown || viewModel.isTranslating
                                ? AppTheme.secondaryText
                                : AppTheme.accent
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.isCooldown || viewModel.isTranslating)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isCooldown)
                }

                Spacer()

                // Boton limpiar
                if !viewModel.inputText.isEmpty {
                    Button {
                        withAnimation { viewModel.clearInput() }
                        isFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .cardStyle()
        .onTapGesture { isFocused = true }
        .alert("Permisos necesarios",
               isPresented: $viewModel.showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Activa el microfono y el reconocimiento de voz en Ajustes para usar esta funcion.")
        }
    }

    // MARK: - Cooldown indicator

    private var cooldownIndicator: some View {
        Circle()
            .trim(from: 0, to: viewModel.cooldownRemaining / 3.0)
            .stroke(AppTheme.secondaryText, lineWidth: 2)
            .frame(width: 12, height: 12)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 0.1), value: viewModel.cooldownRemaining)
    }
}
