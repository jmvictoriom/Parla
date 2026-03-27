import Foundation

// MARK: - Diccionario central de jerga generacional

final class SlangDictionary: Sendable {

    static let shared = SlangDictionary()
    // swiftlint:disable:previous strict_concurrency

    let entries: [SlangEntry]
    private let index: [Generation: [String: SlangEntry]]
    private let sortedTerms: [Generation: [(term: String, entry: SlangEntry, regex: NSRegularExpression)]]

    private init() {
        let all = Self.buildEntries()
        self.entries = all

        var idx: [Generation: [String: SlangEntry]] = [:]
        for gen in Generation.allCases {
            var map: [String: SlangEntry] = [:]
            for entry in all {
                for term in entry.terms(for: gen) {
                    map[term.lowercased()] = entry
                }
            }
            idx[gen] = map
        }
        self.index = idx

        // Pre-compilar regexes para cada termino (ordenados por longitud descendente)
        var sorted: [Generation: [(String, SlangEntry, NSRegularExpression)]] = [:]
        for gen in Generation.allCases {
            let pairs = idx[gen]?.map { ($0.key, $0.value) } ?? []
            sorted[gen] = pairs
                .sorted { $0.0.count > $1.0.count }
                .compactMap { (term, entry) in
                    let escaped = NSRegularExpression.escapedPattern(for: term)
                    let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
                    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
                    return (term, entry, regex)
                }
        }
        self.sortedTerms = sorted
    }

    func findEntry(for term: String, in generation: Generation) -> SlangEntry? {
        index[generation]?[term.lowercased()]
    }

    func phrasesSorted(for generation: Generation) -> [(term: String, entry: SlangEntry, regex: NSRegularExpression)] {
        sortedTerms[generation] ?? []
    }

    var conceptCount: Int { entries.count }
}

// MARK: - Entradas del diccionario  (newGen ↔ boomer)

extension SlangDictionary {

