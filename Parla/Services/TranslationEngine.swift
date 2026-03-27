import Foundation

// MARK: - Motor de traduccion generacional

/// Estrategia: Cache → Gemini (IA) → Diccionario local (fallback)
/// 1. Si la traduccion esta en cache, se devuelve instantaneamente.
/// 2. Si no, se llama a Gemini y se cachea el resultado.
/// 3. Si Gemini falla, se usa el diccionario local como ultimo recurso.
final class TranslationEngine: Sendable {

    private let dictionary = SlangDictionary.shared
    private let cache = TranslationCache.shared

    // MARK: - Traduccion con IA (async)

    /// Traduce usando cache + Gemini. Lanza error solo si ambos fallan.
    func translateWithAI(
        _ text: String,
        from source: Generation,
        to target: Generation,
        exaggeration: ExaggerationLevel = .normal
    ) async throws -> String {
        guard source != target, !text.isEmpty else { return text }

        // 1. Buscar en cache (solo para nivel normal, exageraciones no se cachean)
        if exaggeration == .normal, let cached = await cache.get(text: text, from: source, to: target) {
            return cached
        }

        // 2. Llamar a Gemini
        let result = try await GeminiService.translate(text, from: source, to: target, exaggeration: exaggeration)

        // 3. Guardar en cache si es nivel normal y la respuesta no esta vacia
        if exaggeration == .normal, !result.isEmpty {
            await cache.set(text: text, from: source, to: target, result: result)
        }

        return result
    }

    // MARK: - Traduccion local (instantanea, fallback)

    func translateLocal(
        _ text: String,
        from source: Generation,
        to target: Generation
    ) -> String {
        guard source != target, !text.isEmpty else { return text }

        let phrases = dictionary.phrasesSorted(for: source)
        guard !phrases.isEmpty else { return text }

        var result = text

        for (_, entry, regex) in phrases {
            guard let replacement = entry.primary(for: target) else { continue }

            let nsRange = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: nsRange)

            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let original = String(result[range])
                let adjusted = Self.preserveCase(replacement: replacement, original: original)
                result.replaceSubrange(range, with: adjusted)
            }
        }

        return result
    }

    /// Numero de traducciones en cache.
    var cacheCount: Int {
        get async { await cache.count }
    }

    // MARK: - Helpers

    private static func preserveCase(replacement: String, original: String) -> String {
        if original == original.uppercased(), original.count > 1 {
            return replacement.uppercased()
        }
        if let first = original.first, first.isUppercase {
            return replacement.prefix(1).uppercased() + replacement.dropFirst()
        }
        return replacement
    }
}
