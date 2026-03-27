import Combine
import SwiftUI

// MARK: - ViewModel principal del traductor

@MainActor
final class TranslatorViewModel: ObservableObject {

    // MARK: Estado de la UI

    @Published var sourceGeneration: Generation = .boomer
    @Published var targetGeneration: Generation = .newGen
    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var isRecording: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var isTranslating: Bool = false
    @Published var geminiAvailable: Bool = false
    @Published var showPermissionAlert: Bool = false
    @Published var placeholderExample: String = "Bro, literal eso fue cringe..."
    @Published var exaggerationLevel: ExaggerationLevel = .normal
    @Published var isAITranslation: Bool = false
    @Published var isCooldown: Bool = false
    @Published var cooldownRemaining: Double = 0

    // MARK: Dependencias

    private let engine = TranslationEngine()
    private let speech = SpeechService()
    private var cancellables = Set<AnyCancellable>()
    private var translationTask: Task<Void, Never>?
    private var speakingMonitorCancellable: AnyCancellable?
    private var recordingTimeoutTask: Task<Void, Never>?
    private var cooldownTask: Task<Void, Never>?

    private let cooldownDuration: Double = 3.0

    // MARK: Ciclo de vida

    init() {
        checkGeminiAvailability()
    }

    // MARK: - Traduccion local (en tiempo real mientras escribe)

    func translateLocally() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            isAITranslation = false
            return
        }

        translatedText = engine.translateLocal(trimmed, from: sourceGeneration, to: targetGeneration)
        isAITranslation = false
    }

    // MARK: - Traduccion con IA (boton explicito)

    func translateWithAI() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard geminiAvailable, !isCooldown else { return }

        translationTask?.cancel()
        isTranslating = true

        translationTask = Task { @MainActor in
            do {
                let aiResult = try await engine.translateWithAI(
                    trimmed, from: sourceGeneration, to: targetGeneration,
                    exaggeration: exaggerationLevel
                )
                guard !Task.isCancelled else {
                    isTranslating = false
                    return
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    if !aiResult.isEmpty {
                        translatedText = aiResult
                        isAITranslation = true
                    }
                    isTranslating = false
                }
            } catch {
                guard !Task.isCancelled else {
                    isTranslating = false
                    return
                }
                withAnimation {
                    isTranslating = false
                }
            }

            // Iniciar cooldown de 3s
            startCooldown()
        }
    }

    // MARK: - Cooldown

    private func startCooldown() {
        cooldownTask?.cancel()
        isCooldown = true
        cooldownRemaining = cooldownDuration

        cooldownTask = Task { @MainActor in
            let steps = 30 // actualizar cada 100ms
            let stepDuration = cooldownDuration / Double(steps)

            for i in 1...steps {
                try? await Task.sleep(for: .milliseconds(Int(stepDuration * 1000)))
                guard !Task.isCancelled else { return }
                cooldownRemaining = cooldownDuration - (Double(i) * stepDuration)
            }

            isCooldown = false
            cooldownRemaining = 0
        }
    }

    // MARK: - Intercambio

    func swapGenerations() {
        let temp = sourceGeneration
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sourceGeneration = targetGeneration
            targetGeneration = temp
        }
        translateLocally()
    }

    // MARK: - Grabacion de voz

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Reproduccion de voz

    func toggleSpeaking() {
        if isSpeaking {
            speech.stopSpeaking()
            isSpeaking = false
        } else {
            guard !translatedText.isEmpty else { return }
            speech.speak(translatedText)
            isSpeaking = true
            startSpeakingMonitor()
        }
    }

    // MARK: - Limpiar

    func clearInput() {
        inputText = ""
        translatedText = ""
        translationTask?.cancel()
        isTranslating = false
        isAITranslation = false
    }

    // MARK: - Cargar ejemplo

    func loadExample(_ example: TranslationExample) {
        guard let text = example.sentences[sourceGeneration]
                ?? example.sentences.values.first else { return }
        inputText = text
    }

    var conceptCount: Int {
        SlangDictionary.shared.conceptCount
    }

    // MARK: - Privados

    private func checkGeminiAvailability() {
        Task {
            geminiAvailable = await GeminiService.isAvailable()
        }
    }

    /// Llamado desde .onChange en la vista cuando cambia inputText.
    /// Solo hace traduccion local (diccionario). La IA se activa con boton.
    func inputDidChange() {
        translateLocally()
    }

    private func startRecording() {
        speech.requestPermissions { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.showPermissionAlert = true
                    return
                }
                do {
                    try self.speech.startRecording { [weak self] partial in
                        Task { @MainActor in
                            self?.inputText = partial
                        }
                    }
                    self.isRecording = true

                    // Timeout de 30 segundos para grabacion
                    self.recordingTimeoutTask?.cancel()
                    self.recordingTimeoutTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(30))
                        guard !Task.isCancelled, self.isRecording else { return }
                        self.stopRecording()
                    }
                } catch {
                    self.isRecording = false
                }
            }
        }
    }

    private func stopRecording() {
        speech.stopRecording()
        isRecording = false
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
    }

    private func startSpeakingMonitor() {
        speakingMonitorCancellable?.cancel()
        speakingMonitorCancellable = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if !self.speech.isSpeaking {
                    self.isSpeaking = false
                    self.speakingMonitorCancellable?.cancel()
                    self.speakingMonitorCancellable = nil
                }
            }
    }
}
