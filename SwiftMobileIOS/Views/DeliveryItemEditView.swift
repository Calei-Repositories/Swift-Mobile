import SwiftUI

struct DeliveryItemEditView: View {
    let itemId: Int
    @StateObject private var viewModel: DeliveryItemEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmSave = false
    
    init(itemId: Int) {
        self.itemId = itemId
        _viewModel = StateObject(wrappedValue: DeliveryItemEditViewModel(itemId: itemId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Client info card
                if let client = viewModel.client {
                    clientCard(client)
                }
                
                // Status selector
                statusSection
                
                // Lines section
                linesSection
                
                // Amount and note
                amountNoteSection
                
                // Action buttons
                actionButtons
            }
            .padding(16)
        }
        .background(CaleiColors.background)
        .navigationTitle("Pedido #\(itemId)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showProductSearch) {
            ProductSearchSheet(
                searchQuery: $viewModel.searchQuery,
                searchResults: viewModel.searchResults,
                isSearching: viewModel.isSearching,
                onSearch: { await viewModel.searchProducts() },
                onSelect: { product in
                    viewModel.addLine(product: product)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Guardar cambios", isPresented: $showConfirmSave) {
            Button("Guardar") {
                Task {
                    if await viewModel.save() {
                        dismiss()
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Confirmar los cambios realizados?")
        }
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Client Card
    
    private func clientCard(_ client: Client) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(CaleiColors.accentSoft)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(CaleiColors.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.textPrimary)
                    
                    if let address = client.address {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption)
                            Text(address)
                        }
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    }
                }
                
                Spacer()
                
                if let phone = client.phone {
                    Button {
                        if let url = URL(string: "tel://\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundColor(CaleiColors.success)
                            .padding(12)
                            .background(CaleiColors.success.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estado del pedido")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ItemStatus.allCases, id: \.self) { status in
                    StatusOption(
                        status: status,
                        isSelected: viewModel.status == status
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.status = status
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Lines Section
    
    private var linesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Productos")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.textPrimary)
                
                Spacer()
                
                Button {
                    viewModel.showProductSearch = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.accent)
                }
            }
            
            if viewModel.lines.isEmpty {
                emptyLinesView
            } else {
                ForEach(Array(viewModel.lines.enumerated()), id: \.offset) { index, line in
                    LineItemRow(
                        line: line,
                        onQuantityChange: { qty in
                            viewModel.updateLineQuantity(at: index, quantity: qty)
                        },
                        onPriceChange: { price in
                            viewModel.updateLinePrice(at: index, price: price)
                        },
                        onAddDiscount: {
                            viewModel.addDiscountLine(for: line)
                        },
                        onDelete: {
                            viewModel.removeLine(at: index)
                        }
                    )
                }
                
                // Total
                HStack {
                    Text("Total")
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.textPrimary)
                    
                    Spacer()
                    
                    Text("$\(viewModel.totalAmount, specifier: "%.2f")")
                        .font(CaleiTypography.h3)
                        .foregroundColor(CaleiColors.success)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    private var emptyLinesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 40))
                .foregroundColor(CaleiColors.gray300)
            
            Text("Sin productos")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
            
            Button {
                viewModel.showProductSearch = true
            } label: {
                Text("Agregar producto")
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Amount Note Section
    
    private var amountNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalles adicionales")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.textPrimary)
            
            // Amount
            VStack(alignment: .leading, spacing: 4) {
                Text("Monto cobrado")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                HStack {
                    Text("$")
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.gray500)
                    
                    TextField("0.00", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .font(CaleiTypography.body)
                }
                .padding(12)
                .background(CaleiColors.gray100)
                .cornerRadius(8)
            }
            
            // Note
            VStack(alignment: .leading, spacing: 4) {
                Text("Nota")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                TextField("Agregar nota...", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...6)
                    .font(CaleiTypography.body)
                    .padding(12)
                    .background(CaleiColors.gray100)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save button
            Button {
                showConfirmSave = true
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(viewModel.isSaving ? "Guardando..." : "Guardar cambios")
                }
                .font(CaleiTypography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.canSave ? CaleiColors.accentGradient : LinearGradient(colors: [CaleiColors.gray400], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSave || viewModel.isSaving)
            
            // Print button
            Button {
                Task { await viewModel.printTicket() }
            } label: {
                HStack {
                    if viewModel.isPrinting {
                        ProgressView()
                            .tint(CaleiColors.accent)
                    } else {
                        Image(systemName: "printer.fill")
                    }
                    Text(viewModel.isPrinting ? "Imprimiendo..." : "Imprimir ticket")
                }
                .font(CaleiTypography.button)
                .foregroundColor(CaleiColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CaleiColors.accentSoft)
                .cornerRadius(12)
            }
            .disabled(viewModel.isPrinting)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if let externalId = viewModel.itemDetail?.item.externalId {
                Text(externalId)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            CaleiColors.background.opacity(0.8)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(CaleiColors.accent)
                
                Text("Cargando pedido...")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Status Option

struct StatusOption: View {
    let status: ItemStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.body)
                
                Text(status.displayName)
                    .font(CaleiTypography.buttonSmall)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : status.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? status.color : status.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(status.color, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Line Item Row

struct LineItemRow: View {
    let line: DeliveryItemLine
    let onQuantityChange: (Double) -> Void
    let onPriceChange: (Double) -> Void
    let onAddDiscount: () -> Void
    let onDelete: () -> Void
    
    @State private var quantityText: String = ""
    @State private var priceText: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.description ?? line.productCode)
                        .font(CaleiTypography.body)
                        .foregroundColor(line.isDiscount ? CaleiColors.error : CaleiColors.textPrimary)
                        .lineLimit(2)
                    
                    Text(line.productCode)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
                
                Spacer()
                
                Menu {
                    if !line.isDiscount {
                        Button {
                            onAddDiscount()
                        } label: {
                            Label("Agregar descuento", systemImage: "minus.circle")
                        }
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(CaleiColors.gray400)
                }
            }
            
            HStack(spacing: 12) {
                // Quantity
                HStack {
                    Text("Cant:")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    
                    TextField("0", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .font(CaleiTypography.body)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .onChange(of: quantityText) { _, newValue in
                            if let qty = Double(newValue) {
                                onQuantityChange(qty)
                            }
                        }
                }
                .padding(8)
                .background(CaleiColors.gray100)
                .cornerRadius(8)
                
                // Price
                HStack {
                    Text("$")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    
                    TextField("0", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(CaleiTypography.body)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: priceText) { _, newValue in
                            if let price = Double(newValue) {
                                onPriceChange(price)
                            }
                        }
                }
                .padding(8)
                .background(CaleiColors.gray100)
                .cornerRadius(8)
                
                Spacer()
                
                // Line total
                Text("$\(line.lineTotal, specifier: "%.2f")")
                    .font(CaleiTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(line.isDiscount ? CaleiColors.error : CaleiColors.success)
            }
        }
        .padding(12)
        .background(line.isDiscount ? CaleiColors.error.opacity(0.05) : CaleiColors.gray50)
        .cornerRadius(12)
        .onAppear {
            quantityText = String(format: "%.0f", line.quantity)
            priceText = String(format: "%.2f", line.unitPrice)
        }
    }
}

// MARK: - Product Search Sheet

struct ProductSearchSheet: View {
    @Binding var searchQuery: String
    let searchResults: [Product]
    let isSearching: Bool
    let onSearch: () async -> Void
    let onSelect: (Product) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(CaleiColors.gray400)
                    
                    TextField("Buscar producto...", text: $searchQuery)
                        .font(CaleiTypography.body)
                        .onChange(of: searchQuery) { _, _ in
                            Task { await onSearch() }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(CaleiColors.gray400)
                        }
                    }
                }
                .padding(12)
                .background(CaleiColors.gray100)
                .cornerRadius(12)
                .padding(16)
                
                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(CaleiColors.accent)
                    Spacer()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(CaleiColors.gray300)
                        
                        Text("Sin resultados")
                            .font(CaleiTypography.body)
                            .foregroundColor(CaleiColors.gray500)
                    }
                    Spacer()
                } else {
                    List(searchResults) { product in
                        Button {
                            onSelect(product)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.description ?? "Sin nombre")
                                        .font(CaleiTypography.body)
                                        .foregroundColor(CaleiColors.textPrimary)
                                    
                                    Text(product.code ?? "-")
                                        .font(CaleiTypography.caption)
                                        .foregroundColor(CaleiColors.gray500)
                                }
                                
                                Spacer()
                                
                                if let price = product.unitPrice {
                                    Text("$\(price, specifier: "%.2f")")
                                        .font(CaleiTypography.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(CaleiColors.success)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Buscar producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeliveryItemEditView(itemId: 1)
    }
}
