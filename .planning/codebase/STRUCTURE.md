# Structure

## Directory Layout

```
/Users/jesusvictorio/Documents/repos/Parla/
├── Parla/                                 # Main source directory
│   ├── App/                              # App entry point
│   │   └── ParlaApp.swift               # @main app struct
│   ├── Models/                           # Data structures
│   │   ├── Generation.swift             # Enum: newGen, boomer
│   │   ├── SlangEntry.swift             # Concept-to-translation mappings
│   │   └── TranslationExample.swift      # Sample phrases for UI
│   ├── Services/                         # Business logic & external integration
│   │   ├── TranslationEngine.swift      # Core translation logic (cache→AI→dict)
│   │   ├── OllamaService.swift          # Ollama REST API client
│   │   ├── SpeechService.swift          # Speech recognition & synthesis
│   │   ├── TranslationCache.swift       # Persistent cache with UserDefaults
│   │   └── SlangDictionary.swift        # Central dictionary singleton
│   ├── ViewModels/                       # State management
│   │   └── TranslatorViewModel.swift    # Main observable object for UI state
│   ├── Views/                            # UI layer
│   │   ├── TranslatorView.swift         # Main screen container
│   │   ├── SplashView.swift             # Splash/loading screen
│   │   └── Components/                  # Reusable UI components
│   │       ├── InputCard.swift          # Text input container
│   │       ├── OutputCard.swift         # Translation output display
│   │       ├── RecordButton.swift       # Microphone button
│   │       ├── WaveformView.swift       # Recording waveform animation
│   │       ├── SwapButton.swift         # Generation swap button
│   │       ├── GenerationSelector.swift # Picker for generation selection
│   │       └── ExampleBanner.swift      # Carousel of translation examples
│   ├── Theme/                            # Design system
│   │   └── AppTheme.swift               # Colors, spacing, shadows, modifiers
│   ├── Resources/                        # Assets and data files
│   │   ├── Assets.xcassets/             # Image assets & color sets
│   │   │   ├── AppIcon.appiconset/
│   │   │   ├── AccentColor.colorset/
│   │   │   └── SplashBackground.colorset/
│   │   └── PrecachedTranslations.json   # Pre-cached translation pairs
│   └── Info.plist                        # App metadata & capabilities
├── Parla.xcodeproj/                      # Xcode project
│   ├── project.pbxproj                   # Project configuration
│   ├── xcshareddata/                     # Shared build settings
│   └── xcuserdata/                       # User-specific Xcode data
├── .planning/                            # Planning documents
│   └── codebase/                         # This directory
│       ├── ARCHITECTURE.md               # Architecture analysis
│       └── STRUCTURE.md                  # File organization (this file)
├── project.yml                           # XcodeGen project definition
├── precache.py                           # Script to generate precached translations (legacy)
├── precache2.py                          # Script to generate precached translations (current)
├── Modelfile                             # Ollama model definition
└── build/                                # Xcode build artifacts
    └── Build/                            # Compiled app, intermediate files
```

## Key Locations

### Source Code Root
`/Users/jesusvictorio/Documents/repos/Parla/Parla/`

All Swift source files and resources for the iOS app. Organized by functional layer (App, Models, Services, ViewModels, Views, Theme).

### Application Entry Point
`/Users/jesusvictorio/Documents/repos/Parla/Parla/App/ParlaApp.swift`

Main SwiftUI App struct decorated with `@main`. This is the first code executed when the app launches. Sets up window appearance and renders the initial view hierarchy.

### Core Translation Logic
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Services/TranslationEngine.swift`

Heart of the app: implements the three-tier translation strategy (cache → AI → dictionary). No UI dependencies; pure business logic.

### Dictionary of Generational Terms
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Services/SlangDictionary.swift`

Singleton containing 100+ generational concepts with multi-synonym mappings. Built at initialization, indexed for fast lookup, provides fallback translations when Ollama is unavailable.

### Network Service for Ollama
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Services/OllamaService.swift`

URLSession-based REST client targeting `http://127.0.0.1:11434/api/chat`. Communicates with local Ollama instance running the `parla` model. Includes health check via `/api/tags`.

