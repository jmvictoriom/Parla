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
                .boomer: ["estupendo", "fenomenal", "cojonudo"]
            ]),
            SlangEntry(concept: "amazing", mappings: [
                .newGen: ["devorar", "petarlo"],
                .boomer: ["formidable", "barbaro", "increible"]
            ]),
            SlangEntry(concept: "perfect", mappings: [
                .newGen: ["fantasia", "nashe"],
                .boomer: ["impecable", "perfecto", "redondo"]
            ]),
            SlangEntry(concept: "very_good", mappings: [
                .newGen: ["buenardo", "PEC"],
                .boomer: ["magnifico", "esplendido"]
            ]),
            SlangEntry(concept: "attractive", mappings: [
                .newGen: ["fachero", "face card"],
                .boomer: ["bien parecido", "apuesto", "guapeton"]
            ]),
            SlangEntry(concept: "charisma", mappings: [
                .newGen: ["rizz"],
                .boomer: ["encanto", "carisma", "don de gentes"]
            ]),
            SlangEntry(concept: "style", mappings: [
                .newGen: ["flow"],
                .boomer: ["elegancia", "porte", "distincion"]
            ]),
            SlangEntry(concept: "transformation", mappings: [
                .newGen: ["glow up"],
                .boomer: ["cambio radical", "mejora notable"]
            ]),
            SlangEntry(concept: "easy", mappings: [
                .newGen: ["six seven", "easy"],
                .boomer: ["coser y cantar", "pan comido"]
            ]),
            SlangEntry(concept: "true_facts", mappings: [
                .newGen: ["factos", "facts"],
                .boomer: ["efectivamente", "desde luego", "asi es"]
            ]),
            SlangEntry(concept: "seriously", mappings: [
                .newGen: ["no cap"],
                .boomer: ["de verdad", "te lo digo yo"]
            ]),
            SlangEntry(concept: "honest", mappings: [
                .newGen: ["basado"],
                .boomer: ["franco", "honrado", "sincero"]
            ]),

            // ============================
            // MARK: Cualidades negativas
            // ============================

            SlangEntry(concept: "cringe", mappings: [
                .newGen: ["cringe"],
                .boomer: ["bochornoso", "lamentable", "verguenza ajena"]
            ]),
            SlangEntry(concept: "bad", mappings: [
                .newGen: ["malardo"],
                .boomer: ["espantoso", "horrible", "pesimo"]
            ]),
            SlangEntry(concept: "failed", mappings: [
                .newGen: ["flopear"],
                .boomer: ["fracasar", "fallar"]
            ]),
            SlangEntry(concept: "embarrassing", mappings: [
                .newGen: ["lache"],
                .boomer: ["bochorno", "sonrojo", "verguenza"]
            ]),
            SlangEntry(concept: "suspicious", mappings: [
                .newGen: ["sus"],
                .boomer: ["sospechoso", "turbio", "raro"]
            ]),
            SlangEntry(concept: "outdated", mappings: [
                .newGen: ["cheugy", "charca"],
                .boomer: ["pasado de moda", "trasnochado", "anticuado"]
            ]),
            SlangEntry(concept: "mediocre", mappings: [
                .newGen: ["mid"],
                .boomer: ["mediocre", "del monton", "tirando a malo"]
            ]),
            SlangEntry(concept: "confused", mappings: [
                .newGen: ["bugueado"],
                .boomer: ["aturdido", "confuso", "despistado"]
            ]),

            // ============================
            // MARK: Personas
            // ============================

            SlangEntry(concept: "friend", mappings: [
                .newGen: ["bro"],
                .boomer: ["amigo", "companero", "oye"]
            ]),
            SlangEntry(concept: "best_friend", mappings: [
                .newGen: ["bestie"],
                .boomer: ["amiga del alma", "inseparable"]
            ]),
            SlangEntry(concept: "buddy", mappings: [
                .newGen: ["pana", "neri"],
                .boomer: ["companero", "compadre"]
            ]),
            SlangEntry(concept: "genius", mappings: [
                .newGen: ["crack"],
                .boomer: ["fenomeno", "genio", "un hacha"]
            ]),
            SlangEntry(concept: "newbie", mappings: [
                .newGen: ["noob"],
                .boomer: ["novato", "inexperto", "primerizo"]
            ]),
            SlangEntry(concept: "showoff_person", mappings: [
                .newGen: ["flexero"],
                .boomer: ["presumido", "vanidoso", "fantasma"]
            ]),
            SlangEntry(concept: "critic", mappings: [
                .newGen: ["hater"],
                .boomer: ["envidioso", "criticon", "resentido"]
            ]),
            SlangEntry(concept: "obsessive_fan", mappings: [
                .newGen: ["stan"],
                .boomer: ["admirador ferviente", "devoto", "incondicional"]
            ]),
            SlangEntry(concept: "tryhard_person", mappings: [
                .newGen: ["tryhard"],
                .boomer: ["empollón", "demasiado intenso"]
            ]),
            SlangEntry(concept: "loner", mappings: [
                .newGen: ["sigma"],
                .boomer: ["lobo solitario", "ermitano"]
            ]),
            SlangEntry(concept: "mindless_person", mappings: [
                .newGen: ["NPC"],
                .boomer: ["borreguito", "persona sin criterio"]
            ]),
            SlangEntry(concept: "confident_man", mappings: [
                .newGen: ["chad"],
                .boomer: ["todo un hombre", "un senor"]
            ]),
            SlangEntry(concept: "pick_me_person", mappings: [
                .newGen: ["pick me"],
                .boomer: ["zalamera", "aduladora", "pelota"]
            ]),

            // ============================
            // MARK: Relaciones
            // ============================

            SlangEntry(concept: "crush", mappings: [
                .newGen: ["crush"],
                .boomer: ["amor platonico", "flechazo"]
            ]),
            SlangEntry(concept: "situationship", mappings: [
                .newGen: ["situationship"],
                .boomer: ["amigos especiales", "relacion sin definir"]
            ]),
            SlangEntry(concept: "early_dating", mappings: [
                .newGen: ["talking stage"],
                .boomer: ["cortejo", "conocerse"]
            ]),
            SlangEntry(concept: "secret_affair", mappings: [
                .newGen: ["sneaky link"],
                .boomer: ["ligue secreto", "aventurilla"]
            ]),
            SlangEntry(concept: "toxic_partner", mappings: [
                .newGen: ["toxico", "toxica"],
                .boomer: ["dominante", "posesivo", "asfixiante"]
            ]),
            SlangEntry(concept: "devoted_lover", mappings: [
                .newGen: ["simp"],
                .boomer: ["baboso", "rendido", "sometido"]
            ]),
            SlangEntry(concept: "sudden_rejection", mappings: [
                .newGen: ["ick"],
                .boomer: ["aversion", "repugnancia", "rechazo"]
            ]),
            SlangEntry(concept: "warning_sign", mappings: [
                .newGen: ["red flag"],
                .boomer: ["mala espina", "senal de alarma"]
            ]),
            SlangEntry(concept: "good_sign", mappings: [
                .newGen: ["green flag"],
                .boomer: ["buena senal", "prometedor"]
            ]),

            // ============================
            // MARK: Acciones
            // ============================

            SlangEntry(concept: "show_off", mappings: [
                .newGen: ["flexear"],
                .boomer: ["presumir", "pavonearse"]
            ]),
            SlangEntry(concept: "showing_off", mappings: [
                .newGen: ["flexeando"],
                .boomer: ["presumiendo", "pavoneandose"]
            ]),
            SlangEntry(concept: "ignore", mappings: [
                .newGen: ["ghostear"],
                .boomer: ["dejar plantado", "dejar de hablar"]
            ]),
            SlangEntry(concept: "ignoring", mappings: [
                .newGen: ["ghosteando"],
                .boomer: ["dejando de lado", "ignorando"]
            ]),
            SlangEntry(concept: "ignored_past", mappings: [
                .newGen: ["ghosteo"],
                .boomer: ["dejo de hablar a", "ignoro"]
            ]),
            SlangEntry(concept: "spy_on", mappings: [
                .newGen: ["stalkear"],
                .boomer: ["espiar", "curiosear", "fisgonear"]
            ]),
            SlangEntry(concept: "stalking", mappings: [
                .newGen: ["stalkeando"],
                .boomer: ["espiando", "curioseando"]
            ]),
            SlangEntry(concept: "provoke", mappings: [
                .newGen: ["trolear"],
                .boomer: ["provocar", "molestar", "chinchar"]
            ]),
            SlangEntry(concept: "ship", mappings: [
                .newGen: ["shippear"],
                .boomer: ["casar", "emparejar"]
            ]),
            SlangEntry(concept: "cancel_publicly", mappings: [
                .newGen: ["funar", "cancelar"],
                .boomer: ["poner en evidencia", "denunciar"]
            ]),
            SlangEntry(concept: "cancelled_past", mappings: [
                .newGen: ["funaron", "cancelaron"],
                .boomer: ["denunciaron", "pusieron en evidencia"]
            ]),
            SlangEntry(concept: "block", mappings: [
                .newGen: ["banear"],
                .boomer: ["excluir", "vetar", "apartar"]
            ]),
            SlangEntry(concept: "boast", mappings: [
                .newGen: ["frontear"],
                .boomer: ["pavonearse", "darse aires"]
            ]),
            SlangEntry(concept: "dance", mappings: [
                .newGen: ["perrear"],
                .boomer: ["bailar", "mover el esqueleto"]
            ]),
            SlangEntry(concept: "appear_suddenly", mappings: [
                .newGen: ["spawnear"],
                .boomer: ["aparecer de golpe", "presentarse"]
            ]),
            SlangEntry(concept: "carry_team", mappings: [
                .newGen: ["carrilear", "carrear"],
                .boomer: ["llevar la carga", "tirar del carro"]
            ]),
            SlangEntry(concept: "accumulate", mappings: [
                .newGen: ["farmear aura"],
                .boomer: ["labrarse reputacion", "ganar prestigio"]
            ]),
            SlangEntry(concept: "expose_data", mappings: [
                .newGen: ["doxear"],
                .boomer: ["sacar los trapos", "airear"]
            ]),
            SlangEntry(concept: "succeed_greatly", mappings: [
                .newGen: ["la rompe", "devoro"],
                .boomer: ["arraso", "brillo", "se lucio"]
            ]),

            // ============================
            // MARK: Comunicacion
            // ============================

            SlangEntry(concept: "literally", mappings: [
                .newGen: ["literal"],
                .boomer: ["de verdad", "fijate tu"]
            ]),
            SlangEntry(concept: "filler_word", mappings: [
                .newGen: ["en plan"],
                .boomer: ["o sea", "digamos", "es decir"]
            ]),
            SlangEntry(concept: "end_of_discussion", mappings: [
                .newGen: ["periodt", "y punto"],
                .boomer: ["asunto zanjado", "no hay mas que hablar"]
            ]),
            SlangEntry(concept: "too_long", mappings: [
                .newGen: ["mucho texto"],
                .boomer: ["no te enrolles", "ve al grano"]
            ]),
            SlangEntry(concept: "gossip", mappings: [
                .newGen: ["salseo", "tea"],
                .boomer: ["cotilleo", "chismorreo", "comidilla"]
            ]),
            SlangEntry(concept: "tell_gossip", mappings: [
                .newGen: ["spill the tea"],
                .boomer: ["cuentamelo todo", "desembucha"]
            ]),
            SlangEntry(concept: "lack_context", mappings: [
                .newGen: ["te falta lore"],
                .boomer: ["no sabes ni la mitad", "te falta informacion"]
            ]),
            SlangEntry(concept: "has_backstory", mappings: [
                .newGen: ["tiene lore"],
                .boomer: ["tiene su aquel", "hay mucho detras"]
            ]),
            SlangEntry(concept: "dont_care", mappings: [
                .newGen: ["y la queso"],
                .boomer: ["alla ellos", "no me importa"]
            ]),
            SlangEntry(concept: "all_good", mappings: [
                .newGen: ["todo Gucci"],
                .boomer: ["todo en orden", "todo perfecto"]
            ]),

            // ============================
            // MARK: Emociones
            // ============================

            SlangEntry(concept: "excitement", mappings: [
                .newGen: ["hype"],
                .boomer: ["expectacion", "emocion", "nervios buenos"]
            ]),
            SlangEntry(concept: "mood_state", mappings: [
                .newGen: ["mood"],
                .boomer: ["estado de animo", "humor"]
            ]),
            SlangEntry(concept: "atmosphere", mappings: [
                .newGen: ["vibe", "vibra"],
                .boomer: ["ambiente", "atmosfera"]
            ]),
            SlangEntry(concept: "shocked", mappings: [
                .newGen: ["flipando"],
                .boomer: ["estupefacto", "atonito", "boquiabierto"]
            ]),
            SlangEntry(concept: "stressed", mappings: [
                .newGen: ["rayado", "rayada"],
                .boomer: ["angustiado", "preocupado"]
            ]),
            SlangEntry(concept: "offended", mappings: [
                .newGen: ["triggered"],
                .boomer: ["indignado", "susceptible", "ofendido"]
            ]),
            SlangEntry(concept: "fear_missing_out", mappings: [
                .newGen: ["FOMO"],
                .boomer: ["miedo a perdermelo", "que no me lo pierda"]
            ]),
            SlangEntry(concept: "euphoric", mappings: [
                .newGen: ["living", "estoy living"],
                .boomer: ["radiante", "rebosante de alegria"]
            ]),
            SlangEntry(concept: "mental_saturation", mappings: [
                .newGen: ["brainrot"],
                .boomer: ["embotamiento", "saturacion mental"]
            ]),

            // ============================
            // MARK: Situaciones
            // ============================

            SlangEntry(concept: "turning_point", mappings: [
                .newGen: ["evento canonico"],
                .boomer: ["momento decisivo", "punto de inflexion"]
            ]),
            SlangEntry(concept: "plot_twist", mappings: [
                .newGen: ["plot twist"],
                .boomer: ["giro dramatico", "sorpresa mayuscula"]
            ]),
            SlangEntry(concept: "nailed_it", mappings: [
                .newGen: ["understood the assignment"],
                .boomer: ["dio en el clavo", "se lucio"]
            ]),
            SlangEntry(concept: "caught_red_handed", mappings: [
                .newGen: ["caught in 4K"],
                .boomer: ["pillado con las manos en la masa", "cogido in fraganti"]
            ]),
            SlangEntry(concept: "conflict", mappings: [
                .newGen: ["beef"],
                .boomer: ["disputa", "bronca", "rencilla"]
            ]),
            SlangEntry(concept: "subtle_criticism", mappings: [
                .newGen: ["shade"],
                .boomer: ["indirecta", "pulla", "comentario malicioso"]
            ]),
            SlangEntry(concept: "protagonist_energy", mappings: [
                .newGen: ["main character"],
                .boomer: ["el centro del universo", "la estrella"]
            ]),
            SlangEntry(concept: "selfish_phase", mappings: [
                .newGen: ["villain era"],
                .boomer: ["fase egoista", "mala temporada"]
            ]),
            SlangEntry(concept: "personal_phase", mappings: [
                .newGen: ["mi era"],
                .boomer: ["mi epoca", "mi momento"]
            ]),
            SlangEntry(concept: "random_thing", mappings: [
                .newGen: ["random"],
                .boomer: ["de la nada", "inesperado"]
            ]),
            SlangEntry(concept: "visual_style", mappings: [
                .newGen: ["aesthetic"],
                .boomer: ["apariencia", "aspecto", "estilo"]
            ]),
            SlangEntry(concept: "faking_lifestyle", mappings: [
                .newGen: ["postureo"],
                .boomer: ["guardar las apariencias", "poner buena cara"]
            ]),
            SlangEntry(concept: "nepotism", mappings: [
                .newGen: ["nepobaby"],
                .boomer: ["enchufado", "colocado a dedo"]
            ]),

            // ============================
            // MARK: Internet y digital
            // ============================

            SlangEntry(concept: "condolences_ironic", mappings: [
                .newGen: ["F", "F en el chat"],
                .boomer: ["que mala suerte", "vaya faena"]
            ]),
            SlangEntry(concept: "good_game", mappings: [
                .newGen: ["GG"],
                .boomer: ["enhorabuena", "bravo", "chapeau"]
            ]),
            SlangEntry(concept: "just_kidding", mappings: [
                .newGen: ["ahre"],
                .boomer: ["es broma", "cachondeo"]
            ]),
            SlangEntry(concept: "sleep", mappings: [
                .newGen: ["mimir"],
                .boomer: ["dormir", "descansar"]
            ]),
            SlangEntry(concept: "useful", mappings: [
                .newGen: ["messirve"],
                .boomer: ["me viene bien", "conveniente"]
            ]),
            SlangEntry(concept: "overpowered", mappings: [
                .newGen: ["chetado"],
                .boomer: ["invencible", "imparable"]
            ]),
            SlangEntry(concept: "ratio_beaten", mappings: [
                .newGen: ["ratio"],
                .boomer: ["superado", "desacreditado"]
            ]),

            // ============================
            // MARK: Outfit y apariencia
            // ============================

            SlangEntry(concept: "outfit", mappings: [
                .newGen: ["fit", "outfit"],
                .boomer: ["atuendo", "vestimenta", "conjunto"]
            ]),
            SlangEntry(concept: "very_pretty", mappings: [
                .newGen: ["coquette", "demure"],
                .boomer: ["elegante", "con clase"]
            ]),

            // ============================
            // MARK: Expresiones
            // ============================

            SlangEntry(concept: "exclamation_surprise", mappings: [
                .newGen: ["gyatt", "dou"],
                .boomer: ["caramba", "santo cielo"]
            ]),
            SlangEntry(concept: "absurd_content", mappings: [
                .newGen: ["skibidi"],
                .boomer: ["tonteria", "disparate"]
            ]),
            SlangEntry(concept: "weird_place", mappings: [
                .newGen: ["only in Ohio"],
                .boomer: ["solo en este pais", "hay que ver"]
            ]),
        ]
    }
    // swiftlint:enable function_body_length
}
