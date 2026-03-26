# Concerns

## Technical Debt

### 1. Unsafe Concurrency Patterns
**Files:** `Parla/Services/OllamaService.swift`, `Parla/Services/TranslationCache.swift`

The codebase uses `nonisolated(unsafe)` in two critical places:
- `OllamaService.swift:11` - Static mutable `baseURL` property
- `TranslationCache.swift:12` - `UserDefaults.standard` marked as `nonisolated(unsafe)`

**Impact:** This violates Swift's strict concurrency model (Swift 6.0 is in use per `project.yml:11`). While the app may compile, this can lead to race conditions in concurrent contexts. The `baseURL` is especially problematic as it's mutable state that could be modified from multiple threads.

**Recommendation:** Wrap mutable state with proper synchronization (Actor or DispatchQueue) or use thread-safe patterns.

---

### 2. Debug Print Statements in Production Code
**Files:** `Parla/Services/OllamaService.swift` (6 print calls), `Parla/ViewModels/TranslatorViewModel.swift` (1 print call)

Lines:
- `OllamaService.swift:48, 57, 65, 72, 73` - Verbose logging with emoji prefixes
- `TranslatorViewModel.swift:151` - Ollama availability check logging

**Impact:** These statements will clutter the console in production builds and potentially leak sensitive debugging information (request bodies, raw JSON). Performance overhead is minimal but unnecessary.

**Recommendation:** Use a proper logging framework (OSLog) with appropriate log levels (debug/info) that can be disabled in Release builds.

---

### 3. Hardcoded Configuration Values
**Files:** `Parla/Services/OllamaService.swift`, `precache.py`, `precache2.py`

- `OllamaService.swift:11` - Hardcoded localhost URL `http://127.0.0.1:11434`
- `precache.py:127, precache2.py:172` - Hardcoded curl endpoint
- `project.yml:28` - `NSAllowsLocalNetworking: true` enables local network access

**Impact:** The hardcoded localhost address makes device deployment difficult. Comments mention changing to `192.168.1.100` for physical devices, but this manual process is error-prone.

**Recommendation:** Use environment-based configuration (Info.plist entries, environment variables, or a config file) to switch between simulator/device/production endpoints.

---

### 4. Duplicated Precache Scripts
**Files:** `precache.py`, `precache2.py`

Two nearly identical Python scripts with slight differences:
- `precache.py` - Initial caching of 61 phrases
- `precache2.py` - Extended caching adding 86 more phrases

**Impact:** Code duplication, maintenance burden, potential for divergence between scripts.

**Recommendation:** Consolidate into a single parameterized script that can be run multiple times to augment the cache.

---

## Known Issues

### 1. Invalid iOS Deployment Target
**Files:** `project.yml:5`, `Parla.xcodeproj/project.pbxproj:316, 375`

Deployment target set to iOS 26.0, which does not exist. Current iOS is at version 18.x as of 2026.

**Impact:**
- The app will fail to build/deploy to real devices
- Simulator may have unpredictable behavior
- Xcode may reject the project configuration

**Recommendation:** Update to a valid iOS version (e.g., iOS 16.0 or higher) that supports the features used (Swift Concurrency, AVFoundation, Speech framework).

---

### 2. Timer Resource Leak in ViewModel
**File:** `Parla/ViewModels/TranslatorViewModel.swift:193-203`

The `startSpeakingMonitor()` method creates a Timer subscription that checks if speech is still active every 0.3 seconds:

```swift
Timer.publish(every: 0.3, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in
        guard let self else { return }
        if !self.speech.isSpeaking {
            self.isSpeaking = false
        }
    }
    .store(in: &cancellables)
```

**Impact:** Every time speech finishes, a new timer is started and stored in `cancellables`. These timers are never explicitly cancelled - they only stop when the ViewModel is deinitialized. Multiple rapid speech events could accumulate timer subscriptions.

**Recommendation:** Either:
1. Cancel the previous timer before starting a new one
2. Use a single long-lived timer instead of creating new ones per speech event
3. Use `AVSpeechSynthesizerDelegate` methods instead of polling

---

### 3. Missing Error Messages for User
**File:** `Parla/ViewModels/TranslatorViewModel.swift:72-82`

When Ollama translation fails, the app silently falls back to local dictionary without informing the user that AI translation wasn't available:

```swift
} catch {
    guard !Task.isCancelled else {
        isTranslating = false
        return
    }
    // Fallback al diccionario local si Ollama falla
    withAnimation {
        translatedText = localFallback
        isTranslating = false
    }
}
```

**Impact:** Users don't know whether they're seeing AI-generated or dictionary-based translations. This affects trust and feature clarity.

**Recommendation:** Add a published property to track translation source/status and display a subtle indicator in the UI.

---

### 4. Precache JSON Not Tracked in Git
**File:** `Parla/Resources/PrecachedTranslations.json`

The precached translations file is generated by Python scripts but its presence/absence in the repo is unclear. Large JSON files can cause repository bloat.

**Impact:** If the file is checked in but large, it increases repository size. If it's not checked in, initial builds may fail if users don't run the Python scripts.

