# Architecture

Parla is an iOS generational slang translator built with SwiftUI and Swift 6. It translates text and speech between "Nuevas generaciones" (Gen Z / Alpha) and "Boomer" (1946-1964) language styles, using a hybrid approach combining local dictionary lookups with AI-powered translations via Ollama.

## Pattern

**Hybrid Translation Engine with Progressive Enhancement**

The app implements a three-tier translation fallback strategy:

1. **Cache Layer** — Check in-memory and persistent cache for previously translated phrases
2. **AI Layer** — Call Ollama LLM for intelligent, context-aware translations
3. **Local Dictionary Layer** — Fall back to keyword-based dictionary matching if AI fails

This approach provides fast instant responses (cache), intelligent translations (AI), and reliable fallback (dictionary).

## Layers

### Presentation Layer
**Location:** `Parla/Views/`, `Parla/ViewModels/`

- **TranslatorView** (`Parla/Views/TranslatorView.swift`) — Main UI container coordinating input/output UI and example banners
- **UI Components** in `Parla/Views/Components/`:
  - `InputCard.swift` — Text input field with character count and clear button
  - `OutputCard.swift` — Translation display with copy and text-to-speech controls
  - `RecordButton.swift` — Microphone control for speech input
  - `WaveformView.swift` — Visual feedback during recording
  - `SwapButton.swift` — Button to swap source/target generations
  - `GenerationSelector.swift` — Dropdown to select language generations
  - `ExampleBanner.swift` — Carousel of translation example phrases
- **SplashView** (`Parla/Views/SplashView.swift`) — Loading/splash screen shown at app startup

### ViewModel/State Management Layer
**Location:** `Parla/ViewModels/`

- **TranslatorViewModel** (`Parla/ViewModels/TranslatorViewModel.swift`) — Central state container marked with `@MainActor` for thread safety
  - Published properties: input/output text, recording state, translation loading state, generation selections
  - Orchestrates translation requests with debouncing (500ms delay on input)
  - Manages speech service callbacks and error states
  - Handles generation swapping with animated transitions
  - Monitors Ollama availability on startup

### Business Logic Layer
**Location:** `Parla/Services/`

- **TranslationEngine** (`Parla/Services/TranslationEngine.swift`) — Core translation logic
  - `translateWithAI()` — Async method implementing cache→Ollama→error fallback
  - `translateLocal()` — Synchronous local dictionary translation with regex word boundary matching
  - Case preservation logic for matched terms (preserves capitalization)
  - Marked as `Sendable` for concurrency safety

- **OllamaService** (`Parla/Services/OllamaService.swift`) — Network service for AI translations
  - `translate()` — Async URLSession call to Ollama REST API at `http://127.0.0.1:11434/api/chat`
  - Uses `parla` model with system prompt enforcing Spanish responses and emoji additions
  - `isAvailable()` — Health check for Ollama availability
  - Configurable baseURL for simulator vs. physical device network routing
  - Error types: `OllamaError.serverError`, `OllamaError.invalidResponse`

- **SpeechService** (`Parla/Services/SpeechService.swift`) — Microphone and speaker integration
  - `startRecording()` — Uses `SFSpeechRecognizer` (Spanish locale) with `AVAudioEngine`
  - `stopRecording()` — Cleanup and resource release
  - `speak()` — Text-to-speech synthesis using `AVSpeechSynthesizer` in Spanish
  - Permission request handling for microphone and speech recognition

- **TranslationCache** (`Parla/Services/TranslationCache.swift`) — Persistent caching layer
  - `get(text:from:to:)` — Dictionary lookup in UserDefaults
  - `set(text:from:to:result:)` — Save translations with LRU eviction (max 1000 entries)
  - Pre-cache loading from `PrecachedTranslations.json` bundle asset on first launch
  - Cache key format: `"{source}>{target}>{normalized_text}"`

- **SlangDictionary** (`Parla/Services/SlangDictionary.swift`) — Singleton dictionary of 100+ generational concepts
  - Singleton: `SlangDictionary.shared`
  - Pre-built index by generation for O(1) lookups
  - Sorted terms by length (longest first) for greedy regex matching
  - Supports multiple synonyms per concept and per generation

### Data Models Layer
**Location:** `Parla/Models/`

- **Generation** (`Parla/Models/Generation.swift`) — Enum representing the two supported language styles
  - Cases: `.newGen` ("Nuevas generaciones"), `.boomer` ("Boomer")
  - UI properties: emoji, color (purple/orange), shortName, yearRange, tagline
  - `Codable` and `Identifiable` for integration with SwiftUI pickers

- **SlangEntry** (`Parla/Models/SlangEntry.swift`) — Concept mapping between generations
  - `concept` — Semantic concept identifier ("cool", "cringe", "friend", etc.)
  - `mappings` — Dictionary keyed by Generation, each containing array of synonym strings
  - Methods: `primary(for:)` returns first (preferred) synonym, `terms(for:)` returns all

- **TranslationExample** (`Parla/Models/TranslationExample.swift`) — Sample phrases for user guidance
  - `sentences` — Dictionary mapping generations to example texts
  - `samples` — Static array of example phrases bundled with the app

### Theme/Styling Layer
**Location:** `Parla/Theme/`

- **AppTheme** (`Parla/Theme/AppTheme.swift`) — Centralized design system
  - Colors: system-derived background, white cards, label colors, indigo accent
  - Spacing constants: 14pt card padding, 18pt corner radius, 10pt spacing
  - Shadow definitions: 6pt blur, 4pt offset, black 6% opacity
  - **CardModifier** — Reusable view modifier for consistent card styling

