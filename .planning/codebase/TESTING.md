# Testing

## Framework

### Current State
- **No formal test framework configured**: XCTest target not defined in `project.yml`
- **No dedicated test files**: No `*Test.swift` or `*Tests.swift` files found in codebase
- **Manual testing approach**: Reliance on simulator/device testing and manual verification

### Recommended Frameworks
Based on codebase analysis, if testing were to be implemented:
- **XCTest**: Native Apple testing framework (compatible with Swift 6.0)
- **SwiftUI Previews**: Used for component validation (see `#Preview` blocks in components like `RecordButton`)
- **Combine Testing**: `@testable import Combine` for reactive testing
- **URLSession Mocking**: For testing `OllamaService` network calls

### Build Configuration
- Project configured via `project.yml` (XcodeGen format)
- No test target defined in targets section
- Target configuration for `Parla` only (application type, iOS platform)

## Test Structure

### SwiftUI Preview Pattern
- Components use SwiftUI Previews for visual validation:
  - `/Parla/Views/Components/RecordButton.swift` includes `#Preview` block
  - Provides lightweight UI testing for component behavior
  - Shows both active and inactive states:
    ```swift
    #Preview {
        HStack(spacing: 32) {
            RecordButton(isRecording: false, action: {})
            RecordButton(isRecording: true, action: {})
        }
        .padding()
    }
    ```

### Manual Testing Points
Based on code analysis, critical paths for testing include:

#### Service Layer (`/Parla/Services/`)
- `TranslationEngine.translateWithAI()`: Async translation with caching
  - Test cache hit/miss behavior
  - Test Ollama fallback logic
  - Test local dictionary fallback
- `TranslationEngine.translateLocal()`: Regex-based text replacement
  - Case preservation logic
  - Multi-term matching
  - Word boundary detection
- `OllamaService.translate()`: HTTP request/response handling
  - Network error scenarios
  - Response parsing
  - Timeout handling (60 second timeout configured)
- `OllamaService.isAvailable()`: Service health check
  - Successful model detection
  - Network unavailability
  - Timeout handling (3 second timeout configured)
- `SpeechService.startRecording()`: Audio capture and transcription
  - Permission handling
  - Partial result callbacks
  - Recording lifecycle
- `SpeechService.speak()`: Text-to-speech synthesis
  - Audio output
  - Speaking completion detection
- `SlangDictionary`: Dictionary initialization and lookups
  - Entry indexing
  - Case-insensitive term matching
  - Generation mapping validation
- `TranslationCache`: Cache operations
  - Persistence via UserDefaults
  - Pre-cache loading from bundle JSON
  - LRU eviction at max capacity (1000 entries)
  - Cache key generation consistency

#### ViewModel Layer (`/Parla/ViewModels/`)
- `TranslatorViewModel.translate()`: Main translation orchestration
  - Input validation (empty string handling)
  - Debounce behavior (500ms)
  - Task cancellation
  - Ollama availability switching
  - State updates on MainActor
- `TranslatorViewModel.toggleRecording()`: Recording state management
  - Permission flow
  - Audio engine initialization
  - Partial result propagation
- `TranslatorViewModel.toggleSpeaking()`: Speech output
  - Speaking state management
  - Monitor lifecycle
- `TranslatorViewModel.swapGenerations()`: Generation swap with animation
  - State swap correctness
  - Automatic re-translation

#### View Layer (`/Parla/Views/`)
- `TranslatorView`: Main UI composition
  - Layout rendering
  - State binding correctness
  - onChange callbacks firing
- Component Views: Button states, text input, output display
  - User interaction handling
  - Accessibility labels (e.g., RecordButton has "Detener grabacion" and "Grabar voz" labels)

### Testable Components
Based on architecture, these would be ideal for unit testing:
1. **Pure Functions**: `TranslationEngine.preserveCase()` - case preservation logic
2. **Service Methods**: All public methods in services marked as `Sendable`
3. **Model Methods**: `SlangEntry.primary()`, `SlangEntry.terms()`, `Generation` computed properties
4. **Cache Operations**: `TranslationCache.get()`, `TranslationCache.set()`

### Hard-to-Test Components
- `SpeechService`: Depends on AVAudioEngine, AVSpeechSynthesizer, SFSpeechRecognizer (require mocking)
- View rendering: Requires snapshot testing or UIKit integration tests
- Network calls: Require URLSession mocking or test server
- Async operations: Require async/await testing utilities

## Mocking Patterns

### Not Yet Implemented
No formal mocking infrastructure exists in the codebase.

### Recommended Mocking Strategy

#### Service Mocking
- **Protocol-based design** for dependency injection (not currently used, would require refactoring):
  ```swift
  protocol TranslationServiceProtocol {
      func translateWithAI(...) async throws -> String
      func translateLocal(...) -> String
  }
  ```
- Create mock implementations for testing