**Recommendation:** Either include in git with .gitattributes to track binary delta, or ensure build system generates it automatically.

---

## Security Concerns

### 1. Unencrypted Cache Storage
**File:** `Parla/Services/TranslationCache.swift`

Translation cache is stored directly in `UserDefaults.standard` without encryption:

```swift
private nonisolated(unsafe) let defaults = UserDefaults.standard
```

**Impact:** On jailbroken devices or if the device backup is exposed, all translation history is accessible in plaintext. This includes potentially sensitive or personal text users have translated.

**Recommendation:** Use Keychain or encrypt cache entries before storing in UserDefaults.

---

### 2. Local Network Access Without Validation
**File:** `project.yml:27-28`

```yaml
NSAllowsLocalNetworking: true
```

App is explicitly granted local network access to communicate with Ollama.

**Impact:** While necessary for the app's function, there's no URL validation in `OllamaService.swift`. A compromised device or Man-in-the-Middle attack could redirect requests to a malicious Ollama instance.

**Recommendation:**
1. Validate SSL certificates for any HTTPS endpoints
2. Pin the expected Ollama certificate (if using HTTPS)
3. Add network security configuration to restrict which networks the app can connect to

---

### 3. No Input Validation on Network Requests
**File:** `Parla/Services/OllamaService.swift:40`

The URL is created using force-unwrap:

```swift
let url = URL(string: "\(baseURL)/api/chat")!
```

While `baseURL` is hardcoded, force-unwrapping is brittle if this is later made configurable.

**Impact:** If baseURL ever becomes user-configurable or malformed, the force-unwrap will crash the app.

**Recommendation:** Handle the optional gracefully and throw a descriptive error.

---

### 4. Request Body Exposed in Logs
**File:** `Parla/Services/OllamaService.swift:47-48`

```swift
let bodyString = String(data: request.httpBody!, encoding: .utf8) ?? "(no decodable)"
print("🔵 [Ollama] Request body: \(bodyString)")
```

The full request (including prompt text) is logged. In production, this could leak user input.

**Recommendation:** Only log request body in DEBUG builds, and mask sensitive fields.

---

## Performance

### 1. Regex Compilation on Every Local Translation
**File:** `Parla/Services/TranslationEngine.swift:57-62`

For every translation, a regex is compiled inside a loop:

```swift
for (phrase, entry) in phrases {
    let escaped = NSRegularExpression.escapedPattern(for: phrase)
    let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"

    guard let regex = try? NSRegularExpression(
        pattern: pattern, options: .caseInsensitive
    ) else { continue }
```

**Impact:** For large dictionaries, this is slow. If there are 100+ phrases in `SlangDictionary`, each translation triggers 100+ regex compilations.

**Recommendation:** Pre-compile and cache regexes in `SlangDictionary` initialization.

---

### 2. No LRU Eviction Logic in Cache
**File:** `Parla/Services/TranslationCache.swift:32-35`

When cache reaches `maxEntries` (1000), it removes 25% of entries by deleting the first N items:

```swift
if cache.count >= maxEntries {
    let keysToRemove = Array(cache.keys.prefix(cache.count / 4))
    for k in keysToRemove { cache.removeValue(forKey: k) }
}
```

**Impact:** Deletion order is arbitrary (dictionary order, not insertion/access order). Recently used translations could be evicted while old ones persist.

**Recommendation:** Implement proper LRU (Least Recently Used) eviction or use NSCache instead of UserDefaults.

---

### 3. Repeated Dictionary Initialization
**File:** `Parla/Services/SlangDictionary.swift:14-36`

The singleton initializer builds indices every time (though only once due to singleton pattern):

```swift
private init() {
    let all = Self.buildEntries()
    // ... builds index, sortedTerms ...
}
```

**Impact:** While only happens once, this happens synchronously on first access. With 500+ slang entries, this could cause a brief UI freeze on app launch if `SlangDictionary.shared` is accessed during view initialization.

**Recommendation:** Consider lazy initialization or background loading for large data structures.

---

### 4. Full Cache Reload on Every Set Operation
**File:** `Parla/Services/TranslationCache.swift:28-39`

Every cache write loads the entire cache from UserDefaults, modifies it, and writes it back:

```swift
func set(...) {
    let key = cacheKey(...)
    var cache = loadCache()  // Load entire cache
    // ... modify ...
    saveCache(cache)  // Save entire cache
}
```

**Impact:** Inefficient for large caches. If the JSON is several MB, this adds I/O overhead per translation.

**Recommendation:** Use SQLite or a more efficient storage format (e.g., MessagePack) for large caches.

---

## Fragile Areas

### 1. Brittle Speech Recognition Integration
**File:** `Parla/Services/SpeechService.swift:40-69`

The speech recognition task callback doesn't properly handle lifecycle:

```swift
recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
    if let result {
        onPartialResult(result.bestTranscription.formattedString)
    }
    if error != nil || (result?.isFinal ?? false) {
        // Se detiene automaticamente si hay error o resultado final
    }
}
```

**Issues:**
- No explicit cleanup of task on error
- `onPartialResult` callback called on unknown thread (likely not Main)
- No timeout handling if recognition hangs