### UI State Management
`/Users/jesusvictorio/Documents/repos/Parla/Parla/ViewModels/TranslatorViewModel.swift`

Central observable class (`@MainActor`, `ObservableObject`) managing all UI state:
- Input/output text
- Current selections (source/target generation)
- Loading/recording/speaking indicators
- Debounced translation invocation
- Speech service integration

### Main User Interface
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Views/TranslatorView.swift`

Primary screen: composition of InputCard, OutputCard, DirectionHeader, ExampleBanner, and other components. Implements onChange listeners for translation triggering on input or generation changes.

### Component Library
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Views/Components/`

Reusable SwiftUI view components:
- `InputCard.swift` — Text field with clear button and character count
- `OutputCard.swift` — Translation display with copy/speak buttons
- `RecordButton.swift` — Microphone UI and state binding
- `WaveformView.swift` — Animated recording visualization
- `SwapButton.swift` — Button to reverse translation direction
- `GenerationSelector.swift` — Picker for language selection
- `ExampleBanner.swift` — Horizontal carousel of sample phrases

### Design System
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Theme/AppTheme.swift`

Single source of truth for:
- Color palette (backgrounds, cards, text, accent)
- Spacing values (padding, gaps, corner radius)
- Shadow specifications
- CardModifier ViewModifier for consistent card styling

### Pre-Cached Data
`/Users/jesusvictorio/Documents/repos/Parla/Parla/Resources/PrecachedTranslations.json`

JSON file bundled with app containing pre-computed translation pairs. Loaded once on first app run into UserDefaults to provide instant translations without Ollama calls.

### Project Configuration
`/Users/jesusvictorio/Documents/repos/Parla/project.yml`

XcodeGen configuration defining:
- Project name: `Parla`
- Bundle ID prefix: `com.parla`
- Deployment target: iOS 26.0 (current)
- Swift version: 6.0
- App metadata (permissions, icons, etc.)

### Build Artifacts
`/Users/jesusvictorio/Documents/repos/Parla/build/Build/Products/Debug-iphonesimulator/Parla.app/`

Compiled app binary and resources. Generated after Xcode build.

## Naming Conventions

### File Naming

**Pattern:** `PascalCase.swift` for type-containing files, matching the primary type name.

Examples:
- `ParlaApp.swift` — Contains `struct ParlaApp`
- `TranslatorViewModel.swift` — Contains `class TranslatorViewModel`
- `TranslationEngine.swift` — Contains `class TranslationEngine`
- `OllamaService.swift` — Contains `class OllamaService`
- `SlangDictionary.swift` — Contains `class SlangDictionary`
- `Generation.swift` — Contains `enum Generation`
- `SlangEntry.swift` — Contains `struct SlangEntry`

**Directories:** `lowercase` or `PascalCase` based on type:
- Functional groupings: `lowercase` (App, Models, Services, Views, Theme, Resources)
- Component groups: `Components` (within Views)

### Type Naming

**Classes:** `UpperCamelCase`, descriptive nouns/roles
- `TranslationEngine`
- `OllamaService`
- `SpeechService`
- `TranslationCache`
- `SlangDictionary`
- `TranslatorViewModel`

**Structs:** `UpperCamelCase`
- `SlangEntry`
- `TranslationExample`
- `ParlaApp`
- `CardModifier`
- `AppTheme`
- `TranslatorView`
- UI component views (InputCard, OutputCard, etc.)

**Enums:** `UpperCamelCase`
- `Generation`
- `OllamaError`

**Protocols/Extensions:** `UpperCamelCase`
- `Identifiable`
- `Codable`
- `Sendable`

### Property Naming

**Attributes:** `lowerCamelCase`
- `sourceGeneration`
- `targetGeneration`
- `inputText`
- `translatedText`
- `isRecording`
- `isSpeaking`
- `isTranslating`

**Published Properties:** `@Published var` prefix, `lowerCamelCase` names
- `@Published var inputText: String`
- `@Published var translatedText: String`
- `@Published var sourceGeneration: Generation`

**Constants:** `UPPER_SNAKE_CASE` for true constants or `lowerCamelCase` for theme/configuration
- `AppTheme.cardPadding` — Configuration constant
- `AppTheme.cornerRadius` — Configuration constant
- Model names: `private let model = "parla"` — Service constant

**Singletons:** `.shared` convention
- `SlangDictionary.shared`
- `TranslationCache.shared`

### Method Naming

**Verbs as prefixes** for actions:
- `translate()` — Perform translation
- `toggleRecording()` — Toggle recording on/off
- `startRecording()` — Begin recording
- `stopRecording()` — End recording
- `speak()` — Perform text-to-speech
- `swapGenerations()` — Swap source/target
- `loadExample()` — Load sample phrase

**Accessor methods** for queries:
- `isAvailable()` — Boolean check
- `phrasesSorted(for:)` — Retrieve and sort
- `findEntry(for:in:)` — Lookup

### Abbreviations & Acronyms

**Full expansion preferred, but accepted:**
- `ViewModel` — Standard architectural suffix
- `UI` — Ubiquitous in UIKit context
- `JSON` — In JSON serialization methods
- `HTTP/REST` — In API integration
- `NPC`, `GG`, `FOMO`, `GYATT` — User-facing generational slang terms (preserved from dictionary)
- `NSRegularExpression` — Apple framework class
- `AVFoundation` — Apple framework
- `SFSpeech` — Apple framework

## File Organization

### Layered Organization by Responsibility

```
Parla/
├── App/              ← App lifecycle & window setup
├── Models/           ← Data structures (no logic)
├── Services/         ← Business logic & external I/O
├── ViewModels/       ← UI state management
├── Views/            ← SwiftUI UI components
│   ├── Components/  ← Reusable view pieces
│   └── *.swift      ← Screen-level views
├── Theme/            ← Design system constants
└── Resources/        ← Assets, icons, data files
```

### Logical Grouping Within Services

Services are organized by external system or domain:

- `TranslationEngine.swift` — Translation logic orchestrator
- `OllamaService.swift` — External AI service integration
- `SpeechService.swift` — External speech APIs (AVFoundation, Speech.framework)
- `TranslationCache.swift` — Data persistence (UserDefaults)
- `SlangDictionary.swift` — Domain data (generational slang)

### Logical Grouping Within Views

Views follow MVC/MVVM patterns:

- `TranslatorView.swift` — Main screen container, orchestrates components
- `SplashView.swift` — Standalone splash/loading screen
- `Components/` — Granular reusable pieces:
  - Input components: InputCard, RecordButton, WaveformView
  - Output components: OutputCard
  - Interaction components: SwapButton, GenerationSelector
  - Content components: ExampleBanner

### Comments & Code Organization

**Section markers within files:**
```swift
// MARK: - Section Name
```

Used to organize code logically:
```swift
// MARK: Estado de la UI
// MARK: Dependencias
// MARK: Ciclo de vida
// MARK: - Traduccion
// MARK: - Privados
```

**Language:** Spanish comments throughout (matching Boomer/slang domain)

### Model Relationships

**Data flow through models:**

1. **Generation** — Enum selecting language style (input to all translation operations)
2. **SlangEntry** — Concept mapping containing term synonyms for each generation
3. **TranslationExample** — Sample phrases with generation-specific text
4. **TranslatorViewModel** — Publishes Generation selections and translated text
5. **TranslatorView** — Consumes ViewModel state and passes Generation to services

**No circular dependencies:** Models are immutable and dependency-free; Services consume Models; ViewModels consume Services and publish Model data; Views consume ViewModels.

## Dependency Graph

```
Views (UI Layer)
  ↓ observes
ViewModels (@MainActor state)
  ↓ uses
Services (business logic, I/O)
  ↓ operate on
Models (pure data structures)

Specific flow:
TranslatorView
  → TranslatorViewModel (observable state)
      → TranslationEngine (translation logic)
          → TranslationCache (persistence)
          → SlangDictionary (lookup data)
          → OllamaService (external AI)
      → SpeechService (speech I/O)
      → SlangDictionary (lookup data)
  → Theme/AppTheme (design constants)
```

No circular imports; strict unidirectional dependency flow from Views down to Models.
