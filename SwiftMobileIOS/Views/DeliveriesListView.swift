import SwiftUI

struct DeliveriesListView: View {
    @StateObject private var viewModel = DeliveriesViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter chips
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Status Picker
    
    private var statusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DeliveryStatus.allCases, id: \.self) { status in
                    StatusChip(
                        title: status.displayName,
                        icon: status.icon,
                        count: countFor(status),
                        isSelected: viewModel.statusFilter == status,
                        color: status.color
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.statusFilter = status
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CaleiColors.surface)
    }
    
    private func countFor(_ status: DeliveryStatus) -> Int? {
        switch status {
        case .pending: return viewModel.pendingCount
        case .inProgress: return viewModel.inProgressCount
        case .completed: return viewModel.completedCount
        case .all: return nil
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CaleiColors.gray400)
            
            TextField("Buscar reparto o zona...", text: $viewModel.searchQuery)
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.textPrimary)
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CaleiColors.gray400)
                }
            }
        }
        .padding(12)
        .background(CaleiColors.gray100)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Delivery List
    
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
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(CaleiColors.accent)
            
            Text("Cargando repartos...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(CaleiColors.gray300)
            
            Text("Sin repartos")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.textPrimary)
            
            Text("No hay repartos para mostrar con los filtros actuales")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.statusFilter = .all
                viewModel.searchQuery = ""
            } label: {
                Text("Limpiar filtros")
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.accent)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    // TODO: Profile navigation
                } label: {
                    Label("Perfil", systemImage: "person.circle")
                }
                
                if appState.currentUser?.isAdmin == true {
                    Button {
                        // TODO: Admin navigation
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(delivery.displayTitle)
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.textPrimary)
                        .lineLimit(2)
                    
                    if let zone = delivery.zone {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(zone.name)
                        }
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    }
                }
                
                Spacer()
                
                DeliveryStatusBadge(status: delivery.deliveryStatus)
            }
            
            // Progress bar
            if let total = delivery.itemsCount, let completed = delivery.completedCount, total > 0 {
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CaleiColors.gray200)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(delivery.deliveryStatus.color)
                                .frame(width: geometry.size.width * delivery.progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(CaleiColors.success)
                            Text("\(completed)/\(total)")
                                .font(CaleiTypography.caption)
                                .foregroundColor(CaleiColors.gray600)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(delivery.progress * 100))%")
                            .font(CaleiTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(delivery.deliveryStatus.color)
                    }
                }
            }
            
            // Footer with date
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

struct DeliveryStatusBadge: View {
    let status: DeliveryStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(CaleiTypography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Status Chip

struct StatusChip: View {
    let title: String
    let icon: String
    let count: Int?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(CaleiTypography.buttonSmall)
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(CaleiTypography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .foregroundColor(isSelected ? .white : CaleiColors.gray600)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : CaleiColors.gray100)
            .cornerRadius(20)
        }
    }
}

#Preview {
    DeliveriesListView()
        .environmentObject(AppState())
}
