import AVFoundation
import Speech

// MARK: - Servicio de voz (reconocimiento + sintesis)

/// Encapsula el reconocimiento de voz (Speech) y la sintesis text-to-speech
/// (AVSpeechSynthesizer). No es observable: el ViewModel gestiona el estado
/// de la UI y llama a estos metodos con callbacks.
final class SpeechService {

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Permisos

    /// Solicita permisos de microfono y reconocimiento de voz.
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                completion(false)
                return
            }
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted)
            }
        }
    }

    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Reconocimiento de voz

    /// Inicia la grabacion y transcripcion en tiempo real.
    /// `onPartialResult` se invoca cada vez que llega un resultado parcial.
    func startRecording(onPartialResult: @escaping (String) -> Void) throws {
        stopRecording()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result {
                onPartialResult(result.bestTranscription.formattedString)
            }
            if error != nil || (result?.isFinal ?? false) {
                // Se detiene automaticamente si hay error o resultado final
            }
        }
    }

    /// Detiene la grabacion y libera recursos.
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // MARK: - Text-to-Speech

    /// Lee el texto en voz alta usando sintesis de voz en español.
    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    /// Detiene la reproduccion de voz.
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}
