# Integrations

## External APIs

### Ollama LLM API
- **Service**: Ollama (open-source local LLM server)
- **Endpoint**: `POST http://[baseURL]:11434/api/chat`
- **Base URL Configuration**: Defined in `/Parla/Services/OllamaService.swift` (default: `http://127.0.0.1:11434`)
- **Model**: Custom `parla` model (based on Qwen3:8b)
- **API Client**: Native `URLSession` in `/Parla/Services/OllamaService.swift`
- **Request Format**:
  ```json
  {
    "model": "parla",
    "messages": [
      {"role": "system", "content": "System prompt with translation rules"},
      {"role": "user", "content": "[Generation → Generation] text /no_think"}
    ],
    "stream": false,
    "options": {
      "temperature": 0.6,
      "top_p": 0.9,
      "num_predict": 500
    }
  }
  ```
- **Health Check**: `GET http://[baseURL]:11434/api/tags` to verify model availability
- **Error Handling**: Throws `OllamaError` (serverError, invalidResponse) with fallback to local dictionary
- **Timeout**: 60 seconds for translation requests, 3 seconds for health checks

## Databases

### Local Storage (UserDefaults)
- **Service**: iOS `UserDefaults`
- **Location**: `/Parla/Services/TranslationCache.swift`
- **Storage Key**: `parla_translation_cache_v3`
- **Purpose**: Persistent caching of AI-generated translations
- **Max Entries**: 1,000 translations (with FIFO eviction policy)
- **Format**: Dictionary `[String: String]` where key = `"[Generation]>[Generation]>[normalized_text]"`

### Precached Translations Bundle
- **File**: `/Parla/Resources/PrecachedTranslations.json` (27.4 KB)
- **Format**: JSON dictionary with 100+ pre-generated translations
- **Load Strategy**: Loaded once at app startup if not previously cached
- **Storage Flag**: `parla_precache_loaded_v3`
- **Purpose**: Instant offline translations without Ollama dependency

### Embedded Dictionary
- **Location**: `/Parla/Services/SlangDictionary.swift`
- **Type**: In-memory term-to-concept mapping
- **Concepts**: 80+ generational slang concepts (e.g., "cool", "attractive", "charisma")
- **Mappings**: Bidirectional translations between Boomer ↔ Nuevas generaciones
- **Index Structure**: Three-level indexing for performance (Generation → Term → SlangEntry)
- **Fallback Role**: Used when Ollama is unavailable or request fails

## Auth Providers

### None
Parla does not integrate with external authentication services. The app operates entirely offline/locally with:
- No user accounts required
- No cloud synchronization
- No authentication APIs
- Permissions handled through iOS native permission system (microphone, speech recognition)

## Third-Party Services

### None
Parla does not depend on third-party cloud services. The stack is self-contained:
- No analytics/telemetry services
- No crash reporting (Sentry, Bugsnag, etc.)
- No CDN for assets
- No push notification services
- No social media APIs
- **Exception**: Ollama server (self-hosted or deployed by user)

## Webhooks & Events

### None
Parla does not use webhooks or event streaming services. Communication is strictly request-response:
- **Synchronous HTTP calls only** to Ollama `/api/chat` endpoint
- **No streaming**: `"stream": false` in Ollama requests
- **No real-time messaging**: All updates are UI state-driven
- **Local event handling**: Combine framework for reactive UI updates

## Deployment & Infrastructure

### Server-Side Components
- **Ollama Container** (`/server/docker-compose.yml`)
  - Image: `ollama/ollama:latest`
  - Port: 11434 (TCP)
  - Memory: 8GB reserved
  - Volume: Persistent `/root/.ollama` for model storage
  - Restart Policy: `unless-stopped`

- **Model Setup Service** (`/server/docker-compose.yml`)
  - Pulls base model: `qwen3:8b`
  - Builds custom model from `/server/Modelfile`
  - Registers model as: `parla`
  - Health check: Polls `/api/tags` endpoint until ready

### Deployment Options
- **Local Development**: Simulator/device connected to Mac running Ollama on `127.0.0.1:11434`
- **Remote VPS**: Ubuntu 24 LTS with Docker + Docker Compose (automated via `/server/deploy.sh`)
- **Network Requirements**:
  - App ↔ Ollama requires HTTP connectivity on port 11434
  - Firewall rules configured in deployment script (UFW)
  - Local network access enabled in app permissions

## Data Flow Summary

```
User Input (Voice/Text)
    ↓
[Voice → Text via Speech Framework]
    ↓
TranslationCache.get() → TranslationEngine
    ↓
If cached: Return instantly
If not cached → OllamaService.translate()
    ↓
HTTP POST to Ollama /api/chat endpoint
    ↓
Ollama (Qwen3:8b with custom system prompt)
    ↓
Response → Cache → UI
    ↓
[Optional: Text → Voice via AVSpeechSynthesizer]
    ↓
User Output (Translated Text/Speech)
```

**Fallback Chain**:
1. Check TranslationCache (in-memory + UserDefaults)
2. Query Ollama API if cache miss
3. Fall back to SlangDictionary (local regex-based matching)
4. Return original text if all else fails
