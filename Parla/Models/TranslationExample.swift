import Foundation

struct TranslationExample: Identifiable {
    let id = UUID()
    let sentences: [Generation: String]

    static let samples: [TranslationExample] = [
        TranslationExample(sentences: [
            .newGen: "Bro, literal ese pibe tiene un rizz god",
            .boomer: "Oye, de verdad ese chico tiene un encanto estupendo"
        ]),
        TranslationExample(sentences: [
            .newGen: "El salseo fue cringe total. La funaron por flexear",
            .boomer: "El cotilleo fue bochornoso. La denunciaron por presumir"
        ]),
        TranslationExample(sentences: [
            .newGen: "Mi crush me ghosteo y ahora estoy en mi villain era",
            .boomer: "Mi amor platonico me dejo de hablar y estoy en mi fase egoista"
        ]),
        TranslationExample(sentences: [
            .newGen: "No cap, esa bestie tiene flow. Devoro con ese fit",
            .boomer: "De verdad, esa amiga del alma tiene elegancia. Arraso con ese atuendo"
        ]),
        TranslationExample(sentences: [
            .newGen: "Ese NPC es un simp total, caught in 4K stalkeando",
            .boomer: "Ese borreguito es un baboso total, pillado con las manos en la masa espiando"
        ]),
        TranslationExample(sentences: [
            .newGen: "Todo Gucci, en plan six seven. Periodt",
            .boomer: "Todo en orden, o sea coser y cantar. Asunto zanjado"
        ])
    ]
}
