# Conventions

## Code Style

### Swift Version
- Swift 6.0 (specified in `project.yml`)
- iOS 26.0 deployment target

### Type Declarations
- Primarily uses `struct` for Views (SwiftUI patterns)
- Uses `final class` for ViewModels and Services to prevent subclassing:
  - `TranslatorViewModel` in `/Parla/ViewModels/TranslatorViewModel.swift`
  - `TranslationEngine` in `/Parla/Services/TranslationEngine.swift`
  - `OllamaService` in `/Parla/Services/OllamaService.swift`
  - `SpeechService` in `/Parla/Services/SpeechService.swift`
  - `SlangDictionary` in `/Parla/Services/SlangDictionary.swift`
  - `TranslationCache` in `/Parla/Services/TranslationCache.swift`

### Access Control
- Default to `private` for internal methods and properties
- Use `nonisolated(unsafe)` for thread-unsafe properties in Sendable types (e.g., UserDefaults access)
- Explicit `private` modifier on helper methods
- `public` only when necessary for inter-module communication

### Code Organization
- Extensive use of `// MARK:` comments for section organization (60+ occurrences across codebase)
- Pattern: `// MARK: - Section Title` with dashes for visual separation
- Sections typically group related functionality (e.g., "// MARK: - Traduccion", "// MARK: - Ciclo de vida")
- Views organized as: SubViews (computed properties) then Preview

### Naming Conventions
- **Classes**: PascalCase (e.g., `TranslatorViewModel`, `OllamaService`)
- **Properties/Methods**: camelCase (e.g., `sourceGeneration`, `translatedText`, `inputDidChange()`)
- **Private Methods**: camelCase with clear verb prefixes (e.g., `startRecording()`, `checkOllamaAvailability()`)
- **Functions**: Descriptive, action-oriented names (e.g., `translateWithAI()`, `translateLocal()`, `isAvailable()`)
- **Constants**: camelCase in static enums (e.g., `AppTheme.accent`, `AppTheme.cardPadding`)

### Comments & Documentation
- Spanish language comments throughout for a Spanish-focused project
- Method documentation using `///` for public APIs with descriptions of behavior
- Inline comments explaining non-obvious logic (e.g., regex patterns, cache strategies)
- Comment headers in Spanish matching project locale (e.g., "MARK: - Diccionario central de jerga generacional")

## Naming Patterns

### View Components
- All Views in `/Parla/Views` subdirectories follow SwiftUI naming
- Component Views suffixed with `View` (e.g., `TranslatorView`, `RecordButton`, `OutputCard`)
- Located in `/Parla/Views/Components/` for reusable UI elements
- Main views in `/Parla/Views/`

### View Models
- Suffixed with `ViewModel` (e.g., `TranslatorViewModel`)
- Located in `/Parla/ViewModels/`
- Single MVVM pattern with @Published properties for UI binding

### Services
- Suffixed with `Service` (e.g., `SpeechService`, `OllamaService`)
- Located in `/Parla/Services/`
- Stateless or managed state (cache, dictionary)

### Models & Data
- Suffixed with appropriate noun (e.g., `SlangEntry`, `Generation`, `TranslationExample`)
- Located in `/Parla/Models/`
- Lightweight data structures with helper methods

## Common Patterns

### MVVM Architecture
- Clean separation: Views → ViewModels → Services → Models
- File structure mirrors this pattern:
  - `/Parla/Views/` - SwiftUI view components
  - `/Parla/ViewModels/` - @MainActor observable objects
  - `/Parla/Services/` - Business logic and data access
  - `/Parla/Models/` - Data structures
  - `/Parla/Theme/` - Shared styling

### Async/Await Pattern
- Modern Swift concurrency used throughout:
  - `async throws` for network operations (e.g., `TranslationEngine.translateWithAI()`)
  - `@MainActor` annotation for thread safety in ViewModels
  - `Task` for async work from sync context
  - Proper task cancellation with `Task.isCancelled` checks

