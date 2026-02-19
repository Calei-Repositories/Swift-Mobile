import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case encoding(Error)
    case notAuthenticated
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida"
        case .httpStatus(let code):
            return "Error HTTP: \(code)"
        case .decoding(let error):
            return "Error al decodificar: \(error.localizedDescription)"
        case .encoding(let error):
            return "Error al codificar: \(error.localizedDescription)"
        case .notAuthenticated:
            return "Sesión no autenticada"
        case .other(let error):
            return error.localizedDescription
        }
    }
}
