import Foundation

struct TranslationExample: Identifiable {
    let id = UUID()
    let sentences: [Generation: String]

    static let samples: [TranslationExample] = [
        TranslationExample(sentences: [
            .newGen: "Bro, literal ese pibe tiene un rizz god",
            .boomer: "Tio, de verdad ese chaval tiene una labia increible"
        ]),
        TranslationExample(sentences: [
            .newGen: "El salseo fue cringe total. La funaron por flexear",
            .boomer: "El cotilleo fue super penoso. La señalaron por ir presumiendo"
        ]),
        TranslationExample(sentences: [
            .newGen: "Mi crush me ghosteo y ahora estoy en mi villain era",
            .boomer: "La tia que me gustaba paso de mi y ahora estoy en plan egoista"
        ]),
        TranslationExample(sentences: [
            .newGen: "No cap fr fr, esa bestie tiene flow. Devoro con ese fit",
            .boomer: "De verdad, su mejor amiga tiene un estilazo. Le quedo increible la ropa"
        ]),
        TranslationExample(sentences: [
            .newGen: "Bro ese NPC es un simp total, caught in 4K stalkeando ngl",
            .boomer: "Tio ese borreguito esta pillado total, le pillaron cotilleando el perfil"
        ]),
        TranslationExample(sentences: [
            .newGen: "Todo Gucci bro, en plan six seven. Periodt",
            .boomer: "Todo bien tio, o sea facilisimo. Punto"
        ])
    ]
}
