import SwiftUI
import MapKit

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSideMenu = false
    @State private var navigateToZones = false
    @State private var navigateToVisitPoint = false
    @State private var selectedTab = 0

    var body: some View {
        if let user = appState.currentUser {
            let canShowDeliveries = user.canAccessDeliveries
            let canShowProducts = user.canAccessProducts
            let canShowTracks = user.canAccessTracks
            let canShowAdmin = user.isAdmin

            if canShowDeliveries || canShowProducts || canShowTracks || canShowAdmin {
                ZStack {
                    // TabView sin NavigationStack envolvente
                    TabView(selection: $selectedTab) {
                        if canShowDeliveries {
                            NavigationStack {
                                DeliveriesListView()
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                            sideMenuButton
                                        }
                                    }
                                    .navigationDestination(isPresented: $navigateToVisitPoint) {
                                        DealerVisitPointView()
                                    }
                            }
                            .tabItem {
                                Label("Repartos", systemImage: "shippingbox")
                            }
                            .tag(0)
                        }

                        if canShowTracks {
                            NavigationStack {
                                TracksListView()
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                            sideMenuButton
                                        }
                                    }
                                    .navigationDestination(isPresented: $navigateToVisitPoint) {
                                        DealerVisitPointView()
                                    }
                            }
                            .tabItem {
                                Label("Recorridos", systemImage: "map")
                            }
                            .tag(1)
                        }

                        if canShowProducts {
                            NavigationStack {
                                ProductSearchView()
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                            sideMenuButton
                                        }
                                    }
                                    .navigationDestination(isPresented: $navigateToVisitPoint) {
                                        DealerVisitPointView()
                                    }
                            }
                            .tabItem {
                                Label("Productos", systemImage: "magnifyingglass")
                            }
                            .tag(2)
                        }

                        if canShowAdmin {
                            // Admin con navegación a zonas
                            NavigationStack {
                                AdminHomeView(navigateToZones: $navigateToZones)
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                            sideMenuButton
                                        }
                                    }
                                    .navigationDestination(isPresented: $navigateToZones) {
                                        ZonesManagementView()
                                    }
                                    .navigationDestination(isPresented: $navigateToVisitPoint) {
                                        DealerVisitPointView()
                                    }
                            }
                            .tabItem {
                                Label("Admin", systemImage: "person.badge.key")
                            }
                            .tag(3)
                        }
                    }
                    
                    // Side Menu Overlay
                    SideMenuView(
                        isPresented: $showSideMenu,
                        navigateToZones: $navigateToZones,
                        navigateToVisitPoint: $navigateToVisitPoint,
                        selectedTab: $selectedTab
                    )
                        .zIndex(1)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Tu usuario no tiene módulos habilitados")
                        .font(.headline)
                    Text("Contactá a un administrador para asignar roles.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Usuario: \(user.username)")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("Roles: \(user.roles?.map { $0.name }.filter { !$0.isEmpty }.joined(separator: ", ") ?? "(vacío)")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Cerrar sesión") {
                        Task { await appState.logout() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        } else {
            ProgressView()
        }
    }
    
    private var sideMenuButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showSideMenu = true
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(CaleiColors.dark)
        }
    }
}

