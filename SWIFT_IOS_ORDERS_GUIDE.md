# Swift iOS Orders/Deliveries Module Guide

This guide documents the Orders/Deliveries module implementation for the iOS Swift app, following the existing MVVM architecture and CaleiTheme styling.

## 1. Architecture Overview

### 1.1 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Orders Microservice                  │
│                (Bearer Auth - Source of Truth)                   │
│   GET /api/pedidos | POST /api/pedidos/update-to-R              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Sync via orders-sync.service)
┌─────────────────────────────────────────────────────────────────┐
│                     Main Backend (Railway)                       │
│                    (Cookie Session Auth)                         │
│   Orders grouped by zone/lote → Deliveries                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Dealer Endpoints                            │
│   /dealer/deliveries, /dealer/delivery-items, etc.              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      iOS App (Swift)                             │
│   DealerService → ViewModels → SwiftUI Views                    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Key Entities

| Entity | Description |
|--------|-------------|
| **Delivery** | A grouped set of orders for a dealer to deliver (by zone/lote) |
| **DeliveryItem** | Individual order/report within a delivery (maps to Order entity) |
| **DeliveryItemLine** | Product line within an order (product, quantity, price) |
| **Order** | Backend entity synced from external microservice |
| **OrderPrintTicket** | Print request for an order |

## 2. Backend Endpoints (Dealer)

All endpoints require session cookie authentication.

### 2.1 Deliveries (Repartos)

#### List Deliveries
```http
GET /dealer/deliveries?status={status}
```

**Query Parameters:**
| Param | Values | Description |
|-------|--------|-------------|
| `status` | `all`, `pending`, `in_progress`, `completed` | Filter by status |

**Response:**
```json
[
  {
    "id": 1,
    "title": "Zona Norte - Lote 2024-01-27",
    "status": "pending",
    "date": "2024-01-27",
    "itemsCount": 15,
    "completedCount": 3,
    "zone": {
      "id": 5,
      "name": "Zona Norte"
    }
  }
]
```

#### Get Delivery Detail
```http
GET /dealer/deliveries/{deliveryId}
```

**Response:**
```json
{
  "id": 1,
  "title": "Zona Norte - Lote 2024-01-27",
  "status": "pending",
  "date": "2024-01-27",
  "scheduledDate": "2024-01-28",
  "itemsCount": 15,
  "completedCount": 3,
  "zone": {
    "id": 5,
    "name": "Zona Norte"
  }
}
```

#### Get Delivery Items (Orders)
```http
GET /dealer/deliveries/{deliveryId}/items
```

**Response:**
```json
[
  {
    "id": 101,
    "externalId": "PED-2024-001",
    "status": "pending",
    "amount": 15500.00,
    "note": null,
    "routeOrder": 1,
    "client": {
      "id": 50,
      "name": "Kiosco Don Pedro",
      "address": "Av. Colón 1234",
      "phone": "351-4567890"
    },
    "salePoint": {
      "id": 200,
      "latitude": -31.4135,
      "longitude": -64.1810
    }
  }
]
```

### 2.2 Delivery Items (Individual Orders)

#### Get Item Detail
```http
GET /dealer/delivery-items/{itemId}
```

**Response:**
```json
{
  "item": {
    "id": 101,
    "externalId": "PED-2024-001",
    "status": "pending",
    "amount": 15500.00,
    "note": null,
    "client": {
      "id": 50,
      "name": "Kiosco Don Pedro",
      "address": "Av. Colón 1234",
      "phone": "351-4567890"
    }
  },
  "lines": [
    {
      "id": 1,
      "productCode": "PROD001",
      "quantity": 2.0,
      "unitPrice": 5000.00,
      "description": "Auriculares Bluetooth"
    },
    {
      "id": 2,
      "productCode": "PROD002",
      "quantity": 1.0,
      "unitPrice": 5500.00,
      "description": "Cargador USB-C"
    }
  ]
}
```

#### Update Item (Complete/Postpone)
```http
PATCH /dealer/delivery-items/{itemId}
Content-Type: application/json

{
  "status": "completed",
  "items": [
    {"productCode": "PROD001", "quantity": 2.0, "unitPrice": 5000.00, "description": "Auriculares"},
    {"productCode": "PROD001", "quantity": -1.0, "unitPrice": 5000.00, "description": "Descuento"}
  ],
  "amount": 9000.00,
  "note": "Cliente solicitó descuento por compra múltiple"
}
```

**Status Values:**
| Status | Description |
|--------|-------------|
| `pending` | Not yet processed |
| `completed` | Successfully delivered |
| `postpone_rescue` | Postponed for rescue delivery |
| `postpone_next_week` | Postponed to next week |

