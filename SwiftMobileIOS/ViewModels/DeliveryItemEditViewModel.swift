import Foundation
import UIKit

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
    @Published var showProductSearch = false
    
    // MARK: - Computed Properties
    
    var client: Client? {
        itemDetail?.item.client
    }
    
    var totalAmount: Double {
        lines.reduce(0) { $0 + $1.lineTotal }
    }
    
    var hasChanges: Bool {
        guard let original = itemDetail else { return false }
        return status != original.item.itemStatus ||
               amount != String(format: "%.2f", original.item.amount ?? 0) ||
               note != (original.item.note ?? "") ||
               lines != (original.lines ?? [])
    }
    
    var canSave: Bool {
        !isSaving && (status != .pending || !lines.isEmpty)
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
            status = detail.item.itemStatus
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
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
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
                successMessage = response.message ?? "Ticket enviado a impresión"
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
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
            productCode: product.code ?? "",
            quantity: 1,
            unitPrice: product.unitPrice ?? 0,
            description: product.description
        )
        lines.append(line)
        searchQuery = ""
        searchResults = []
        showProductSearch = false
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func addDiscountLine(for line: DeliveryItemLine) {
        let discount = DeliveryItemLine(
            productCode: line.productCode,
            quantity: -abs(line.quantity),
            unitPrice: line.unitPrice,
            description: "\(line.description ?? line.productCode) (Descuento)"
        )
        lines.append(discount)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func removeLine(at index: Int) {
        guard lines.indices.contains(index) else { return }
        lines.remove(at: index)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func updateLineQuantity(at index: Int, quantity: Double) {
        guard lines.indices.contains(index), quantity != 0 else { return }
        lines[index].quantity = quantity
    }
    
    func updateLinePrice(at index: Int, price: Double) {
        guard lines.indices.contains(index), price >= 0 else { return }
        lines[index].unitPrice = price
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
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}