    // swiftlint:disable function_body_length
    static func buildEntries() -> [SlangEntry] {
        [
            // ============================
            // MARK: Cualidades positivas
            // ============================

            SlangEntry(concept: "cool", mappings: [
                .newGen: ["god", "slay", "basado"],
                .boomer: ["increible", "brutal", "genial"]
            ]),
            SlangEntry(concept: "amazing", mappings: [
                .newGen: ["devorar", "petarlo"],
                .boomer: ["arrasar", "estar increible"]
            ]),
            SlangEntry(concept: "perfect", mappings: [
                .newGen: ["fantasia", "nashe"],
                .boomer: ["perfecto", "genial"]
            ]),
            SlangEntry(concept: "very_good", mappings: [
                .newGen: ["buenardo", "PEC"],
                .boomer: ["buenisimo", "de lo mejor"]
            ]),
            SlangEntry(concept: "attractive", mappings: [
                .newGen: ["fachero", "face card"],
                .boomer: ["esta muy bueno", "es guapo"]
            ]),
            SlangEntry(concept: "charisma", mappings: [
                .newGen: ["rizz"],
                .boomer: ["labia", "encanto"]
            ]),
            SlangEntry(concept: "style", mappings: [
                .newGen: ["flow"],
                .boomer: ["estilo", "rollo"]
            ]),
            SlangEntry(concept: "transformation", mappings: [
                .newGen: ["glow up"],
                .boomer: ["menudo cambio", "vaya cambiazo"]
            ]),
            SlangEntry(concept: "easy", mappings: [
                .newGen: ["six seven", "easy"],
                .boomer: ["facilisimo", "pan comido"]
            ]),
            SlangEntry(concept: "true_facts", mappings: [
                .newGen: ["factos", "facts"],
                .boomer: ["totalmente", "exacto", "tal cual"]
            ]),
            SlangEntry(concept: "seriously", mappings: [
                .newGen: ["no cap"],
                .boomer: ["de verdad", "en serio"]
            ]),
            SlangEntry(concept: "honest", mappings: [
                .newGen: ["basado"],
                .boomer: ["sin filtros", "va de frente"]
            ]),

            // ============================
            // MARK: Cualidades negativas
            // ============================

            SlangEntry(concept: "cringe", mappings: [
                .newGen: ["cringe"],
                .boomer: ["verguenza ajena", "penoso"]
            ]),
            SlangEntry(concept: "bad", mappings: [
                .newGen: ["malardo"],
                .boomer: ["horrible", "pesimo", "una mierda"]
            ]),
            SlangEntry(concept: "failed", mappings: [
                .newGen: ["flopear"],
                .boomer: ["fracasar", "salir mal"]
            ]),
            SlangEntry(concept: "embarrassing", mappings: [
                .newGen: ["lache"],
                .boomer: ["que corte", "que verguenza"]
            ]),
            SlangEntry(concept: "suspicious", mappings: [
                .newGen: ["sus"],
                .boomer: ["raro", "sospechoso", "no me fio"]
            ]),
            SlangEntry(concept: "outdated", mappings: [
                .newGen: ["cheugy", "charca"],
                .boomer: ["pasado de moda", "desfasado"]
            ]),
            SlangEntry(concept: "mediocre", mappings: [
                .newGen: ["mid"],
                .boomer: ["mediocre", "normalito"]
            ]),
            SlangEntry(concept: "confused", mappings: [
                .newGen: ["bugueado"],
                .boomer: ["empanado", "ido", "no se entera"]
            ]),

            // ============================
            // MARK: Personas
            // ============================

            SlangEntry(concept: "friend", mappings: [
                .newGen: ["bro"],
                .boomer: ["tio", "oye", "colega"]
            ]),
            SlangEntry(concept: "best_friend", mappings: [
                .newGen: ["bestie"],
                .boomer: ["mi mejor amiga", "mi amiga de siempre"]
            ]),
            SlangEntry(concept: "buddy", mappings: [
                .newGen: ["pana", "neri"],
                .boomer: ["colega", "compi"]
            ]),
            SlangEntry(concept: "genius", mappings: [
                .newGen: ["crack"],
                .boomer: ["crack", "genio"]
            ]),
            SlangEntry(concept: "newbie", mappings: [
                .newGen: ["noob"],
                .boomer: ["novato", "no tiene ni idea"]
            ]),
            SlangEntry(concept: "showoff_person", mappings: [
                .newGen: ["flexero"],
                .boomer: ["presumido", "chulo"]
            ]),
            SlangEntry(concept: "critic", mappings: [
                .newGen: ["hater"],
                .boomer: ["envidioso", "toxico"]
            ]),
            SlangEntry(concept: "obsessive_fan", mappings: [
                .newGen: ["stan"],
                .boomer: ["superfan", "obsesionado"]
            ]),
            SlangEntry(concept: "tryhard_person", mappings: [
                .newGen: ["tryhard"],
                .boomer: ["intenso", "se esfuerza demasiado"]
            ]),
            SlangEntry(concept: "loner", mappings: [
                .newGen: ["sigma"],
                .boomer: ["va a su bola", "lobo solitario"]
            ]),
            SlangEntry(concept: "mindless_person", mappings: [
                .newGen: ["NPC"],
                .boomer: ["borreguito", "no tiene personalidad"]
            ]),
            SlangEntry(concept: "confident_man", mappings: [
                .newGen: ["chad"],
                .boomer: ["es un maquina", "un tio con todas las letras"]
            ]),
            SlangEntry(concept: "pick_me_person", mappings: [
                .newGen: ["pick me"],
                .boomer: ["va de especial", "busca atencion"]
            ]),

            // ============================
            // MARK: Relaciones
            // ============================

            SlangEntry(concept: "crush", mappings: [
                .newGen: ["crush"],
                .boomer: ["la persona que me gusta", "me mola"]
            ]),
            SlangEntry(concept: "situationship", mappings: [
                .newGen: ["situationship"],
                .boomer: ["un rollo raro", "no somos nada oficial"]
            ]),
            SlangEntry(concept: "early_dating", mappings: [
                .newGen: ["talking stage"],
                .boomer: ["estamos tonteando", "estamos en ello"]
            ]),
            SlangEntry(concept: "secret_affair", mappings: [
                .newGen: ["sneaky link"],
                .boomer: ["lio secreto", "rollo a escondidas"]
            ]),
            SlangEntry(concept: "toxic_partner", mappings: [
                .newGen: ["toxico", "toxica"],
                .boomer: ["toxico", "controlador"]
            ]),
            SlangEntry(concept: "devoted_lover", mappings: [
                .newGen: ["simp"],
                .boomer: ["esta pillado", "esta colgado"]
            ]),
            SlangEntry(concept: "sudden_rejection", mappings: [
                .newGen: ["ick"],
                .boomer: ["me da rechazo", "se me quitaron las ganas"]
            ]),
            SlangEntry(concept: "warning_sign", mappings: [
                .newGen: ["red flag"],
                .boomer: ["mala senal", "no pinta bien"]
            ]),
            SlangEntry(concept: "good_sign", mappings: [
                .newGen: ["green flag"],
                .boomer: ["buena senal", "eso mola"]
            ]),

            // ============================
            // MARK: Acciones
            // ============================

            SlangEntry(concept: "show_off", mappings: [
                .newGen: ["flexear"],
                .boomer: ["presumir", "fardar"]
            ]),
            SlangEntry(concept: "showing_off", mappings: [
                .newGen: ["flexeando"],
                .boomer: ["presumiendo", "fardando"]
            ]),
            SlangEntry(concept: "ignore", mappings: [
                .newGen: ["ghostear"],
                .boomer: ["dejar de hablar", "ignorar"]
            ]),
            SlangEntry(concept: "ignoring", mappings: [
                .newGen: ["ghosteando"],
                .boomer: ["ignorando", "pasando de"]
            ]),
            SlangEntry(concept: "ignored_past", mappings: [
                .newGen: ["ghosteo"],
                .boomer: ["paso de mi", "me ignoro"]
            ]),
            SlangEntry(concept: "spy_on", mappings: [
                .newGen: ["stalkear"],
                .boomer: ["espiar", "cotillear el perfil"]
            ]),
            SlangEntry(concept: "stalking", mappings: [
                .newGen: ["stalkeando"],
                .boomer: ["espiando", "cotilleando"]
            ]),
            SlangEntry(concept: "provoke", mappings: [
                .newGen: ["trolear"],
                .boomer: ["provocar", "vacillar"]
            ]),
            SlangEntry(concept: "ship", mappings: [
                .newGen: ["shippear"],
                .boomer: ["emparejar", "juntar"]
            ]),
            SlangEntry(concept: "cancel_publicly", mappings: [
                .newGen: ["funar", "cancelar"],
                .boomer: ["señalar", "denunciar"]
            ]),
            SlangEntry(concept: "cancelled_past", mappings: [
                .newGen: ["funaron", "cancelaron"],
                .boomer: ["la señalaron", "la denunciaron"]
            ]),
            SlangEntry(concept: "block", mappings: [
                .newGen: ["banear"],
                .boomer: ["bloquear", "echar"]
            ]),
            SlangEntry(concept: "boast", mappings: [
                .newGen: ["frontear"],
                .boomer: ["ir de chulo", "darse aires"]
            ]),
            SlangEntry(concept: "dance", mappings: [
                .newGen: ["perrear"],
                .boomer: ["bailar reggaeton", "perrear"]
            ]),
            SlangEntry(concept: "appear_suddenly", mappings: [
                .newGen: ["spawnear"],
                .boomer: ["aparecer de la nada", "presentarse"]
            ]),
            SlangEntry(concept: "carry_team", mappings: [
                .newGen: ["carrilear", "carrear"],
                .boomer: ["llevar el peso", "tirar del carro"]
            ]),
            SlangEntry(concept: "accumulate", mappings: [
                .newGen: ["farmear aura"],
                .boomer: ["hacerse un nombre", "ganar reputacion"]
            ]),
            SlangEntry(concept: "expose_data", mappings: [
                .newGen: ["doxear"],
                .boomer: ["airear", "sacar los trapos"]
            ]),
            SlangEntry(concept: "succeed_greatly", mappings: [
                .newGen: ["la rompe", "devoro"],
                .boomer: ["la esta rompiendo", "se lucio"]
            ]),

            // ============================
            // MARK: Comunicacion
            // ============================

            SlangEntry(concept: "literally", mappings: [
                .newGen: ["literal"],
                .boomer: ["de verdad", "en serio"]
            ]),
            SlangEntry(concept: "filler_word", mappings: [
                .newGen: ["en plan"],
                .boomer: ["o sea", "tipo"]
            ]),
            SlangEntry(concept: "end_of_discussion", mappings: [
                .newGen: ["periodt", "y punto"],
                .boomer: ["punto", "se acabo"]
            ]),
            SlangEntry(concept: "too_long", mappings: [
                .newGen: ["mucho texto"],
                .boomer: ["ve al grano", "no te enrolles"]
            ]),
            SlangEntry(concept: "gossip", mappings: [
                .newGen: ["salseo", "tea"],
                .boomer: ["cotilleo", "drama"]
            ]),
            SlangEntry(concept: "tell_gossip", mappings: [
                .newGen: ["spill the tea"],
                .boomer: ["cuenta", "desembucha"]
            ]),
            SlangEntry(concept: "lack_context", mappings: [
                .newGen: ["te falta lore"],
                .boomer: ["no sabes ni la mitad", "no tienes ni idea"]
            ]),
            SlangEntry(concept: "has_backstory", mappings: [
                .newGen: ["tiene lore"],
                .boomer: ["tiene historia", "hay mucho detras"]
            ]),
            SlangEntry(concept: "dont_care", mappings: [
                .newGen: ["y la queso"],
                .boomer: ["me da igual", "paso"]
            ]),
            SlangEntry(concept: "all_good", mappings: [
                .newGen: ["todo Gucci"],
                .boomer: ["todo bien", "todo guay"]
            ]),

            // ============================
            // MARK: Emociones
            // ============================

            SlangEntry(concept: "excitement", mappings: [
                .newGen: ["hype"],
                .boomer: ["hype", "emocion", "ganas locas"]
            ]),
            SlangEntry(concept: "mood_state", mappings: [
                .newGen: ["mood"],
                .boomer: ["mood", "eso me representa"]
            ]),
            SlangEntry(concept: "atmosphere", mappings: [
                .newGen: ["vibe", "vibra"],
                .boomer: ["rollo", "ambiente"]
            ]),
            SlangEntry(concept: "shocked", mappings: [
                .newGen: ["flipando"],
                .boomer: ["alucinando", "flipando"]
            ]),
            SlangEntry(concept: "stressed", mappings: [
                .newGen: ["rayado", "rayada"],
                .boomer: ["agobiado", "rallado"]
            ]),
            SlangEntry(concept: "offended", mappings: [
                .newGen: ["triggered"],
                .boomer: ["ofendido", "le ha sentado fatal"]
            ]),
            SlangEntry(concept: "fear_missing_out", mappings: [
                .newGen: ["FOMO"],
                .boomer: ["miedo a perdermelo"]
            ]),
            SlangEntry(concept: "euphoric", mappings: [
                .newGen: ["living", "estoy living"],
                .boomer: ["contentisimo", "eufórico"]
            ]),
            SlangEntry(concept: "mental_saturation", mappings: [
                .newGen: ["brainrot"],
                .boomer: ["el cerebro derretido", "saturado de internet"]
            ]),

            // ============================
            // MARK: Situaciones
            // ============================

            SlangEntry(concept: "turning_point", mappings: [
                .newGen: ["evento canonico"],
                .boomer: ["momento clave", "punto de inflexion"]
            ]),
            SlangEntry(concept: "plot_twist", mappings: [
                .newGen: ["plot twist"],
                .boomer: ["menudo giro", "vaya giro"]
            ]),
            SlangEntry(concept: "nailed_it", mappings: [
                .newGen: ["understood the assignment"],
                .boomer: ["lo bordo", "lo hizo perfecto"]
            ]),
            SlangEntry(concept: "caught_red_handed", mappings: [
                .newGen: ["caught in 4K"],
                .boomer: ["pillado con las manos en la masa"]
            ]),
            SlangEntry(concept: "conflict", mappings: [
                .newGen: ["beef"],
                .boomer: ["bronca", "lio", "pique"]
            ]),
            SlangEntry(concept: "subtle_criticism", mappings: [
                .newGen: ["shade"],
                .boomer: ["indirecta", "pullita"]
            ]),
            SlangEntry(concept: "protagonist_energy", mappings: [
                .newGen: ["main character"],
                .boomer: ["se cree el protagonista", "va de estrella"]
            ]),
            SlangEntry(concept: "selfish_phase", mappings: [
                .newGen: ["villain era"],
                .boomer: ["fase egoista", "paso de todo"]
            ]),
            SlangEntry(concept: "personal_phase", mappings: [
                .newGen: ["mi era"],
                .boomer: ["mi momento", "mi fase"]
            ]),
            SlangEntry(concept: "random_thing", mappings: [
                .newGen: ["random"],
                .boomer: ["aleatorio", "de la nada"]
            ]),
            SlangEntry(concept: "visual_style", mappings: [
                .newGen: ["aesthetic"],
                .boomer: ["tiene un rollo visual", "estilo cuidado"]
            ]),
            SlangEntry(concept: "faking_lifestyle", mappings: [
                .newGen: ["postureo"],
                .boomer: ["pura fachada", "postureo"]
            ]),
            SlangEntry(concept: "nepotism", mappings: [
                .newGen: ["nepobaby"],
                .boomer: ["enchufado", "hijo de papa"]
            ]),

            // ============================
            // MARK: Internet y digital
            // ============================

            SlangEntry(concept: "condolences_ironic", mappings: [
                .newGen: ["F", "F en el chat"],
                .boomer: ["vaya faena", "que mala suerte"]
            ]),
            SlangEntry(concept: "good_game", mappings: [
                .newGen: ["GG"],
                .boomer: ["bien jugado", "enhorabuena"]
            ]),
            SlangEntry(concept: "just_kidding", mappings: [
                .newGen: ["ahre"],
                .boomer: ["es broma", "de broma"]
            ]),
            SlangEntry(concept: "sleep", mappings: [
                .newGen: ["mimir"],
                .boomer: ["dormir", "irse a dormir"]
            ]),
            SlangEntry(concept: "useful", mappings: [
                .newGen: ["messirve"],
                .boomer: ["me vale", "me viene genial"]
            ]),
            SlangEntry(concept: "overpowered", mappings: [
                .newGen: ["chetado"],
                .boomer: ["invencible", "imbatible"]
            ]),
            SlangEntry(concept: "ratio_beaten", mappings: [
                .newGen: ["ratio"],
                .boomer: ["le han humillado", "superado"]
            ]),

            // ============================
            // MARK: Outfit y apariencia
            // ============================

            SlangEntry(concept: "outfit", mappings: [
                .newGen: ["fit", "outfit"],
                .boomer: ["la ropa", "el look", "lo que lleva"]
            ]),
            SlangEntry(concept: "very_pretty", mappings: [
                .newGen: ["coquette", "demure"],
                .boomer: ["muy femenino", "elegante"]
            ]),

            // ============================
            // MARK: Expresiones
            // ============================

            SlangEntry(concept: "exclamation_surprise", mappings: [
                .newGen: ["gyatt", "dou"],
                .boomer: ["anda", "madre mia"]
            ]),
            SlangEntry(concept: "absurd_content", mappings: [
                .newGen: ["skibidi"],
                .boomer: ["tonteria", "absurdo"]
            ]),
            SlangEntry(concept: "weird_place", mappings: [
                .newGen: ["only in Ohio"],
                .boomer: ["solo en este pais", "hay que ver"]
            ]),
        ]
    }
    // swiftlint:enable function_body_length
}
