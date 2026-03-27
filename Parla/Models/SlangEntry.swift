import Foundation

/// Representa un concepto con su traduccion en cada generacion.
/// Cada generacion puede tener varios sinonimos; el motor de traduccion
/// utiliza el primero como traduccion preferida y el resto como terminos
/// reconocidos en el texto de entrada.
struct SlangEntry: Identifiable {
    let id = UUID()
    let concept: String
    let mappings: [Generation: [String]]

    /// Devuelve la traduccion principal (primer sinonimo) para una generacion.
    func primary(for generation: Generation) -> String? {
        mappings[generation]?.first
    }

    /// Todos los sinonimos reconocidos para una generacion.
    func terms(for generation: Generation) -> [String] {
        mappings[generation] ?? []
    }
}
