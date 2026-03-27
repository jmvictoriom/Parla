import Foundation

// MARK: - Cache de traducciones

/// Cache en memoria + disco para evitar llamadas repetidas a Gemini.
/// Al primer arranque carga traducciones precacheadas desde un JSON bundled.
/// Nuevas traducciones se guardan en UserDefaults con timestamps LRU.
actor TranslationCache {

    static let shared = TranslationCache()

    private let defaults = UserDefaults.standard
    private let storageKey = "parla_translation_cache_v4"
    private let precacheLoaded = "parla_precache_loaded_v4"
    private let maxEntries = 1000
    private var precacheChecked = false

    private init() {}

    // MARK: - Tipos internos

    private struct CacheEntry: Codable {
        let value: String
        var lastAccess: Date
    }

    // MARK: - API

    func get(text: String, from source: Generation, to target: Generation) -> String? {
        ensurePrecacheLoaded()
        let key = cacheKey(text: text, source: source, target: target)
        var cache = loadCache()

        guard var entry = cache[key] else { return nil }

        // Actualizar timestamp LRU
        entry.lastAccess = Date()
        cache[key] = entry
        saveCache(cache)

        return entry.value
    }

    func set(text: String, from source: Generation, to target: Generation, result: String) {
        let key = cacheKey(text: text, source: source, target: target)
        var cache = loadCache()

        // Eviccion LRU: borrar el 25% mas antiguo
        if cache.count >= maxEntries {
            let sorted = cache.sorted { $0.value.lastAccess < $1.value.lastAccess }
            let toRemove = sorted.prefix(cache.count / 4)
            for (k, _) in toRemove { cache.removeValue(forKey: k) }
        }

        cache[key] = CacheEntry(value: result, lastAccess: Date())
        saveCache(cache)
    }

    var count: Int { loadCache().count }

    func clear() {
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: precacheLoaded)
    }

    // MARK: - Precache

    private func ensurePrecacheLoaded() {
        guard !precacheChecked else { return }
        precacheChecked = true
        loadPrecacheIfNeeded()
    }

    /// Carga traducciones pre-generadas desde el JSON incluido en el bundle.
    private func loadPrecacheIfNeeded() {
        guard !defaults.bool(forKey: precacheLoaded) else { return }

        guard let url = Bundle.main.url(forResource: "PrecachedTranslations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let precache = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return
        }

        var cache = loadCache()
        let now = Date()
        for (key, value) in precache {
            if cache[key] == nil {
                cache[key] = CacheEntry(value: value, lastAccess: now)
            }
        }
        saveCache(cache)
        defaults.set(true, forKey: precacheLoaded)
    }

    // MARK: - Privado

    private func cacheKey(text: String, source: Generation, target: Generation) -> String {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(source.rawValue)>\(target.rawValue)>\(normalized)"
    }

    private func loadCache() -> [String: CacheEntry] {
        guard let data = defaults.data(forKey: storageKey),
              let cache = try? JSONDecoder().decode([String: CacheEntry].self, from: data)
        else {
            return [:]
        }
        return cache
    }

    private func saveCache(_ cache: [String: CacheEntry]) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