private struct DealerVisitPointView: View {
    @StateObject private var viewModel = DealerVisitPointViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: VisitPointTab = .list
    @State private var selectedMapItemId: Int?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -31.4201, longitude: -64.1888),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    private enum VisitPointTab: String, CaseIterable {
        case list = "Lista"
        case map = "Mapa"
    }

    var body: some View {
        VStack(spacing: 0) {
            topControls

            if viewModel.loading && sourceCardsCount == 0 && viewModel.sortedItems.isEmpty {
                loadingView
            } else {
                Group {
                    switch selectedTab {
                    case .list:
                        listContent
                    case .map:
                        mapContent
                    }
                }
            }
        }
        .background(CaleiColors.background)
        .navigationTitle("Visitar Puntos")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mapPointsSignature) { _, _ in
            updateMapRegionIfNeeded()
        }
        .task {
            await viewModel.loadInitial(currentUserId: appState.currentUser?.id)
            updateMapRegionIfNeeded()
        }
    }

    private var topControls: some View {
        VStack(spacing: 0) {
            tabSelector
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            Button {
                Task {
                    await viewModel.loadInitial(currentUserId: appState.currentUser?.id)
                    updateMapRegionIfNeeded()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Actualizar Puntos")
                        .font(CaleiTypography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(CaleiColors.accent)
                .cornerRadius(25)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            if let feedback = viewModel.feedbackMessage {
                Text(feedback)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(VisitPointTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(CaleiTypography.button)
                        .foregroundColor(selectedTab == tab ? .white : CaleiColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? CaleiColors.accent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(CaleiColors.gray200, lineWidth: 1)
        )
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.usingZonesFallback {
                    if viewModel.assignedZones.isEmpty {
                        sourceEmptyState(message: "No tenés zonas asignadas.")
                    } else {
                        ForEach(viewModel.assignedZones) { zone in
                            DealerVisitSourceCard(
                                title: zone.name,
                                subtitle: "\(zone.items.count) puntos de venta",
                                isSelected: viewModel.selectedZoneId == zone.id,
                                onTap: {
                                    Task {
                                        await viewModel.selectZone(zone.id)
                                        updateMapRegionIfNeeded()
                                    }
                                }
                            )
                        }
                    }
                } else {
                    DealerVisitSourceCard(
                        title: "Todos los repartos",
                        subtitle: "\(viewModel.deliveries.count) repartos",
                        isSelected: viewModel.selectedDeliveryId == nil,
                        onTap: {
                            Task {
                                await viewModel.selectDelivery(nil)
                                updateMapRegionIfNeeded()
                            }
                        }
                    )

                    ForEach(viewModel.deliveries) { delivery in
                        DealerVisitSourceCard(
                            title: delivery.displayTitle,
                            subtitle: delivery.deliveryStatus.displayName,
                            isSelected: viewModel.selectedDeliveryId == delivery.id,
                            onTap: {
                                Task {
                                    await viewModel.selectDelivery(delivery.id)
                                    updateMapRegionIfNeeded()
                                }
                            }
                        )
                    }
                }

                if hasActiveSelection {
                    HStack {
                        Text("Puntos a visitar")
                            .font(CaleiTypography.h4)
                            .foregroundColor(CaleiColors.dark)
                        Spacer()
                        Text("\(viewModel.sortedItems.count)")
                            .font(CaleiTypography.caption)
                            .foregroundColor(CaleiColors.gray500)
                    }
                    .padding(.top, 2)

                    if viewModel.sortedItems.isEmpty {
                        sourceEmptyState(message: "No hay puntos para visitar en la selección actual.")
                    } else {
                        ForEach(viewModel.sortedItems) { item in
                            DealerVisitPointCard(
                                item: item,
                                isSubmitting: viewModel.submittingItemIds.contains(item.id),
                                isArrived: viewModel.arrivedItemIds.contains(item.id),
                                onArrived: {
                                    Task { await viewModel.arrived(item: item) }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var mapContent: some View {
        VStack(spacing: 12) {
            if mapPoints.isEmpty {
                sourceEmptyState(message: "No hay ubicaciones para mostrar en el mapa.")
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
            } else {
                Map(coordinateRegion: $mapRegion, annotationItems: mapPoints) { point in
                    MapAnnotation(coordinate: point.coordinate) {
                        Button {
                            selectedMapItemId = point.id
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: viewModel.arrivedItemIds.contains(point.id) ? "checkmark.circle.fill" : "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.arrivedItemIds.contains(point.id) ? CaleiColors.success : CaleiColors.accent)
                                Text(point.item.displayName)
                                    .font(CaleiTypography.caption)
                                    .foregroundColor(CaleiColors.dark)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(CaleiColors.cardBackground)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                if let selectedItem = selectedMapItem {
                    Button {
                        Task { await viewModel.arrived(item: selectedItem) }
                    } label: {
                        Text(viewModel.arrivedItemIds.contains(selectedItem.id) ? "Llegada registrada" : "Llegué en \(selectedItem.displayName)")
                            .font(CaleiTypography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.arrivedItemIds.contains(selectedItem.id) ? CaleiColors.success : CaleiColors.accent)
                            .cornerRadius(14)
                    }
                    .disabled(viewModel.submittingItemIds.contains(selectedItem.id) || viewModel.arrivedItemIds.contains(selectedItem.id))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 92)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(CaleiColors.accent)
            Text("Cargando puntos...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
            Spacer()
        }
    }

    private func sourceEmptyState(message: String) -> some View {
        Text(message)
            .font(CaleiTypography.body)
            .foregroundColor(CaleiColors.gray500)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(CaleiColors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(CaleiColors.gray200, lineWidth: 1)
            )
    }

    private var sourceCardsCount: Int {
        viewModel.usingZonesFallback ? viewModel.assignedZones.count : viewModel.deliveries.count
    }

    private var hasActiveSelection: Bool {
        viewModel.usingZonesFallback ? viewModel.selectedZoneId != nil : true
    }

    private var mapPoints: [VisitMapPoint] {
        viewModel.sortedItems.compactMap { item in
            guard let coordinate = item.coordinate else { return nil }
            return VisitMapPoint(id: item.id, item: item, coordinate: coordinate)
        }
    }

    private var mapPointsSignature: String {
        mapPoints.map { "\($0.id)-\($0.coordinate.latitude)-\($0.coordinate.longitude)" }
            .joined(separator: "|")
    }

    private var selectedMapItem: DeliveryItem? {
        guard let selectedMapItemId else { return nil }
        return viewModel.sortedItems.first(where: { $0.id == selectedMapItemId })
    }

    private func updateMapRegionIfNeeded() {
        guard !mapPoints.isEmpty else { return }

        if selectedMapItemId == nil || selectedMapItem == nil {
            selectedMapItemId = mapPoints.first?.id
        }

        let coords = mapPoints.map { $0.coordinate }
        guard let first = coords.first else { return }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLng = first.longitude
        var maxLng = first.longitude

        for coordinate in coords {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.02),
            longitudeDelta: max((maxLng - minLng) * 1.8, 0.02)
        )

        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
}

private struct VisitMapPoint: Identifiable {
    let id: Int
    let item: DeliveryItem
    let coordinate: CLLocationCoordinate2D
}

private struct DealerVisitSourceCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                Text(subtitle)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }

            Spacer()

            if isSelected {
                Text("Activo")
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(CaleiColors.accent, lineWidth: 1)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(CaleiColors.gray400)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(16)
        .background(CaleiColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? CaleiColors.accent : CaleiColors.gray200, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

private struct DealerAssignedZone: Identifiable {
    let id: Int
    let name: String
    let boundaryPointsCount: Int
    var items: [DeliveryItem]
}

private struct DealerVisitPointCard: View {
    let item: DeliveryItem
    let isSubmitting: Bool
    let isArrived: Bool
    let onArrived: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.dark)

                    Text(routeOrderText)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }

                Spacer()

                Text(item.itemStatus.displayName)
                    .font(CaleiTypography.caption)
                    .foregroundColor(item.itemStatus.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.itemStatus.color.opacity(0.14))
                    .cornerRadius(8)
            }

            Button {
                onArrived()
            } label: {
                HStack(spacing: 6) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(isArrived ? "Llegada registrada" : "Llegué")
                        .font(CaleiTypography.buttonSmall)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isArrived ? CaleiColors.success : CaleiColors.accent)
                .cornerRadius(10)
            }
            .disabled(isSubmitting || isArrived)
            .opacity((isSubmitting || isArrived) ? 0.8 : 1)
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CaleiColors.gray200, lineWidth: 1)
        )
    }

    private var routeOrderText: String {
        if let route = item.routeOrder {
            return "Orden de ruta #\(route)"
        }
        return "Sin orden de ruta"
    }
}

@MainActor
private final class DealerVisitPointViewModel: ObservableObject {
    @Published var deliveries: [Delivery] = []
    @Published var assignedZones: [DealerAssignedZone] = []
    @Published var selectedDeliveryId: Int?
    @Published var selectedZoneId: Int?
    @Published var items: [DeliveryItem] = []
    @Published var usingZonesFallback = false
    @Published var loading = false
    @Published var submittingItemIds: Set<Int> = []
    @Published var arrivedItemIds: Set<Int> = []
    @Published var feedbackMessage: String?
    @Published var errorMessage: String?

    private let dealerService: DealerService
    private let zonesService: ZonesService
    private let apiClient: APIClient
    private let locationService: LocationService
    private let isoFormatter = ISO8601DateFormatter()

    init(
        dealerService: DealerService = DealerService(),
        zonesService: ZonesService = ZonesService(),
        apiClient: APIClient = .shared,
        locationService: LocationService = .shared
    ) {
        self.dealerService = dealerService
        self.zonesService = zonesService
        self.apiClient = apiClient
        self.locationService = locationService
        self.isoFormatter.formatOptions = [.withInternetDateTime]
    }

    var sortedItems: [DeliveryItem] {
        items.sorted {
            let lhsOrder = $0.routeOrder ?? Int.max
            let rhsOrder = $1.routeOrder ?? Int.max
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    func loadInitial(currentUserId: Int?) async {
        loading = true
        errorMessage = nil
        feedbackMessage = nil
        defer { loading = false }

        do {
            // Única fuente para esta pantalla: zonas asignadas al usuario logueado.
            let hasAssignedZones = try await loadAssignedZonesFallback(currentUserId: currentUserId)
            if !hasAssignedZones {
                items = []
                errorMessage = "No tenés zonas asignadas en este momento."
            }
        } catch {
            errorMessage = "No se pudieron cargar los puntos para visitar."
        }
    }

    func selectZone(_ zoneId: Int?) async {
        selectedZoneId = zoneId
        errorMessage = nil
        if let zoneId {
            if let cached = assignedZones.first(where: { $0.id == zoneId })?.items, !cached.isEmpty {
                items = cached
            } else {
                loading = true
                defer { loading = false }
                do {
                    let loaded = try await loadItemsForZone(zoneId: zoneId)
                    if let index = assignedZones.firstIndex(where: { $0.id == zoneId }) {
                        assignedZones[index].items = loaded
                    }
                    items = loaded
                } catch {
                    items = []
                    errorMessage = "No se pudieron cargar los puntos de la zona seleccionada."
                    return
                }
            }
            if items.isEmpty {
                errorMessage = "No hay puntos de venta para la zona seleccionada."
            }
        } else {
            items = assignedZones.flatMap { $0.items }
        }
    }

    func selectDelivery(_ deliveryId: Int?) async {
        selectedDeliveryId = deliveryId
        loading = true
        errorMessage = nil
        defer { loading = false }

        do {
            try await loadItemsForCurrentSelection()
            if items.isEmpty {
                errorMessage = "No hay puntos para visitar en el reparto seleccionado."
            }
        } catch {
            errorMessage = "No se pudieron cargar los pedidos del reparto seleccionado."
        }
    }

    private func loadItemsForCurrentSelection() async throws {
        if let deliveryId = selectedDeliveryId {
            items = try await dealerService.deliveryItems(deliveryId: deliveryId)
            return
        }

        var merged: [DeliveryItem] = []
        for delivery in deliveries {
            let deliveryItems = try await dealerService.deliveryItems(deliveryId: delivery.id)
            merged.append(contentsOf: deliveryItems)
        }

        items = merged
    }

    private func loadAssignedZonesFallback(currentUserId: Int?) async throws -> Bool {
        usingZonesFallback = true
        deliveries = []
        selectedDeliveryId = nil

        guard let currentUserId else {
            assignedZones = []
            items = []
            return false
        }

        let zones = try await zonesService.listZones()
        DLog("[VisitarPunto] Fallback zones count:", zones.count)
        if zones.isEmpty {
            assignedZones = []
            items = []
            return false
        }

        let assignedZoneIds = try await listAssignedZoneIdsForCurrentUser(userId: currentUserId, zones: zones)
        let assignedOnly = zones.filter { assignedZoneIds.contains($0.id) }
        DLog("[VisitarPunto] Zonas asignadas al usuario \(currentUserId):", assignedOnly.count)

        if assignedOnly.isEmpty {
            assignedZones = []
            items = []
            return false
        }

        // Efficiency: use /zones as the primary source for dealer-assigned zones.
        // The backend context for dealer users should already scope visible zones.
        let loadedZones: [DealerAssignedZone] = assignedOnly.map { zone in
            DealerAssignedZone(
                id: zone.id,
                name: zone.name,
                boundaryPointsCount: zone.boundaryPointsCount,
                items: []
            )
        }

        assignedZones = loadedZones.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        if assignedZones.isEmpty {
            items = []
            return false
        }

        selectedZoneId = nil
        items = []
        if let firstZoneId = assignedZones.first?.id {
            selectedZoneId = firstZoneId
            Task { [weak self] in
                await self?.selectZone(firstZoneId)
            }
        }

        if items.isEmpty, selectedZoneId == nil {
            errorMessage = "Tenés zonas asignadas, seleccioná una para ver sus puntos de venta."
        }

        return true
    }

    private func listAssignedZoneIdsForCurrentUser(userId: Int, zones: [GeoZone]) async throws -> Set<Int> {
        // 1) Try generic endpoint with userId query (most efficient)
        do {
            let endpoint = Endpoint(
                path: "/zone-assignments",
                method: .get,
                queryItems: [URLQueryItem(name: "userId", value: String(userId))]
            )
            let assignments = try await apiClient.request(endpoint, responseType: [ZoneAssignment].self)
            let ids: Set<Int> = Set(assignments.compactMap { assignment -> Int? in
                guard assignment.userId == userId else { return nil }
                if let isActive = assignment.isActive, !isActive { return nil }
                return assignment.zoneId
            })
            if !ids.isEmpty { return ids }
        } catch {
            DLog("[VisitarPunto] /zone-assignments?userId failed:", error)
        }

        // 2) Try alternative user endpoint
        do {
            let endpoint = Endpoint(path: "/zone-assignments/user/\(userId)", method: .get)
            let assignments = try await apiClient.request(endpoint, responseType: [ZoneAssignment].self)
            let ids: Set<Int> = Set(assignments.compactMap { assignment -> Int? in
                guard assignment.userId == userId else { return nil }
                if let isActive = assignment.isActive, !isActive { return nil }
                return assignment.zoneId
            })
            if !ids.isEmpty { return ids }
        } catch {
            DLog("[VisitarPunto] /zone-assignments/user/{id} failed:", error)
        }

        // 3) Fallback seguro: consultar asignaciones por cada zona visible
        var zoneIds = Set<Int>()
        for zone in zones {
            do {
                let assignments = try await zonesService.getZoneAssignments(zoneId: zone.id)
                let hasUser = assignments.contains { assignment in
                    guard assignment.userId == userId else { return false }
                    if let isActive = assignment.isActive, !isActive { return false }
                    return true
                }
                if hasUser {
                    zoneIds.insert(zone.id)
                }
            } catch {
                DLog("[VisitarPunto] Error consultando asignaciones de zona \(zone.id):", error)
            }
        }

        return zoneIds
    }

    private func loadItemsForZone(zoneId: Int) async throws -> [DeliveryItem] {
        let salePoints = try await listSalePoints(zoneId: zoneId)
        DLog("[VisitarPunto] zone", zoneId, "salePoints:", salePoints.count)
        return salePoints.map { point in
            DeliveryItem(
                id: point.id,
                externalId: nil,
                status: "pending",
                amount: nil,
                note: nil,
                routeOrder: nil,
                client: Client(id: nil, name: point.name, address: point.address, phone: point.phone),
                salePoint: ItemSalePoint(id: point.id, latitude: point.latitude, longitude: point.longitude)
            )
        }
    }

    private func listSalePoints(zoneId: Int) async throws -> [MarkedSalePoint] {
        let endpoint = Endpoint(
            path: "/sale-points",
            method: .get,
            queryItems: [URLQueryItem(name: "zoneId", value: String(zoneId))]
        )
        return try await apiClient.request(endpoint, responseType: [MarkedSalePoint].self)
    }

    func arrived(item: DeliveryItem) async {
        guard !submittingItemIds.contains(item.id) else { return }
        submittingItemIds.insert(item.id)
        feedbackMessage = nil
        errorMessage = nil

        let location = locationService.currentLocation
        if location == nil {
            locationService.requestSingleLocation()
        }

        let timestamp = isoFormatter.string(from: Date())

        do {
            try await dealerService.registerArrival(
                orderId: item.id,
                timestamp: timestamp,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            )
            arrivedItemIds.insert(item.id)
            feedbackMessage = "Llegada registrada en \(item.displayName)."
        } catch {
            errorMessage = "No se pudo registrar la llegada. Podés continuar y reintentar."
        }

        submittingItemIds.remove(item.id)
    }
}
