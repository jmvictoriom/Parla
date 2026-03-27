import SwiftUI

// MARK: - Nivel de exageracion

enum ExaggerationLevel: String, CaseIterable, Identifiable {
    case suave = "Suave"
    case normal = "Normal"
    case extremo = "Extremo"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .suave: return "😌"
        case .normal: return "😄"
        case .extremo: return "🤪"
        }
    }

    /// Instruccion adicional que se inyecta en el prompt para Gemini.
    var promptInstruction: String {
        switch self {
        case .suave:
            return "NIVEL DE EXAGERACION: SUAVE. Traduce de forma natural y sutil. Usa equivalentes generacionales pero sin forzar estereotipos. El resultado debe sonar como alguien que habla asi naturalmente, sin exagerar."
        case .normal:
            return "NIVEL DE EXAGERACION: NORMAL. Traduce con el nivel estandar de jerga generacional. Usa las expresiones tipicas de cada generacion de forma natural."
        case .extremo:
            return "NIVEL DE EXAGERACION: EXTREMO. Exagera al maximo los estereotipos generacionales. Un boomer debe sonar como el abuelo mas castizo del pueblo, con refranes, \"madre del amor hermoso\", \"fijate tu\", \"en mis tiempos\". Un Gen Z debe sonar como el tiktoker mas intenso: lleno de anglicismos, \"bro\" en cada frase, \"no cap fr fr\", \"literally dead\". Cuanto mas exagerado mejor."
        }
    }

    /// Temperatura de Gemini ajustada al nivel.
    var temperature: Double {
        switch self {
        case .suave: return 0.3
        case .normal: return 0.6
        case .extremo: return 0.9
        }
    }
}

// MARK: - Generaciones

enum Generation: String, CaseIterable, Identifiable, Codable {
    case newGen = "Nuevas generaciones"
    case boomer = "Boomer"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .newGen: return "⚡"
        case .boomer: return "📰"
        }
    }

    var color: Color {
        switch self {
        case .newGen: return .purple
        case .boomer: return .orange
        }
    }

    var shortName: String {
        switch self {
        case .newGen: return "Nuevas gen."
        case .boomer: return "Boomer"
        }
    }

    var yearRange: String {
        switch self {
        case .newGen: return "1997 +"
        case .boomer: return "1946 – 1964"
        }
    }

    var tagline: String {
        switch self {
        case .newGen: return "Slay, bro, no cap..."
        case .boomer: return "Estupendo, fenomenal..."
        }
    }
}
