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

    // MARK: Dependencias

    private let engine = TranslationEngine()
    private let speech = SpeechService()
    private var cancellables = Set<AnyCancellable>()
    private var translationTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var speakingMonitorCancellable: AnyCancellable?
    private var recordingTimeoutTask: Task<Void, Never>?

    // MARK: Ciclo de vida

    init() {
        checkGeminiAvailability()
    }

    // MARK: - Traduccion

    func translate() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            isTranslating = false
            return
        }

        translationTask?.cancel()

        if geminiAvailable {
            // IA disponible: mostrar estado de carga y esperar a Gemini
            isTranslating = true

            // Fallback local inmediato para no dejar el output vacio
            let localFallback = engine.translateLocal(trimmed, from: sourceGeneration, to: targetGeneration)
            translatedText = localFallback

            translationTask = Task { @MainActor in
                do {
                    let aiResult = try await engine.translateWithAI(
                        trimmed, from: sourceGeneration, to: targetGeneration
                    )
                    guard !Task.isCancelled else {
                        isTranslating = false
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Solo usar resultado IA si no esta vacio
                        if !aiResult.isEmpty {
                            translatedText = aiResult
                        }
                        isTranslating = false
                    }
                } catch {
                    guard !Task.isCancelled else {
                        isTranslating = false
                        return
                    }
                    // Fallback al diccionario local si Gemini falla
                    withAnimation {
                        translatedText = localFallback
                        isTranslating = false
                    }
                }
            }
        } else {
            // Sin IA: usar diccionario local
            translatedText = engine.translateLocal(trimmed, from: sourceGeneration, to: targetGeneration)
        }
    }

    // MARK: - Intercambio

    func swapGenerations() {
        let temp = sourceGeneration
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sourceGeneration = targetGeneration
            targetGeneration = temp
        }
        translate()
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
    /// Aplica debounce de 500ms antes de traducir.
    func inputDidChange() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            translate()
        }
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