#### URLSession Mocking
- For `OllamaService` network calls in `translate()` and `isAvailable()`:
  - Use `URLProtocol` subclass to intercept HTTP requests
  - Provide canned responses for success/failure scenarios
  - Mock timeout scenarios

#### Audio Framework Mocking
- `SpeechService` uses:
  - `AVAudioEngine`: Would require mock audio buffer creation
  - `SFSpeechRecognizer`: Would require `SFSpeechRecognitionRequest` mocking
  - `AVSpeechSynthesizer`: Would need to mock synthesis completion callbacks

#### Cache Mocking
- `TranslationCache` uses `UserDefaults.standard`
- Test approach: Create test-specific UserDefaults suite for isolation
- Or: Inject UserDefaults dependency (currently hardcoded)

### Current Debugging Infrastructure
The codebase includes print-based logging for debugging:
- Color-coded debug output in `OllamaService`:
  - 🔵 blue: Ollama availability check
  - 🟡 yellow: Raw JSON response
  - 🟠 orange: Content before cleaning
  - 🟣 purple: Prompt sent
  - 🟢 green: Final response
- Helps with manual testing and debugging of Ollama integration

## Coverage

### Current Coverage: 0%
- No test files exist in the project
- No CI-based coverage reporting configured

### Coverage Targets (if implemented)
Critical paths by priority:

1. **High Priority** (business logic):
   - `TranslationEngine.translateLocal()` - core translation algorithm
   - `TranslationEngine.preserveCase()` - case preservation edge cases
   - `TranslationCache` - persistence and eviction logic
   - `SlangDictionary.buildEntries()` - dictionary initialization

2. **Medium Priority** (user-facing features):
   - `TranslatorViewModel.translate()` - debounce and task cancellation
   - `TranslatorViewModel` state management
   - `OllamaService.translate()` - HTTP handling
   - `SpeechService` - audio capture state transitions

3. **Low Priority** (UI/presentation):
   - View rendering (use snapshot/component testing)
   - Theme and styling verification
   - Animation timing

### Estimated Coverage
If all testable code were covered:
- Services: ~70-80% easily testable (networking requires mocking)
- ViewModels: ~60-70% (async/state management requires async testing)
- Models: ~95%+ (simple data structures with pure functions)
- Views: ~30-40% (UI testing requires specific tools)

## CI Integration

### Current CI Setup: None
- No `.github/workflows/` directory
- No GitHub Actions configuration
- No CircleCI, Travis CI, or other CI provider config visible

### Recommended CI Configuration
If CI/CD were to be implemented:

#### Suggested GitHub Actions Workflow
Location: `.github/workflows/test.yml`

Key stages:
1. **Build Stage**
   - Swift 6.0 compilation
   - Pod dependencies (if added)
   - XCTest target build

2. **Test Stage**
   - Unit tests via `xcodebuild test`
   - Code coverage reporting with `xcov` or similar
   - Coverage thresholds (e.g., 70% minimum)

3. **Lint Stage** (not currently configured)
   - SwiftLint (referenced in code via `swiftlint:disable` comments)
   - Format checking

4. **Archive/Deploy Stage**
   - TestFlight upload
   - App Store Connect integration

#### SwiftLint Integration
The codebase already references SwiftLint:
- Disable comments in `SlangDictionary.swift`: `// swiftlint:disable:previous strict_concurrency`
- Disable comments in `SlangDictionary.swift`: `// swiftlint:disable function_body_length`
- Indicates SwiftLint is part of build process
- Configuration file likely present but not visible in analysis

#### Test Configuration Requirements
```yaml
# Would be needed in project.yml for test target:
targets:
  ParlaTests:
    type: bundle.unit-test
    sources:
      - path: ParlaTests
    dependencies:
      - target: Parla
```

#### Platform Targets
- iOS Simulator (arm64, x86_64)
- iOS Device (arm64)
- Minimum iOS 26.0

#### Performance Considerations
- Async/await tests require `Task.detached` or similar for isolation
- Ollama service tests would need network mocking to avoid timeouts
- Speech framework tests require special permissions/entitlements
- Cache tests need fresh UserDefaults isolation per test

### Manual Testing Checklist
Based on code functionality:

**Translation Features**
- [ ] Text input translation with debounce
- [ ] Voice recording to text
- [ ] Audio output of translated text
- [ ] Generation swapping and retranslation
- [ ] Example banner loading
- [ ] Cache persistence across app restarts
- [ ] Ollama availability detection

**Fallback Behaviors**
- [ ] Translation succeeds with Ollama available
- [ ] Graceful fallback to local dictionary when Ollama unavailable
- [ ] Graceful fallback when Ollama times out
- [ ] Case preservation in translations

**Permissions**
- [ ] Microphone permission request flow
- [ ] Speech recognition permission request flow
- [ ] Permission denial handling

**Edge Cases**
- [ ] Empty input handling
- [ ] Very long input (>500 chars)
- [ ] Special characters in input
- [ ] Network timeout scenarios
- [ ] Cache eviction at max capacity
