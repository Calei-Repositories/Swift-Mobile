import SwiftUI
import MapKit

struct DeliveryDetailView: View {
    let deliveryId: Int
    @StateObject private var viewModel: DeliveryDetailViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -31.4135, longitude: -64.1810),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedTab: DetailTab = .pending
    
    enum DetailTab: String, CaseIterable {
        case pending = "Pendientes"
        case completed = "Completados"
        case postponed = "Pospuestos"
    }
    
    init(deliveryId: Int) {
        self.deliveryId = deliveryId
        _viewModel = StateObject(wrappedValue: DeliveryDetailViewModel(deliveryId: deliveryId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card with delivery info
                if let delivery = viewModel.delivery {
                    deliveryHeader(delivery)
                }
                
                // Map section
                mapSection
                
                // Stats section
                statsSection
                
                // Items tabs
                itemsSection
            }
            .padding(16)
        }
        .background(CaleiColors.background)
        .navigationTitle(viewModel.delivery?.displayTitle ?? "Reparto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.delivery == nil {
                loadingOverlay
            }
        }
    }
    
    // MARK: - Delivery Header
    
    private func deliveryHeader(_ delivery: Delivery) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(delivery.displayTitle)
                        .font(CaleiTypography.h3)
                        .foregroundColor(CaleiColors.textPrimary)
                    
                    if let zone = delivery.zone {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(CaleiColors.accent)
                            Text(zone.name)
                        }
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.gray600)
                    }
                }
                
                Spacer()
                
                DeliveryStatusBadge(status: delivery.deliveryStatus)
            }
            
            // Progress
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CaleiColors.gray200)
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [CaleiColors.accent, CaleiColors.success],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * viewModel.progress, height: 10)
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text("\(viewModel.completedItems.count) de \(viewModel.items.count) completados")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(CaleiTypography.body)
                        .fontWeight(.bold)
                        .foregroundColor(CaleiColors.accent)
                }
            }
            
            // Date info
            HStack(spacing: 16) {
                if let date = delivery.date {
                    Label(date, systemImage: "calendar")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
                
                if let scheduled = delivery.scheduledDate {
                    Label(scheduled, systemImage: "clock")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.info)
                }
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Mapa de entregas")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: MarkNewSalePointView(deliveryId: deliveryId)) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Marcar punto")
                    }
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.accent)
                }
            }
            
            DeliveryMapView(
                region: $region,
                items: viewModel.sortedItems
            )
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.gray200, lineWidth: 1)
            )
            .onAppear {
                centerMapOnItems()
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    private func centerMapOnItems() {
        let coordinates = viewModel.itemCoordinates
        guard !coordinates.isEmpty else { return }
        
        if coordinates.count == 1 {
            region.center = coordinates[0]
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            return
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
            )
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "clock.fill",
                value: "\(viewModel.pendingItems.count)",
                label: "Pendientes",
                color: CaleiColors.warning
            )
            
            Divider()
                .frame(height: 50)
            
            statItem(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.completedItems.count)",
                label: "Completados",
                color: CaleiColors.success
            )
            
            Divider()
                .frame(height: 50)
            
            statItem(
                icon: "arrow.uturn.backward.circle.fill",
                value: "\(viewModel.postponedItems.count)",
                label: "Pospuestos",
                color: CaleiColors.info
            )
        }
        .padding(.vertical, 16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(CaleiTypography.h3)
                .foregroundColor(CaleiColors.textPrimary)
            
            Text(label)
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Items Section
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tab selector
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(CaleiTypography.buttonSmall)
                            .foregroundColor(selectedTab == tab ? .white : CaleiColors.gray600)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? CaleiColors.accent : CaleiColors.gray100)
                            .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
            
            // Items list
            let items = itemsForTab(selectedTab)
            
            if items.isEmpty {
                emptyItemsView
            } else {
                ForEach(items) { item in
                    NavigationLink(destination: DeliveryItemEditView(itemId: item.id)) {
                        DeliveryItemCard(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(CaleiColors.surface)
        .cornerRadius(16)
    }
    
    private func itemsForTab(_ tab: DetailTab) -> [DeliveryItem] {
        switch tab {
        case .pending:
            return viewModel.pendingItems.sorted { ($0.routeOrder ?? 999) < ($1.routeOrder ?? 999) }
        case .completed:
            return viewModel.completedItems
        case .postponed:
            return viewModel.postponedItems
        }
    }
    
    private var emptyItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(CaleiColors.gray300)
            
            Text("Sin items en esta categoría")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(CaleiColors.accent)
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
                
                Text("Cargando reparto...")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Delivery Item Card

struct DeliveryItemCard: View {
    let item: DeliveryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Route order badge
            if let order = item.routeOrder {
                Text("\(order)")
                    .font(CaleiTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(CaleiColors.accent)
                    .clipShape(Circle())
            }
            
            // Client info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(CaleiTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(CaleiColors.textPrimary)
                    .lineLimit(1)
                
                if let address = item.client?.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(address)
                            .lineLimit(1)
                    }
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                }
                
                if let amount = item.amount, amount > 0 {
                    Text("$\(amount, specifier: "%.2f")")
                        .font(CaleiTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(CaleiColors.success)
                }
            }
            
            Spacer()
            
            // Status icon
            Image(systemName: item.itemStatus.icon)
                .font(.title3)
                .foregroundColor(item.itemStatus.color)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CaleiColors.gray400)
        }
        .padding(12)
        .background(CaleiColors.gray50)
        .cornerRadius(12)
    }
}

// MARK: - Delivery Map View

struct DeliveryMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let items: [DeliveryItem]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        for item in items {
            guard let coordinate = item.coordinate else { continue }
            
            let annotation = DeliveryItemAnnotation(item: item)
            annotation.coordinate = coordinate
            annotation.title = item.displayName
            annotation.subtitle = item.client?.address
            mapView.addAnnotation(annotation)
        }
        
        // Fit to show all annotations
        if !items.isEmpty {
            let coordinates = items.compactMap { $0.coordinate }
            guard !coordinates.isEmpty else { return }
            
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude
            var maxLon = coordinates[0].longitude
            
            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
            )
            
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let itemAnnotation = annotation as? DeliveryItemAnnotation else { return nil }
            
            let identifier = "DeliveryItem"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            
            let status = itemAnnotation.item.itemStatus
            view?.markerTintColor = UIColor(status.color)
            view?.glyphImage = UIImage(systemName: status.icon)
            
            if let order = itemAnnotation.item.routeOrder {
                view?.glyphText = "\(order)"
            }
            
            return view
        }
    }
}

class DeliveryItemAnnotation: NSObject, MKAnnotation {
    let item: DeliveryItem
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    
    init(item: DeliveryItem) {
        self.item = item
    }
}

#Preview {
    NavigationStack {
        DeliveryDetailView(deliveryId: 1)
    }
}