### Dependency Injection
- Services accessed via singletons:
  - `SlangDictionary.shared` in `/Parla/Services/SlangDictionary.swift`
  - `TranslationCache.shared` in `/Parla/Services/TranslationCache.swift`
  - Local instantiation in ViewModels for injectable dependencies:
    - `private let engine = TranslationEngine()` in `TranslatorViewModel`
    - `private let speech = SpeechService()` in `TranslatorViewModel`

### State Management
- @Published properties for observable state in ViewModels
- @State for local UI state in Views
- @StateObject for ViewModel lifecycle management
- Combine framework for reactive updates

### Caching Strategy
- Three-tier translation strategy in `TranslationEngine`:
  1. Cache check → `TranslationCache.get()`
  2. AI (Ollama) call with `await OllamaService.translate()`
  3. Local dictionary fallback with `translateLocal()`
- Pre-cached translations from `PrecachedTranslations.json` (bundled)
- LRU cache eviction when reaching max entries (1000 entries)

### Closure-based Callbacks
- SpeechService uses completion handlers instead of async/await for compatibility
- Example: `requestPermissions(completion: @escaping (Bool) -> Void)`
- Callbacks marshaled back to MainThread in ViewModel

### Debouncing Pattern
- Text input translation uses debounce timer (500ms)
- Implemented via `Task.sleep(for: .milliseconds(500))`
- Previous task cancelled before starting new one to prevent race conditions

### Property Wrappers Usage
- **@Published**: Observable state in ViewModels (28+ occurrences)
- **@State**: Local UI state in Views
- **@StateObject**: Lifecycle management of ViewModels
- **@MainActor**: Thread safety for UI updates

## Error Handling

### Error Types
- Custom error enum with `LocalizedError` conformance:
  - `OllamaError` in `/Parla/Services/OllamaService.swift` with cases:
    - `.serverError` - Ollama service unavailable
    - `.invalidResponse` - Malformed API response
- Localized error descriptions in Spanish

### Error Handling Strategy
- **Try/Catch Blocks**: Used in service layer for network operations
- **Guard Statements**: Preferred for conditional unwrapping and early returns
- **Graceful Degradation**:
  - Ollama failures fall back to local dictionary automatically
  - Empty string checks prevent processing invalid input
  - Network timeout set to 60 seconds for translation requests, 3 seconds for availability checks

### HTTP Error Handling
- Status code validation: `guard let http = response as? HTTPURLResponse, http.statusCode == 200`
- Network errors wrapped and thrown to caller
- Logging of failures for debugging (see print statements with color codes)

### Async Task Cancellation
- Explicit `Task.isCancelled` checks to prevent state updates on cancelled tasks
- Example in `TranslatorViewModel.translate()`:
  ```swift
  translationTask?.cancel()
  // ... async work ...
  guard !Task.isCancelled else { return }
  ```
- Prevents memory leaks and race conditions

## Import Organization

### Standard Pattern
Imports organized in this order:
1. Foundation/System frameworks (e.g., `import Foundation`)
2. Platform frameworks (e.g., `import AVFoundation`, `import Speech`)
3. UI framework (e.g., `import SwiftUI`)
4. Combine framework (e.g., `import Combine`)

### Common Frameworks Used
- **Foundation**: Core data types, JSON encoding, UserDefaults
- **SwiftUI**: UI framework for all Views
- **Combine**: Reactive programming (Publishers, Subscribers)
- **AVFoundation**: Audio recording and speech synthesis
- **Speech**: Speech recognition framework

### Framework Examples by File
- `/Parla/App/ParlaApp.swift`: `import SwiftUI`
- `/Parla/ViewModels/TranslatorViewModel.swift`: `import Combine`, `import SwiftUI`
- `/Parla/Services/OllamaService.swift`: `import Foundation` (network operations)
- `/Parla/Services/SpeechService.swift`: `import AVFoundation`, `import Speech`
- `/Parla/Models/Generation.swift`: `import SwiftUI` (Color usage)
- `/Parla/Theme/AppTheme.swift`: `import SwiftUI` (Theming)

### No Import of Project-Internal Types
- Services and ViewModels use only framework types or custom models defined in same module
- Clean module boundaries maintained through minimal imports

### Third-Party Dependencies
- No CocoaPods or external dependencies visible in configuration
- Self-contained implementation leveraging native iOS frameworks