**Impact:** Speech recognition could leak memory or cause thread-safety issues.

**Recommendation:**
1. Explicitly cancel task on error
2. Ensure callback dispatch to main thread
3. Add timeout handler

---

### 2. Weak Self Captures in Closures
**File:** `Parla/ViewModels/TranslatorViewModel.swift:167, 175-177`

Multiple closures use `[weak self]` but don't explicitly check the result:

```swift
speech.requestPermissions { [weak self] granted in
    Task { @MainActor in
        guard let self else { return }
        // ...
    }
}
```

**Impact:** While correct, the pattern is nested and could be simplified. If refactored, it's easy to forget the guard check.

**Recommendation:** Consider using `@MainActor` final class to reduce need for manual captures.

---

### 3. Generation Enum Hardcoded Everywhere
**File:** `Parla/Models/Generation.swift:4-5`

Only 2 generations exist: `newGen` and `boomer`. All code assumes this:

```swift
enum Generation: String, CaseIterable {
    case newGen = "Nuevas generaciones"
    case boomer = "Boomer"
}
```

**Impact:** Adding a third generation would require changes throughout:
- `SlangDictionary.swift:19-36` (index building loop)
- All cache keys which encode both source and target
- UI components that hardcode color/emoji mappings

**Recommendation:** Future-proof by using more generic mapping structures or configuration-driven generation definitions.

---

### 4. No Validation of Ollama Response Format
**File:** `Parla/Services/OllamaService.swift:59-63`

Assumes response structure without checking:

```swift
guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let message = json["message"] as? [String: Any],
      let content = message["content"] as? String else {
    throw OllamaError.invalidResponse
}
```

**Impact:** If Ollama API changes or returns unexpected structure, entire translation fails with generic error message.

**Recommendation:** Add detailed error reporting (log actual structure) and consider API versioning.

---

### 5. Raw Regex Pattern Hardcoding
**File:** `Parla/Services/TranslationEngine.swift:58`

```swift
let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
```

The word boundary pattern is hardcoded and assumes Spanish text patterns will always use Latin letters and numbers.

**Impact:** Won't work correctly for:
- Languages with different scripts (Arabic, Chinese, etc.)
- Emoji in text
- Compound words with hyphens

**Recommendation:** Make pattern configurable per language/generation, or use simpler word boundary logic (\b in most languages).

---

## Recommendations

### Immediate Priority (Before Release)

1. **Fix iOS Deployment Target** (`project.yml:5`)
   - Change from 26.0 to a valid version (16.0 or higher)
   - This is a blocker for any real device testing

2. **Remove Debug Print Statements**
   - Replace with OSLog calls in debug builds only
   - Use `#if DEBUG` guards or logging framework

3. **Fix Timer Leak in SpeakingMonitor** (`TranslatorViewModel.swift:193-203`)
   - Cancel previous timer or use better approach (delegate pattern)
   - Test with rapid speech events to verify fix

4. **Secure Cache Storage** (`TranslationCache.swift`)
   - Migrate from UserDefaults to Keychain or encrypted storage
   - Or at minimum, add encryption layer

### High Priority (Before 1.0 Release)

5. **Address Concurrency Safety**
   - Properly isolate mutable state from `nonisolated(unsafe)`
   - Use Actor or DispatchQueue for shared state

6. **Cache Performance Optimization**
   - Pre-compile regex patterns in SlangDictionary
   - Implement LRU eviction or switch to NSCache/SQLite
   - Add batch operations to reduce I/O

7. **User Feedback on Translation Source**
   - Add indicator showing whether translation came from AI or dictionary
   - Helps set proper user expectations

### Medium Priority (Polish & Scalability)

8. **Configuration Management**
   - Externalize Ollama URL to configurable source
   - Support different environments (dev/staging/prod)

9. **Better Error Handling**
   - Catch and display Ollama connection errors gracefully
   - Add retry logic with exponential backoff

10. **Code Organization**
    - Consolidate duplicate Python scripts
    - Extract common patterns into shared utilities

### Nice to Have (Future Enhancements)

11. **Logging Framework**
    - Implement structured logging (OSLog or third-party)
    - Make production logs queryable

12. **Unit Tests**
    - Add tests for translation engine (regex edge cases)
    - Test cache eviction logic
    - Mock Ollama responses

13. **API Versioning**
    - Future-proof Ollama integration
    - Handle API changes gracefully

14. **Internationalization**
    - Current implementation hardcodes Spanish generation names
    - Consider multilingual support if expanding app

---

## Summary

The codebase is well-structured for an MVP translator app with clean separation of concerns (Services, ViewModels, Views). However, it has several critical issues:

**Critical:** iOS deployment target is invalid (26.0) - blocks all testing
**Critical:** Concurrency safety violations with Swift 6.0 strict mode
**Important:** Security issues (unencrypted cache, exposed request bodies)
**Important:** Performance issues (regex recompilation, inefficient cache)
**Important:** Resource leaks (timer subscriptions)

Most issues are fixable with targeted refactoring. The core architecture is sound but needs hardening before production release.
