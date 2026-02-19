import Foundation
import CoreLocation
import SwiftUI

// MARK: - Delivery

struct Delivery: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let status: String?
    let date: String?
    let scheduledDate: String?
    let itemsCount: Int?
    let completedCount: Int?
    let zone: DeliveryZone?
    
    var deliveryStatus: DeliveryStatus {
        DeliveryStatus(rawValue: status ?? "") ?? .pending
    }
    
    var progress: Double {
        guard let total = itemsCount, let completed = completedCount, total > 0 else {
            return 0
        }
        return Double(completed) / Double(total)
    }
    
    var displayTitle: String {
        title ?? "Reparto #\(id)"
    }
}

enum DeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .inProgress: return "En progreso"
        case .completed: return "Completado"
        case .all: return "Todos"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "shippingbox"
        case .completed: return "checkmark.circle.fill"
        case .all: return "list.bullet"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return CaleiColors.warning
        case .inProgress: return CaleiColors.info
        case .completed: return CaleiColors.success
        case .all: return CaleiColors.gray500
        }
    }
}

struct DeliveryZone: Codable, Equatable {
    let id: Int
    let name: String
}

// MARK: - Delivery Item (Order)

struct DeliveryItem: Codable, Identifiable, Equatable {
    let id: Int
    let externalId: String?
    let status: String?
    let amount: Double?
    let note: String?
    let routeOrder: Int?
    let client: Client?
    let salePoint: ItemSalePoint?
    
    var itemStatus: ItemStatus {
        ItemStatus(rawValue: status ?? "") ?? .pending
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let sp = salePoint else { return nil }
        return CLLocationCoordinate2D(latitude: sp.latitude, longitude: sp.longitude)
    }
    
    var displayName: String {
        client?.name ?? externalId ?? "Pedido #\(id)"
    }
}

enum ItemStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case postponeRescue = "postpone_rescue"
    case postponeNextWeek = "postpone_next_week"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .completed: return "Completado"
        case .postponeRescue: return "Posponer rescate"
        case .postponeNextWeek: return "Posponer semana"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .postponeRescue: return "arrow.uturn.backward.circle"
        case .postponeNextWeek: return "calendar.badge.clock"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return CaleiColors.warning
        case .completed: return CaleiColors.success
        case .postponeRescue: return CaleiColors.info
        case .postponeNextWeek: return CaleiColors.gray500
        }
    }
}

struct Client: Codable, Equatable {
    let id: Int?
    let name: String
    let address: String?
    let phone: String?
}

struct ItemSalePoint: Codable, Equatable {
    let id: Int
    let latitude: Double
    let longitude: Double
}

// MARK: - Delivery Item Detail

struct DeliveryItemDetail: Codable {
    let item: DeliveryItem
    let lines: [DeliveryItemLine]?
}

struct DeliveryItemLine: Codable, Identifiable, Equatable {
    let id: Int?
    var productCode: String
    var quantity: Double
    var unitPrice: Double
    var description: String?
    
    var isDiscount: Bool {
        quantity < 0
    }
    
    var lineTotal: Double {
        quantity * unitPrice
    }
    
    // For creating new lines
    init(id: Int? = nil, productCode: String, quantity: Double, unitPrice: Double, description: String?) {
        self.id = id
        self.productCode = productCode
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.description = description
    }
}

// MARK: - Requests

struct UpdateDeliveryItemRequest: Encodable {
    let status: String
    let items: [DeliveryItemLine]?
    let amount: Double?
    let note: String?
}

struct PrintTicketResponse: Codable {
    let success: Bool
    let ticketId: Int?
    let message: String?
}

// MARK: - Map Overlay

struct DeliveryMapOverlay: Codable {
    let points: [MapDeliveryPoint]
    let ghosts: [MapDeliveryPoint]?
}

struct MapDeliveryPoint: Codable, Identifiable {
    let id: Int
    let latitude: Double
    let longitude: Double
    let name: String?
    let status: String?
    let routeOrder: Int?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