**Rules:**
- `quantity` can be negative (discount/warranty) but **cannot be 0**
- `unitPrice` must be `>= 0`

### 2.3 Print Ticket
```http
POST /dealer/orders/{orderId}/print
```

**Response:**
```json
{
  "success": true,
  "ticketId": 456,
  "message": "Ticket enviado a impresión"
}
```

### 2.4 Map Overlay (Delivery Points)
```http
GET /dealer/deliveries/{deliveryId}/map-overlay?n={north}&s={south}&e={east}&w={west}
```

**Response:**
```json
{
  "points": [
    {
      "id": 200,
      "latitude": -31.4135,
      "longitude": -64.1810,
      "name": "Kiosco Don Pedro",
      "status": "pending",
      "routeOrder": 1
    }
  ],
  "ghosts": [
    {
      "id": 300,
      "latitude": -31.4200,
      "longitude": -64.1850,
      "name": "Punto sin asignar"
    }
  ]
}
```

### 2.5 Product Search
```http
GET /dealer/products?search={query}&limit={n}
```

**Response:**
```json
[
  {
    "code": "PROD001",
    "name": "Auriculares Bluetooth",
    "price": 5000.00,
    "stock": 25
  }
]
```

## 3. Swift Models

### 3.1 DeliveryModels.swift (Expanded)

```swift
import Foundation
import CoreLocation

// MARK: - Delivery

struct Delivery: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let status: DeliveryStatus
    let date: String?
    let scheduledDate: String?
    let itemsCount: Int?
    let completedCount: Int?
    let zone: DeliveryZone?
    
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
    let status: ItemStatus?
    let amount: Double?
    let note: String?
    let routeOrder: Int?
    let client: Client?
    let salePoint: ItemSalePoint?
    
    var displayStatus: ItemStatus {
        status ?? .pending
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let sp = salePoint else { return nil }
        return CLLocationCoordinate2D(latitude: sp.latitude, longitude: sp.longitude)
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
    let id: Int
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
    let productCode: String
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
    init(productCode: String, quantity: Double, unitPrice: Double, description: String?) {
        self.id = nil
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

// MARK: - Product (for search)

struct Product: Codable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let name: String
    let price: Double?
    let stock: Int?
}
```

## 4. DealerService (Expanded)

```swift
import Foundation

final class DealerService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: - Deliveries

    func deliveries(status: DeliveryStatus = .all) async throws -> [Delivery] {
        let endpoint = Endpoint(
            path: "/dealer/deliveries",
            method: .get,
            queryItems: [URLQueryItem(name: "status", value: status.rawValue)]
        )
        return try await client.request(endpoint, responseType: [Delivery].self)
    }

    func deliveryDetail(deliveryId: Int) async throws -> Delivery {
        let endpoint = Endpoint(path: "/dealer/deliveries/\(deliveryId)", method: .get)
        return try await client.request(endpoint, responseType: Delivery.self)
    }

    func deliveryItems(deliveryId: Int) async throws -> [DeliveryItem] {
        let endpoint = Endpoint(path: "/dealer/deliveries/\(deliveryId)/items", method: .get)
        return try await client.request(endpoint, responseType: [DeliveryItem].self)
    }

    // MARK: - Delivery Items

    func deliveryItemDetail(itemId: Int) async throws -> DeliveryItemDetail {
        let endpoint = Endpoint(path: "/dealer/delivery-items/\(itemId)", method: .get)
        return try await client.request(endpoint, responseType: DeliveryItemDetail.self)
    }

    func updateDeliveryItem(
        itemId: Int,
        status: ItemStatus,
        items: [DeliveryItemLine]?,
        amount: Double?,
        note: String?
    ) async throws {
        let body = UpdateDeliveryItemRequest(
            status: status.rawValue,
            items: items,
            amount: amount,
            note: note
        )
        let endpoint = Endpoint(path: "/dealer/delivery-items/\(itemId)", method: .patch, body: body)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }

    // MARK: - Print

    func printOrderTicket(orderId: Int) async throws -> PrintTicketResponse {
        let endpoint = Endpoint(path: "/dealer/orders/\(orderId)/print", method: .post)
        return try await client.request(endpoint, responseType: PrintTicketResponse.self)
    }

    // MARK: - Products

    func searchProducts(query: String, limit: Int = 20) async throws -> [Product] {
        let endpoint = Endpoint(
            path: "/dealer/products",
            method: .get,
            queryItems: [
                URLQueryItem(name: "search", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        return try await client.request(endpoint, responseType: [Product].self)
    }

    // MARK: - Map

    func deliveryMapOverlay(
        deliveryId: Int,
        bounds: (north: Double, south: Double, east: Double, west: Double)
    ) async throws -> DeliveryMapOverlay {
        let endpoint = Endpoint(
            path: "/dealer/deliveries/\(deliveryId)/map-overlay",
            method: .get,
            queryItems: [
                URLQueryItem(name: "n", value: String(bounds.north)),
                URLQueryItem(name: "s", value: String(bounds.south)),
                URLQueryItem(name: "e", value: String(bounds.east)),
                URLQueryItem(name: "w", value: String(bounds.west))
            ]
        )
        return try await client.request(endpoint, responseType: DeliveryMapOverlay.self)
    }

    // MARK: - Mark New Sale Point

    func markNewSalePoint(
        deliveryId: Int,
        name: String,
        latitude: Double,
        longitude: Double
    ) async throws -> MarkedSalePoint {
        let body = MarkNewSalePointRequest(name: name, latitude: latitude, longitude: longitude)
        let endpoint = Endpoint(
            path: "/dealer/deliveries/\(deliveryId)/mark-new-sale-point",
            method: .post,
            body: body
        )
        return try await client.request(endpoint, responseType: MarkedSalePoint.self)
    }
}
```

