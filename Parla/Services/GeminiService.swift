import Foundation

// MARK: - Servicio de conexion con Gemini

/// Llama a la API de Gemini (Google) para traducir texto
/// entre generaciones usando IA.
final class GeminiService: Sendable {

    private static let model = "gemini-2.5-flash"
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models"

    // MARK: - API Key

    private static var apiKey: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.isEmpty, key != "YOUR_API_KEY_HERE"
        else {
            return nil
        }
        return key
    }

    // MARK: - System Prompt

    private static let systemPrompt: String = {
        guard let url = Bundle.main.url(forResource: "GeminiSystemPrompt", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            return "Eres PARLA, un traductor generacional de español. Traduce entre jerga Gen Z y español de persona mayor (Boomer). Responde SOLO con la traduccion."
        }
        return content
    }()

    // MARK: - Traduccion

    /// Traduce `text` de `source` a `target` usando Gemini.
    /// Lanza error si la API no esta disponible o la respuesta es invalida.
    static func translate(
        _ text: String,
        from source: Generation,
        to target: Generation
    ) async throws -> String {
        guard let apiKey else {
            throw TranslationError.missingAPIKey
        }

        let prompt = "[\(source.rawValue) → \(target.rawValue)] \(text)"

        guard let url = URL(string: "\(endpoint)/\(model):generateContent?key=\(apiKey)") else {
            throw TranslationError.invalidURL
        }

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 0.6,
                "topP": 0.9,
                "maxOutputTokens": 256
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        print("[Gemini] Prompt: \(prompt)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw TranslationError.serverError(statusCode: code)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            throw TranslationError.invalidResponse
        }

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        #if DEBUG
        print("[Gemini] Respuesta: \(cleaned)")
        #endif

        return cleaned
    }

    // MARK: - Salud

    /// Comprueba si la API de Gemini esta accesible y la API key es valida.
    static func isAvailable() async -> Bool {
        guard let apiKey else { return false }
        guard let url = URL(string: "\(endpoint)/\(model)?key=\(apiKey)") else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let available = (response as? HTTPURLResponse)?.statusCode == 200
            #if DEBUG
            print("[Gemini] Disponible: \(available)")
            #endif
            return available
        } catch {
            #if DEBUG
            print("[Gemini] No disponible: \(error.localizedDescription)")
            #endif
            return false
        }
    }
}

// MARK: - Errores

enum TranslationError: LocalizedError {
    case invalidURL
    case serverError(statusCode: Int)
    case invalidResponse
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de API invalida."
        case .serverError(let code):
            return "Error del servidor (codigo \(code))."
        case .invalidResponse:
            return "Respuesta invalida del modelo."
        case .missingAPIKey:
            return "Falta la clave de API de Gemini. Configura Secrets.plist."
        }
    }
}
