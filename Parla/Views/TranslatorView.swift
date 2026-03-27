import SwiftUI

// MARK: - Vista principal del traductor

struct TranslatorView: View {

    @StateObject private var viewModel = TranslatorViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                header
                DirectionHeader(
                    source: viewModel.sourceGeneration,
                    target: viewModel.targetGeneration,
                    onSwap: { viewModel.swapGenerations() }
                )
                InputCard(viewModel: viewModel)

                exaggerationSelector

                if viewModel.isRecording {
                    WaveformView(isActive: true, color: .red)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                OutputCard(viewModel: viewModel)

                ExampleBanner(
                    examples: TranslationExample.samples,
                    sourceGeneration: viewModel.sourceGeneration,
                    targetGeneration: viewModel.targetGeneration,
                    onSelect: { viewModel.loadExample($0) }
                )
                .padding(.top, 2)

                footer
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.default, value: viewModel.isRecording)
        .onChange(of: viewModel.inputText) {
            viewModel.inputDidChange()
        }
        .onChange(of: viewModel.sourceGeneration) {
            viewModel.translateLocally()
        }
        .onChange(of: viewModel.targetGeneration) {
            viewModel.translateLocally()
        }
        .background {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea(.all)
        }
    }

    // MARK: - Subvistas

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)

            Text("Parla")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            Text("Traductor generacional")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var exaggerationSelector: some View {
        HStack(spacing: 6) {
            ForEach(ExaggerationLevel.allCases) { level in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.exaggerationLevel = level
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(level.emoji)
                            .font(.caption2)
                        Text(level.rawValue)
                            .font(.caption)
                            .fontWeight(viewModel.exaggerationLevel == level ? .bold : .regular)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.exaggerationLevel == level
                            ? AppTheme.accent.opacity(0.15)
                            : Color.clear
                    )
                    .foregroundStyle(
                        viewModel.exaggerationLevel == level
                            ? AppTheme.accent
                            : AppTheme.secondaryText
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                viewModel.exaggerationLevel == level
                                    ? AppTheme.accent.opacity(0.3)
                                    : AppTheme.secondaryText.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var footer: some View {
        Text("\(viewModel.conceptCount) conceptos")
            .font(.caption2)
            .foregroundStyle(AppTheme.secondaryText)
            .padding(.top, 2)
    }
}

#Preview {
    TranslatorView()
        .preferredColorScheme(.light)
}