## 5. ViewModels

### 5.1 DeliveriesViewModel

```swift
import Foundation
import Combine

@MainActor
final class DeliveriesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var deliveries: [Delivery] = []
    @Published var statusFilter: DeliveryStatus = .all
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties
    
    var filteredDeliveries: [Delivery] {
        if searchQuery.isEmpty {
            return deliveries
        }
        return deliveries.filter { delivery in
            delivery.displayTitle.localizedCaseInsensitiveContains(searchQuery) ||
            delivery.zone?.name.localizedCaseInsensitiveContains(searchQuery) == true
        }
    }
    
    var pendingCount: Int {
        deliveries.filter { $0.status == .pending }.count
    }
    
    var inProgressCount: Int {
        deliveries.filter { $0.status == .inProgress }.count
    }

    // MARK: - Dependencies
    
    private let service: DealerService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    
    init(service: DealerService = DealerService()) {
        self.service = service
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Search is done locally via filteredDeliveries
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            deliveries = try await service.deliveries(status: statusFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            deliveries = try await service.deliveries(status: statusFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 5.2 DeliveryDetailViewModel

```swift
import Foundation
import MapKit

@MainActor
final class DeliveryDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var delivery: Delivery?
    @Published var items: [DeliveryItem] = []
    @Published var mapPoints: [MapDeliveryPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedItemId: Int?
    
    // MARK: - Computed Properties
    
    var sortedItems: [DeliveryItem] {
        items.sorted { ($0.routeOrder ?? 999) < ($1.routeOrder ?? 999) }
    }
    
    var pendingItems: [DeliveryItem] {
        items.filter { $0.displayStatus == .pending }
    }
    
    var completedItems: [DeliveryItem] {
        items.filter { $0.displayStatus == .completed }
    }
    
    var itemCoordinates: [CLLocationCoordinate2D] {
        items.compactMap { $0.coordinate }
    }

    // MARK: - Dependencies
    
    private let service: DealerService

    init(service: DealerService = DealerService()) {
        self.service = service
    }

    // MARK: - Actions
    
    func load(deliveryId: Int) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            async let deliveryTask = service.deliveryDetail(deliveryId: deliveryId)
            async let itemsTask = service.deliveryItems(deliveryId: deliveryId)
            
            self.delivery = try await deliveryTask
            self.items = try await itemsTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMapOverlay(deliveryId: Int, region: MKCoordinateRegion) async {
        let bounds = (
            north: region.center.latitude + region.span.latitudeDelta / 2,
            south: region.center.latitude - region.span.latitudeDelta / 2,
            east: region.center.longitude + region.span.longitudeDelta / 2,
            west: region.center.longitude - region.span.longitudeDelta / 2
        )
        
        do {
            let overlay = try await service.deliveryMapOverlay(deliveryId: deliveryId, bounds: bounds)
            mapPoints = overlay.points + (overlay.ghosts ?? [])
        } catch {
            print("Error loading map overlay: \(error)")
        }
    }
}
```

### 5.3 DeliveryItemEditViewModel

```swift
import Foundation

