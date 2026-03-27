import SwiftUI

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
