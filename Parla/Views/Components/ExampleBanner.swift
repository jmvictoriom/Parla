import SwiftUI

// MARK: - Carrusel de ejemplos de traduccion

/// Muestra tarjetas deslizables con frases de ejemplo traducidas
/// entre generaciones. Al pulsar una, se carga en el traductor.
struct ExampleBanner: View {

    let examples: [TranslationExample]
    let sourceGeneration: Generation
    let targetGeneration: Generation
    let onSelect: (TranslationExample) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.accent)
                Text("Prueba un ejemplo")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(examples) { example in
                        ExampleCard(
                            example: example,
                            sourceGeneration: sourceGeneration,
                            targetGeneration: targetGeneration
                        )
                        .onTapGesture { onSelect(example) }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Tarjeta individual de ejemplo

private struct ExampleCard: View {

    let example: TranslationExample
    let sourceGeneration: Generation
    let targetGeneration: Generation

    /// Texto a mostrar: intenta la generacion origen, si no la primera disponible.
    private var displayText: String {
        example.sentences[sourceGeneration]
            ?? example.sentences.values.first
            ?? ""
    }

    private var targetText: String {
        example.sentences[targetGeneration]
            ?? example.sentences.values.dropFirst().first
            ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Frase origen
            HStack(spacing: 4) {
                Text(sourceGeneration.emoji)
                    .font(.caption)
                Text(displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
            }

            // Flecha
            Image(systemName: "arrow.down")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            // Frase destino
            HStack(spacing: 4) {
                Text(targetGeneration.emoji)
                    .font(.caption)
                Text(targetText)
                    .font(.caption)
                    .foregroundStyle(targetGeneration.color)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 240)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.shadowColor, radius: 6, y: 3)
    }
}