@MainActor
final class DeliveryItemEditViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var itemDetail: DeliveryItemDetail?
    @Published var status: ItemStatus = .pending
    @Published var amount: String = ""
    @Published var note: String = ""
    @Published var lines: [DeliveryItemLine] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isPrinting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // For product search
    @Published var searchQuery: String = ""
    @Published var searchResults: [Product] = []
    @Published var isSearching = false
    
    // MARK: - Computed Properties
    
    var client: Client? {
        itemDetail?.item.client
    }
    
    var totalAmount: Double {
        lines.reduce(0) { $0 + $1.lineTotal }
    }
    
    var hasChanges: Bool {
        guard let original = itemDetail else { return false }
        return status != original.item.displayStatus ||
               amount != String(original.item.amount ?? 0) ||
               note != (original.item.note ?? "") ||
               lines != (original.lines ?? [])
    }

    // MARK: - Dependencies
    
    private let service: DealerService
    private let itemId: Int

    init(itemId: Int, service: DealerService = DealerService()) {
        self.itemId = itemId
        self.service = service
    }

    // MARK: - Load
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let detail = try await service.deliveryItemDetail(itemId: itemId)
            itemDetail = detail
            status = detail.item.displayStatus
            amount = detail.item.amount.map { String(format: "%.2f", $0) } ?? ""
            note = detail.item.note ?? ""
            lines = detail.lines ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save
    
    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        defer { isSaving = false }
        
        // Validate lines
        for line in lines {
            if line.quantity == 0 {
                errorMessage = "La cantidad no puede ser 0"
                return false
            }
            if line.unitPrice < 0 {
                errorMessage = "El precio no puede ser negativo"
                return false
            }
        }
        
        do {
            let amountValue = Double(amount)
            try await service.updateDeliveryItem(
                itemId: itemId,
                status: status,
                items: lines.isEmpty ? nil : lines,
                amount: amountValue,
                note: note.isEmpty ? nil : note
            )
            successMessage = "Guardado correctamente"
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Print
    
    func printTicket() async {
        isPrinting = true
        errorMessage = nil
        
        defer { isPrinting = false }
        
        do {
            let response = try await service.printOrderTicket(orderId: itemId)
            if response.success {
                successMessage = response.message ?? "Ticket enviado"
            } else {
                errorMessage = response.message ?? "Error al imprimir"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Line Management
    
    func addLine(product: Product) {
        let line = DeliveryItemLine(
            productCode: product.code,
            quantity: 1,
            unitPrice: product.price ?? 0,
            description: product.name
        )
        lines.append(line)
        searchQuery = ""
        searchResults = []
    }
    
    func addDiscountLine(for line: DeliveryItemLine) {
        let discount = DeliveryItemLine(
            productCode: line.productCode,
            quantity: -abs(line.quantity),
            unitPrice: line.unitPrice,
            description: "\(line.description ?? line.productCode) (Descuento)"
        )
        lines.append(discount)
    }
    
    func removeLine(at index: Int) {
        guard lines.indices.contains(index) else { return }
        lines.remove(at: index)
    }
    
    func updateLineQuantity(at index: Int, quantity: Double) {
        guard lines.indices.contains(index), quantity != 0 else { return }
        lines[index].quantity = quantity
    }

    // MARK: - Product Search
    
    func searchProducts() async {
        guard searchQuery.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            searchResults = try await service.searchProducts(query: searchQuery)
        } catch {
            searchResults = []
        }
    }
}
```

## 6. SwiftUI Views

### 6.1 DeliveriesListView (Improved)

Key improvements:
- CaleiTheme styling
- Pull-to-refresh
- Search bar
- Progress indicators on cards
- Empty states

```swift
import SwiftUI

struct DeliveriesListView: View {
    @StateObject private var viewModel = DeliveriesViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter
                statusPicker
                
                // Search bar
                searchBar
                
                // Content
                if viewModel.isLoading && viewModel.deliveries.isEmpty {
                    loadingView
                } else if viewModel.filteredDeliveries.isEmpty {
                    emptyView
                } else {
                    deliveryList
                }
            }
            .background(CaleiColors.background)
            .navigationTitle("Repartos")
            .toolbar { toolbarContent }
            .task { await viewModel.load() }
            .onChange(of: viewModel.statusFilter) { _, _ in
                Task { await viewModel.load() }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Components
    
    private var statusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DeliveryStatus.allCases, id: \.self) { status in
                    StatusChip(
                        title: status.displayName,
                        isSelected: viewModel.statusFilter == status,
                        color: status.color
                    ) {
                        viewModel.statusFilter = status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CaleiColors.gray400)
            
            TextField("Buscar reparto...", text: $viewModel.searchQuery)
                .font(CaleiTypography.body)
        }
        .padding(12)
        .background(CaleiColors.gray100)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var deliveryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredDeliveries) { delivery in
                    NavigationLink(destination: DeliveryDetailView(deliveryId: delivery.id)) {
                        DeliveryCard(delivery: delivery)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando repartos...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(CaleiColors.gray300)
            
            Text("Sin repartos")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.gray500)
            
            Text("No hay repartos para mostrar con los filtros actuales")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray400)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    // Profile
                } label: {
                    Label("Perfil", systemImage: "person.circle")
                }
                
                if appState.currentUser?.isAdmin == true {
                    Button {
                        // Admin
                    } label: {
                        Label("Administrador", systemImage: "gearshape")
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    Task { await appState.logout() }
                } label: {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(CaleiColors.accent)
            }
        }
    }
}

