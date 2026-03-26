# Stack

## Languages & Runtime
- **Swift 6.0** - Primary language for iOS app development
- **Python** - Build/setup scripts (`precache.py`, `precache2.py`)
- **Bash** - Deployment and Docker setup scripts

## Frameworks & Libraries

### iOS App (SwiftUI)
- **SwiftUI** - Modern UI framework for iOS 26.0+ (defined in `project.yml`)
- **Combine** - Reactive programming framework for async operations and state management
- **Foundation** - Core utilities including URLSession, UserDefaults, JSONSerialization
- **AVFoundation** - Audio recording and playback capabilities
- **Speech Framework** - Native speech-to-text recognition (`SFSpeechRecognizer`, `SFSpeechAudioBufferRecognitionRequest`)
- **AVSpeechSynthesizer** - Text-to-speech synthesis for Spanish language output

### Server/Backend
- **Ollama** - Open-source LLM server for running the Qwen3 model
- **Docker & Docker Compose** - Containerization for deployment

## Key Dependencies

### Internal Services (`/Parla/Services/`)
- **`OllamaService.swift`** - HTTP client for communicating with Ollama's `/api/chat` endpoint
- **`SpeechService.swift`** - Encapsulates voice recording and TTS functionality
- **`TranslationEngine.swift`** - Translation orchestration with cache + AI + fallback strategy
- **`TranslationCache.swift`** - In-memory and disk-based translation caching using `UserDefaults`
- **`SlangDictionary.swift`** - Embedded generational slang dictionary with 80+ concepts

### Data Models (`/Parla/Models/`)
- **`Generation.swift`** - Enum for generational types (Boomer / Nuevas generaciones)
- **`SlangEntry.swift`** - Data structure for slang term mappings
- **`TranslationExample.swift`** - Sample translations for UI examples

### UI Components (`/Parla/Views/`)
- **`TranslatorView.swift`** - Main translator interface
- **`SplashView.swift`** - Launch screen
- **Components/**
  - `WaveformView.swift` - Real-time audio waveform visualization
  - `RecordButton.swift` - Voice recording trigger
  - `SwapButton.swift` - Generation swap button
  - `OutputCard.swift` - Translation display card
  - `InputCard.swift` - Text/voice input card
  - `GenerationSelector.swift` - Generation picker
  - `ExampleBanner.swift` - Example translations showcase

### Theme (`/Parla/Theme/`)
- **`AppTheme.swift`** - Color scheme and styling constants

## Configuration

### iOS App Configuration
- **`project.yml`** - XCode project structure and build configuration
  - Bundle ID: `com.parla`
  - Deployment Target: iOS 26.0
  - Swift Version: 6.0
  - Marketing Version: 1.0.0
  - Microphone permissions required
  - Speech recognition permissions required
  - Local network access enabled (`NSAllowsLocalNetworking`)

### Server Configuration
- **`/server/docker-compose.yml`** - Containerized Ollama setup
  - Ollama service on port 11434
  - 8GB memory allocation
  - Custom Parla model creation from Qwen3:8b base
- **`/server/Modelfile`** - Ollama model configuration (Qwen3 8B with custom system prompt)
- **`/server/deploy.sh`** - Ubuntu 24 VPS deployment automation

### App Resources
- **`/Parla/Info.plist`** - iOS manifest with permissions and app metadata
- **`/Parla/Resources/PrecachedTranslations.json`** - Pre-generated translation cache (27.4 KB)
- **`/Parla/Resources/Assets.xcassets/`** - App icons, colors, and UI assets

## Build & Deploy

### Local Development
- **Xcode project** - `/Parla.xcodeproj` for iOS simulator and device builds
- **XCode 26.0** compatibility
- Light color scheme preference for UI

### Server Deployment
- **Docker-based deployment** (`/server/deploy.sh`)
- Automated setup of Ollama with Qwen3:8b model
- UFW firewall rules for port 11434
- Configurable Ollama host (default: `http://127.0.0.1:11434`)
- Support for remote deployment via SSH

### Resource Generation
- **`precache.py`** and **`precache2.py`** - Scripts for generating pre-cached translations (stored in `PrecachedTranslations.json`)

### Endpoints & Architecture
- **API Endpoint**: `http://[OLLAMA_HOST]:11434/api/chat`
- **Model Name**: `parla` (custom Qwen3 8B variant)
- **Request Format**: JSON with system prompt and user message
- **Response Handling**: Extracts `message.content` from JSON response