### App Entry Point
**Location:** `Parla/App/`

- **ParlaApp** (`Parla/App/ParlaApp.swift`) — SwiftUI App struct marked with `@main`
  - Sets window background color to system grouped background
  - Manages splash screen visibility with opacity animation
  - Enforces light color scheme across the app

## Data Flow

### Translation Flow (User Input → Output)

```
User types in InputCard
  ↓
TranslatorView onChange listener triggers viewModel.inputDidChange()
  ↓
ViewModel debounces 500ms, then calls translate()
  ↓
TranslationEngine.translateWithAI() or translateLocal()
  ↓
Cache hit? Return instantly
  ↓
Cache miss → OllamaService.translate() (async)
  ↓
Ollama returns result → Cache stores it
  ↓
ViewModel updates @Published translatedText property
  ↓
SwiftUI re-renders OutputCard with new translation
```

### Recording Flow (Speech → Text → Translation)

```
User taps RecordButton
  ↓
ViewModel.toggleRecording() → SpeechService.startRecording()
  ↓
SFSpeechRecognizer feeds AVAudioEngine buffers
  ↓
Partial results stream back via onPartialResult callback
  ↓
Callback updates ViewModel.inputText
  ↓
onChange triggers translation pipeline (as above)
  ↓
User taps RecordButton again or result finalizes
  ↓
SpeechService.stopRecording() releases audio resources
```

### Speaking Flow (Translation → Audio)

```
User taps speaker icon in OutputCard
  ↓
ViewModel.toggleSpeaking() → SpeechService.speak(translatedText)
  ↓
AVSpeechSynthesizer generates Spanish audio utterance
  ↓
Timer polls synthesizer.isSpeaking every 0.3s
  ↓
When isSpeaking becomes false, ViewModel sets isSpeaking = false
  ↓
UI updates to show inactive speaker state
```

### Initialization Flow

```
App startup (ParlaApp)
  ↓
TranslatorView creates @StateObject TranslatorViewModel
  ↓
ViewModel.init() calls checkOllamaAvailability()
  ↓
Async Task queries OllamaService.isAvailable()
  ↓
Sets @Published ollamaAvailable property
  ↓
SplashView shown until user dismissal
  ↓
On first app run, TranslationCache loads PrecachedTranslations.json
  ↓
SlangDictionary builds indices and term sorter in singleton init
  ↓
App ready for user interaction
```

## Key Abstractions

### 1. Sendable Protocol Compliance
- **TranslationEngine**, **SlangDictionary**, **TranslationCache** conform to `Sendable` for thread-safe actor usage
- Enables concurrent translation requests without race conditions

### 2. Generation Enum
- Encapsulates all generation-specific UI (colors, emojis) and data mappings
- Acts as type-safe key for dictionary lookups and cache indexing
- Supports SwiftUI Picker integration via Identifiable conformance

### 3. Cache Layering Pattern
- **Three-tier lookup**: UserDefaults → (LRU eviction) → Dictionary regex → fallback empty result
- Reduces network requests and Ollama server load
- Enables offline usage via pre-cached translations

### 4. Debounced Input Handler
- 500ms delay prevents excessive translation requests during typing
- Task-based cancellation avoids redundant computation
- Maintains responsive UI feel while reducing backend load

### 5. Main Actor Isolation
- **TranslatorViewModel** runs all UI state updates on main thread
- Prevents concurrent modification of @Published properties
- Integrates cleanly with SwiftUI's requirement for main-thread binding

### 6. Progressive Enhancement with Fallback
- If Ollama unavailable → use local dictionary
- If local dictionary incomplete → return untranslated text
- User still gets best-effort response at each tier

## Entry Points

### User-Facing Entry Points

1. **Text Input** — `InputCard` text field in `TranslatorView`
   - Triggers `viewModel.inputDidChange()` on every keystroke
   - Debounced translation pipeline begins

2. **Speech Input** — `RecordButton` in `TranslatorView`
   - Initiates microphone recording via `SpeechService`
   - Streamed transcription populates `inputText`
   - Implicit translation from on-change handler

3. **Speech Output** — Speaker icon in `OutputCard`
   - Calls `viewModel.toggleSpeaking()`
   - Reads `translatedText` using `AVSpeechSynthesizer`

4. **Generation Swap** — `SwapButton` in direction header
   - Swaps `sourceGeneration` and `targetGeneration`
   - Re-triggers translation with swapped parameters

5. **Examples Carousel** — `ExampleBanner` at bottom
   - Tap example text to load into input
   - Immediately triggers translation

### Code Entry Points

1. **Application Entry** — `ParlaApp` struct marked `@main`
   - Executed by iOS runtime on app launch
   - Sets up window appearance and initial view hierarchy

2. **Main View Initialization** — `TranslatorView` body
   - First SwiftUI view rendered
   - Creates `@StateObject TranslatorViewModel()` singleton for session
   - Observes viewModel state via `@EnvironmentObject` in child components

3. **ViewModel Initialization** — `TranslatorViewModel.init()`
   - Called when first view mounts
   - Starts async Ollama availability check
   - Sets up translation engine and speech service references

4. **Cache Initialization** — `TranslationCache.init()`
   - Called on app launch via `TranslationEngine` dependency
   - Synchronously loads pre-cached translations from bundle JSON
   - Initializes UserDefaults backend

5. **Dictionary Initialization** — `SlangDictionary.shared` singleton
   - Lazy-initialized on first access
   - Builds concept-to-term indices and sorted term arrays
   - ~100 concepts × 2 generations = hundreds of term mappings cached in memory