// MARK: - Delivery Card

struct DeliveryCard: View {
    let delivery: Delivery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(delivery.displayTitle)
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.dark)
                    
                    if let zone = delivery.zone {
                        Text(zone.name)
                            .font(CaleiTypography.caption)
                            .foregroundColor(CaleiColors.gray500)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: delivery.status)
            }
            
            // Progress
            if let total = delivery.itemsCount, let completed = delivery.completedCount {
                VStack(spacing: 6) {
                    ProgressView(value: delivery.progress)
                        .tint(delivery.status.color)
                    
                    HStack {
                        Text("\(completed)/\(total) completados")
                            .font(CaleiTypography.caption)
                            .foregroundColor(CaleiColors.gray500)
                        
                        Spacer()
                        
                        Text("\(Int(delivery.progress * 100))%")
                            .font(CaleiTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(delivery.status.color)
                    }
                }
            }
            
            // Date
            if let date = delivery.date {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(date)
                        .font(CaleiTypography.caption)
                }
                .foregroundColor(CaleiColors.gray400)
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: DeliveryStatus
    
    var body: some View {
        Text(status.displayName)
            .font(CaleiTypography.caption)
            .fontWeight(.medium)
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Status Chip

struct StatusChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CaleiTypography.buttonSmall)
                .foregroundColor(isSelected ? .white : CaleiColors.gray600)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : CaleiColors.gray100)
                .cornerRadius(20)
        }
    }
}
```

## 7. User Flows

### 7.1 View Deliveries Flow

```
1. Open "Repartos" tab
2. Load deliveries (GET /dealer/deliveries)
3. Filter by status (pending/in_progress/completed)
4. Search by name/zone
5. Tap delivery → Navigate to detail
```

### 7.2 Complete Order Flow

```
1. Open delivery detail
2. View items sorted by routeOrder
3. Tap item → Open edit view
4. Modify lines (add/remove products)
5. Add discounts if needed (negative quantity)
6. Set status to "completed"
7. Save (PATCH /dealer/delivery-items/:id)
8. Optional: Print ticket (POST /dealer/orders/:id/print)
```

### 7.3 Postpone Order Flow

```
1. Open item edit view
2. Set status to "postpone_rescue" or "postpone_next_week"
3. Add note explaining reason
4. Save
```

## 8. Implementation Checklist

### Phase 1: Models & Service (Foundation)
- [ ] Expand DeliveryModels.swift with all entities
- [ ] Update DealerService with all endpoints
- [ ] Add PrintTicketResponse model

### Phase 2: ViewModels
- [ ] Improve DeliveriesViewModel (search, computed props)
- [ ] Improve DeliveryDetailViewModel (map, sorting)
- [ ] Improve DeliveryItemEditViewModel (lines, search, print)

### Phase 3: Views
- [ ] Redesign DeliveriesListView with CaleiTheme
- [ ] Add DeliveryCard component
- [ ] Redesign DeliveryDetailView with map
- [ ] Redesign DeliveryItemEditView with line editor
- [ ] Add ProductSearchView for adding lines

### Phase 4: Polish
- [ ] Add haptic feedback
- [ ] Add loading states
- [ ] Add error handling with retry
- [ ] Add offline support consideration
- [ ] Test all flows

## 9. Notes

### 9.1 Quantity Rules
- Quantity can be **negative** (for discounts/warranties)
- Quantity **cannot be 0** (will cause 400 error)
- UnitPrice must be **>= 0**

### 9.2 Status Transitions
```
pending → completed (delivery successful)
pending → postpone_rescue (will retry soon)
pending → postpone_next_week (will retry next week)
```

### 9.3 External ID
- Each DeliveryItem has an `externalId` (e.g., "PED-2024-001")
- This maps to the external orders microservice
- Use for display, not for API calls (use `id` for API)
