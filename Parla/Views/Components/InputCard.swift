import SwiftUI

// MARK: - Tarjeta de entrada de texto

/// Muestra un TextEditor con placeholder, boton de micro y boton de limpiar.
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
            HStack(spacing: 16) {
                // Boton de micro
                RecordButton(
                    isRecording: viewModel.isRecording,
                    action: { viewModel.toggleRecording() }
                )

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
}
