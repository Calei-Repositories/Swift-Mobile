import Foundation

struct Product: Codable, Identifiable {
    let id: Int?
    let code: String?
    let description: String?
    let unitPrice: Double?
}
