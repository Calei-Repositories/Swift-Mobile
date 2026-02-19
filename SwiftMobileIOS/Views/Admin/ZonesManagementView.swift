import SwiftUI
import MapKit

// MARK: - Zones Management View

struct ZonesManagementView: View {
    @StateObject private var viewModel = ZonesManagementViewModel()
    @State private var selectedTab: ZonesTab = .list
    @State private var showCreateSheet = false
    @State private var selectedZoneForEdit: GeoZone?
    @State private var showDeleteConfirmation = false
    @State private var zoneToDelete: GeoZone?
    @State private var showAssignSheet = false
    @State private var zoneToAssign: GeoZone?
    @State private var selectedSalePoint: MarkedSalePoint?
    @State private var showSalePointDetail = false
    @State private var selectedZoneForDetail: GeoZone?
    
    enum ZonesTab: String, CaseIterable {
        case list = "Lista"
        case map = "Mapa"
    }
    
    var body: some View {
        mainContent
            .navigationTitle("Gestión de Zonas")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Tabs tipo cápsula
            tabSelector
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            
            // Botón Crear Nueva Zona
            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Crear Nueva Zona")
                        .font(CaleiTypography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(CaleiColors.accent)
                .cornerRadius(25)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Contenido según tab
            Group {
                switch selectedTab {
                case .list:
                    zonesListContent
                case .map:
                    zonesMapContent
                }
            }
        }
        .background(CaleiColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(item: $selectedZoneForDetail) { zone in
            ZoneDetailView(zone: zone, salePoints: viewModel.salePointsForZone(zone))
        }
        .sheet(isPresented: $showCreateSheet) {
            ZoneEditorSheet(mode: .create) { name, isDangerous, points in
                Task {
                    _ = await viewModel.createZone(
                        name: name,
                        isDangerous: isDangerous,
                        boundaryPoints: points
                    )
                }
            }
        }
        .sheet(item: $selectedZoneForEdit) { zone in
            ZoneEditorSheet(mode: .edit(zone)) { name, isDangerous, points in
                Task {
                    let success = await viewModel.updateZone(
                        id: zone.id,
                        name: name,
                        isDangerous: isDangerous,
                        isActive: nil
                    )
                    if success, let points = points, !points.isEmpty {
                        _ = await viewModel.updateBoundaryPoints(zoneId: zone.id, points: points)
                    }
                }
            }
        }
        .sheet(item: $zoneToAssign) { zone in
            ZoneAssignmentSheet(zone: zone, viewModel: viewModel)
        }
        .sheet(isPresented: $showSalePointDetail) {
            if let salePoint = selectedSalePoint {
                MarkedSalePointDetailSheet(
                    salePoint: salePoint,
                    onSave: { request in
                        Task {
                            await viewModel.updateSalePoint(id: salePoint.id, request: request)
                        }
                    }
                )
            }
        }
        .confirmationDialog(
            "¿Eliminar zona?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let zone = zoneToDelete {
                    Task {
                        _ = await viewModel.deleteZone(zone)
                    }
                }
            }
            Button("Cancelar", role: .cancel) {
                zoneToDelete = nil
            }
        } message: {
            if let zone = zoneToDelete {
                Text("Se eliminará la zona \"\(zone.name)\" y todas sus asignaciones. Esta acción no se puede deshacer.")
            }
        }
        .task {
            await viewModel.loadZones()
        }
        .refreshable {
            await viewModel.refreshZones()
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ZonesTab.allCases, id: \.self) { tab in
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
    
    // MARK: - Zones List Content
    
    private var zonesListContent: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView
                
            case .error(let message):
                errorView(message: message)
                
            case .idle, .loaded:
                if viewModel.zones.isEmpty {
                    emptyStateView
                } else {
                    zonesList
                }
            }
        }
    }
    
    private var zonesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredZones) { zone in
                    Button {
                        selectedZoneForDetail = zone
                    } label: {
                        ZoneCardNew(
                            zone: zone,
                            salePointsCount: viewModel.salePointsCount(for: zone),
                            onTap: nil,
                            onEdit: {
                                selectedZoneForEdit = zone
                            },
                            onDelete: {
                                zoneToDelete = zone
                                showDeleteConfirmation = true
                            },
                            onAssign: {
                                zoneToAssign = zone
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Map Content
    
    private var zonesMapContent: some View {
        ZonesMapView(
            zones: viewModel.zones,
            salePoints: viewModel.visibleSalePoints,
            onZoneTap: { zone in
                selectedZoneForDetail = zone
            },
            onSalePointTap: { salePoint in
                selectedSalePoint = salePoint
                showSalePointDetail = true
            },
            onZoneLongPress: { zone in
                // Mantener presionado abre la interfaz de asignar
                zoneToAssign = zone
            },
            onRegionChanged: { region in
                Task {
                    await viewModel.loadSalePointsInRegion(region)
                }
            }
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(CaleiColors.accent)
            Text("Cargando zonas...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(CaleiColors.warning)
            
            Text("Error al cargar")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            Text(message)
                .font(CaleiTypography.bodySmall)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task { await viewModel.loadZones() }
            } label: {
                Text("Reintentar")
                    .font(CaleiTypography.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CaleiColors.accent)
                    .cornerRadius(12)
            }
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "hexagon")
                    .font(.system(size: 44))
                    .foregroundColor(CaleiColors.accent)
            }
            
            Text("Sin zonas")
                .font(CaleiTypography.h3)
                .foregroundColor(CaleiColors.dark)
            
            Text("Creá tu primera zona para organizar\ntu territorio de ventas.")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
            
            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Crear zona")
                }
                .font(CaleiTypography.button)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(CaleiColors.accentGradient)
                .cornerRadius(14)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Zone Card (New Design matching image)

struct ZoneCardNew: View {
    let zone: GeoZone
    let salePointsCount: Int // Conteo calculado localmente con ray-casting
    var onTap: (() -> Void)? = nil
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAssign: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Contenido izquierdo
            VStack(alignment: .leading, spacing: 6) {
                // Nombre de la zona
                Text(zone.name)
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                // ID
                Text("ID: \(zone.id)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                // Puntos de perímetro
                Text("Puntos de perímetro: \(zone.boundaryPointsCount)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                // Puntos de venta
                Text("Puntos de venta: \(salePointsCount)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
            
            Spacer()
            
            // Acciones (derecha)
            VStack(alignment: .trailing, spacing: 12) {
                // Botones de editar y eliminar
                HStack(spacing: 16) {
                    // Editar
                    Button {
                        onEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 18))
                                .foregroundColor(CaleiColors.gray500)
                        }
                        
                        // Eliminar
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(CaleiColors.error)
                        }
                    }
                    
                    Spacer()
                    
                    // Botón Asignar
                    Button {
                        onAssign()
                    } label: {
                        Text("Asignar")
                            .font(CaleiTypography.buttonSmall)
                            .foregroundColor(CaleiColors.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(CaleiColors.accent, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(16)
            .background(CaleiColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Zone Assignment Sheet (Selector de rol + listado incremental)

struct ZoneAssignmentSheet: View {
    let zone: GeoZone
    @ObservedObject var viewModel: ZonesManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRoleType: UserRoleType?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var users: [User] = []
    @State private var assignments: [ZoneUserAssignment] = []
    @State private var selectedUsers: [User] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedRoleType == nil {
                    roleSelector
                } else {
                    assignmentByRoleView
                }
            }
            .background(CaleiColors.background)
            .navigationTitle("Asignar zona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(CaleiColors.accent)
                }
            }
            .task {
                await loadAssignments()
            }
        }
    }
    
    // MARK: - Paso 1: Selector de Rol
    
    private var roleSelector: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 6) {
                Text("Asignar zona")
                    .font(CaleiTypography.h2)
                    .foregroundColor(CaleiColors.dark)
                
                Text(zone.name)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
            }
            
            Text("Elegí a qué rol querés asignarla.")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            VStack(spacing: 14) {
                roleButton(role: .seller)
                roleButton(role: .deliverer)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Cancelar")
                    .font(CaleiTypography.button)
                    .foregroundColor(CaleiColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(CaleiColors.gray300, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func roleButton(role: UserRoleType) -> some View {
        Button {
            selectedRoleType = role
            selectedUsers.removeAll()
            Task { await loadUsersForRole(role) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: role.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text("Asignar a \(role.displayName.lowercased())")
                    .font(CaleiTypography.button)
                Spacer()
            }
            .foregroundColor(CaleiColors.dark)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(CaleiColors.accentSoft)
            .cornerRadius(22)
        }
    }
    
    // MARK: - Paso 2: Asignación por rol
    
    private var assignmentByRoleView: some View {
        VStack(spacing: 0) {
            headerBar
            searchBar
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        loadingBlock
                    } else {
                        if !selectedUsers.isEmpty {
                            selectedUsersSection
                        }
                        assignedUsersSection
                        availableUsersSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            assignFooter
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button {
                selectedRoleType = nil
                searchText = ""
                selectedUsers.removeAll()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CaleiColors.accent)
            }
            
            Spacer()
            
            if let role = selectedRoleType {
                Text("Asignar zona a \(role.displayName.lowercased())")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
            }
            
            Spacer()
            
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CaleiColors.gray400)
            TextField("Buscar usuario...", text: $searchText)
                .font(CaleiTypography.body)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
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
    
    private var loadingBlock: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(CaleiColors.accent)
            Text("Cargando usuarios...")
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var selectedUsersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Seleccionados")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                Spacer()
                Text("\(selectedUsers.count)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray400)
            }
            
            ForEach(selectedUsers) { user in
                SelectedUserRow(user: user) {
                    selectedUsers.removeAll { $0.id == user.id }
                }
            }
        }
    }
    
    private var assignedUsersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Asignados")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                Spacer()
                Text("\(assignmentsForRole.count)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray400)
            }
            
            if assignmentsForRole.isEmpty {
                EmptyPlaceholderRow(text: "Sin asignados")
            } else {
                ForEach(assignmentsForRole) { assignment in
                    AssignedUserRow(assignment: assignment) {
                        Task { await removeAssignment(assignment) }
                    }
                }
            }
        }
    }
    
    private var availableUsersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usuarios")
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
            
            if filteredUsers.isEmpty {
                EmptyPlaceholderRow(text: searchText.isEmpty ? "No hay usuarios disponibles" : "Sin resultados para \"\(searchText)\"")
            } else {
                ForEach(filteredUsers) { user in
                    AvailableUserRow(
                        user: user,
                        isAssigned: isUserAssignedWithCurrentRole(user.id),
                        isSelected: selectedUsers.contains { $0.id == user.id }
                    ) {
                        toggleSelection(user)
                    }
                }
            }
        }
    }
    
    private var assignFooter: some View {
        VStack(spacing: 10) {
            Button {
                Task { await assignSelectedUsers() }
            } label: {
                Text("Asignar")
                    .font(CaleiTypography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedUsers.isEmpty ? CaleiColors.gray300 : CaleiColors.accent)
                    .cornerRadius(18)
            }
            .disabled(selectedUsers.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CaleiColors.background)
    }
    
    // MARK: - Computed Properties
    
    /// Asignaciones filtradas solo para ESTA zona
    private var assignmentsForThisZone: [ZoneUserAssignment] {
        // Si zoneId es nil en la asignación, la incluimos igual (el endpoint ya filtra por zona)
        return assignments.filter { $0.zoneId == zone.id || $0.zoneId == nil }
    }
    
    /// IDs de usuarios del rol actualmente seleccionado
    /// Esto viene de la lista de usuarios cargados por rol (GET /users/by-role?roleId=X)
    private var userIdsForCurrentRole: Set<Int> {
        Set(users.map { $0.id })
    }
    
    /// Asignaciones filtradas por rol seleccionado
    /// Cruza las asignaciones con la lista de usuarios del rol actual
    private var assignmentsForRole: [ZoneUserAssignment] {
        guard selectedRoleType != nil else {
            return assignmentsForThisZone
        }
        
        // Filtrar asignaciones donde el usuario pertenece al rol actual
        // (verificando si su ID está en la lista de usuarios cargados para este rol)
        return assignmentsForThisZone.filter { assignment in
            userIdsForCurrentRole.contains(assignment.userId)
        }
    }
    
    private var filteredUsers: [User] {
        let baseUsers = users
        if searchText.isEmpty {
            return baseUsers
        }
        return baseUsers.filter { user in
            user.username.localizedCaseInsensitiveContains(searchText) ||
            (user.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    /// Verifica si un usuario ya está asignado a esta zona CON EL ROL ACTUAL
    /// Un usuario puede estar asignado múltiples veces (una por cada rol)
    private func isUserAssignedWithCurrentRole(_ userId: Int) -> Bool {
        assignmentsForRole.contains { $0.userId == userId }
    }
    
    private func toggleSelection(_ user: User) {
        // Solo bloquear si ya está asignado CON ESTE ROL específico
        // Un usuario con doble rol puede asignarse en ambas pantallas
        guard !isUserAssignedWithCurrentRole(user.id) else { return }
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }
    
    // MARK: - Actions
    
    private func loadAssignments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            assignments = try await AdminService().listZoneAssignments(zoneId: zone.id)
            print("📋 Asignaciones cargadas: \(assignments.count) total")
            let forThisZone = assignments.filter { $0.zoneId == zone.id }
            print("📋 Asignaciones para zona \(zone.id) (\(zone.name)): \(forThisZone.count)")
            
            // Debug: mostrar información de rol de cada asignación
            for assignment in assignments {
                let username = assignment.user?.username ?? "unknown"
                let roleInfo = assignment.user?.role
                let rolesInfo = assignment.user?.roles
                let isSeller = assignment.user?.isSeller ?? false
                let isDeliverer = assignment.user?.isDeliverer ?? false
                print("   📌 Usuario: \(username), role: \(String(describing: roleInfo)), roles: \(String(describing: rolesInfo)), isSeller: \(isSeller), isDeliverer: \(isDeliverer)")
            }
        } catch {
            print("Error loading assignments: \(error)")
        }
    }
    
    private func loadUsersForRole(_ roleType: UserRoleType) async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await AdminService().listUsersByRoleType(roleType)
            print("📋 Usuarios disponibles para asignar: \(users.count)")
            for user in users.prefix(5) {
                print("   - \(user.username) (id: \(user.id))")
            }
        } catch {
            print("❌ Error loading users: \(error)")
        }
    }
    
    private func assignSelectedUsers() async {
        guard !selectedUsers.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        print("🔄 Intentando asignar \(selectedUsers.count) usuarios a zona \(zone.id)")
        
        var successCount = 0
        for user in selectedUsers {
            do {
                print("  → Asignando usuario \(user.username) (id: \(user.id))...")
                try await AdminService().assignZone(zoneId: zone.id, userId: user.id)
                successCount += 1
                print("  ✅ Usuario \(user.username) asignado correctamente")
            } catch {
                print("  ❌ Error asignando usuario \(user.username): \(error)")
            }
        }
        
        print("📊 Resultado: \(successCount)/\(selectedUsers.count) asignaciones exitosas")
        
        selectedUsers.removeAll()
        await loadAssignments()
        
        if successCount > 0 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func removeAssignment(_ assignment: ZoneUserAssignment) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AdminService().removeZoneAssignment(assignmentId: assignment.id)
            assignments.removeAll { $0.id == assignment.id }
        } catch {
            print("Error removing assignment: \(error)")
        }
    }
}

// MARK: - Assignment UI Rows

private struct AvailableUserRow: View {
    let user: User
    let isAssigned: Bool              // Asignado con el rol actual
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(CaleiColors.accentSoft)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.accent)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.dark)
                if let email = user.email {
                    Text(email)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
            }
            
            Spacer()
            
            if isAssigned {
                // Ya asignado con este rol
                Label("Asignado", systemImage: "checkmark.circle.fill")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.success)
            } else {
                // Disponible para asignar (aunque tenga otro rol asignado)
                Button {
                    onToggle()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? CaleiColors.success : CaleiColors.accent)
                }
            }
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(12)
    }
}

private struct SelectedUserRow: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(CaleiColors.accentSoft)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.accent)
                )
            
            Text(user.username)
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.dark)
            
            Spacer()
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(CaleiColors.gray400)
            }
        }
        .padding(10)
        .background(CaleiColors.gray100)
        .cornerRadius(10)
    }
}

private struct AssignedUserRow: View {
    let assignment: ZoneUserAssignment
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar con icono según rol
            Circle()
                .fill(roleColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: roleIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(roleColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(assignment.user?.username ?? "Usuario #\(assignment.userId)")
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.dark)
                    
                    // Badge de rol
                    Text(roleName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(roleColor.opacity(0.15))
                        .foregroundColor(roleColor)
                        .cornerRadius(4)
                }
                
                if let email = assignment.user?.email {
                    Text(email)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
            }
            
            Spacer()
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(CaleiColors.error)
                    .padding(8)
            }
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Role computed properties
    
    private var isSeller: Bool {
        assignment.user?.isSeller ?? false
    }
    
    private var isDeliverer: Bool {
        assignment.user?.isDeliverer ?? false
    }
    
    private var roleColor: Color {
        if isSeller { return CaleiColors.accent }
        if isDeliverer { return CaleiColors.warning }
        return CaleiColors.gray500
    }
    
    private var roleIcon: String {
        if isSeller { return "bag.fill" }
        if isDeliverer { return "shippingbox.fill" }
        return "person.fill"
    }
    
    private var roleName: String {
        assignment.user?.roleDisplayName ?? "Sin rol"
    }
}

private struct EmptyPlaceholderRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "minus.circle")
                .foregroundColor(CaleiColors.gray400)
            Text(text)
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
            Spacer()
        }
        .padding(12)
        .background(CaleiColors.gray100)
        .cornerRadius(10)
    }
}

// MARK: - User Assignment Row

struct UserAssignmentRow: View {
    let user: User
    let isAssigned: Bool
    let onAssign: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 44, height: 44)
                
                Text(user.username.prefix(1).uppercased())
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.accent)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.dark)
                
                if let email = user.email {
                    Text(email)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
            }
            
            Spacer()
            
            // Estado/Botón
            if isAssigned {
                Label("Asignado", systemImage: "checkmark.circle.fill")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.success)
            } else {
                Button {
                    onAssign()
                } label: {
                    Text("Asignar")
                        .font(CaleiTypography.buttonSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(CaleiColors.accent)
                        .cornerRadius(20)
                }
            }
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: ZoneUserAssignment
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 44, height: 44)
                
                Text(assignment.user?.username.prefix(1).uppercased() ?? "?")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.accent)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.user?.username ?? "Usuario #\(assignment.userId)")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.dark)
                
                if let roleDisplay = assignment.user?.roleDisplayName {
                    HStack(spacing: 4) {
                        Image(systemName: assignment.user?.isSeller == true ? "cart.fill" : "truck.box.fill")
                            .font(.system(size: 10))
                        Text(roleDisplay)
                    }
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                }
            }
            
            Spacer()
            
            // Botón eliminar
            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(CaleiColors.error)
                    .padding(8)
            }
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(12)
    }
}

// Modelo básico de usuario para asignación (mantener compatibilidad)
struct UserBasic: Codable, Identifiable {
    let id: Int
    let username: String
}

// MARK: - Zone Card (Legacy - keeping for compatibility)

struct ZoneCard: View {
    let zone: GeoZone
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(zone.swiftUIDisplayColor)
                    .frame(width: 12, height: 12)
                
                Text(zone.name)
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                Spacer()
                
                // Status badge
                if let isActive = zone.isActive {
                    Text(isActive ? "Activa" : "Inactiva")
                        .font(CaleiTypography.overline)
                        .foregroundColor(isActive ? CaleiColors.success : CaleiColors.gray500)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isActive ? CaleiColors.success.opacity(0.15) : CaleiColors.gray100)
                        )
                }
            }
            
            // Description
            if let description = zone.description, !description.isEmpty {
                Text(description)
                    .font(CaleiTypography.bodySmall)
                    .foregroundColor(CaleiColors.textSecondary)
                    .lineLimit(2)
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(zone.boundaryPointsCount) puntos", systemImage: "mappin.circle")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                Label("\(zone.salePointsCount) locales", systemImage: "storefront")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                Label("\(zone.assignmentsCount) asignados", systemImage: "person.2")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                Spacer()
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Editar")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.accent)
                }
                
                Spacer()
                
                Button {
                    onDelete()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Eliminar")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.error)
                }
            }
        }
        .padding(16)
        .background(CaleiColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Stat Mini Card

struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            Text(label)
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Zones Map View (Optimizado con tap en POIs y long press para asignar)

struct ZonesMapView: UIViewRepresentable {
    let zones: [GeoZone]
    let salePoints: [MarkedSalePoint]
    let onZoneTap: (GeoZone) -> Void
    var onSalePointTap: ((MarkedSalePoint) -> Void)?
    var onZoneLongPress: ((GeoZone) -> Void)?  // Nuevo: long press para asignar
    var onRegionChanged: ((MKCoordinateRegion) -> Void)?  // Callback cuando cambia la región visible
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .excludingAll // Mejor rendimiento
        
        // Agregar gesture recognizer para long press
        let longPressGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Calcular hash para detectar cambios reales
        let zonesHash = zones.map { $0.id }.hashValue
        let pointsHash = salePoints.map { $0.id }.hashValue
        
        // Solo actualizar si hay cambios
        let needsUpdate = zonesHash != context.coordinator.lastZonesHash || 
                          pointsHash != context.coordinator.lastPointsHash ||
                          context.coordinator.isFirstLoad
        
        guard needsUpdate else { return }
        
        context.coordinator.lastZonesHash = zonesHash
        context.coordinator.lastPointsHash = pointsHash
        context.coordinator.isFirstLoad = false
        
        // Actualizar overlays de zonas de forma eficiente
        updateZoneOverlays(mapView: mapView, context: context)
        
        // Actualizar anotaciones de forma eficiente
        updateAnnotations(mapView: mapView, context: context)
        
        // Ajustar región solo la primera vez
        if context.coordinator.shouldFitRegion {
            fitMapToContent(mapView: mapView)
            context.coordinator.shouldFitRegion = false
        }
    }
    
    private func updateZoneOverlays(mapView: MKMapView, context: Context) {
        // Remover overlays existentes
        mapView.removeOverlays(mapView.overlays)
        
        // Agregar polígonos de zonas
        for zone in zones {
            let coords = zone.polygonCoordinates
            guard coords.count >= 3 else { continue }
            
            var mutableCoords = coords
            let polygon = ZonePolygon(coordinates: &mutableCoords, count: coords.count)
            polygon.zone = zone
            mapView.addOverlay(polygon, level: .aboveLabels)
        }
    }
    
    private func updateAnnotations(mapView: MKMapView, context: Context) {
        // Remover anotaciones existentes (excepto user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Agregar anotaciones de zonas (en el centro)
        for zone in zones {
            if let center = zone.centerCoordinate {
                let annotation = ZoneAnnotation(zone: zone)
                annotation.coordinate = center
                annotation.title = zone.name
                mapView.addAnnotation(annotation)
            }
        }
        
        // Agregar puntos de venta
        for point in salePoints {
            let annotation = ZoneSalePointAnnotation(salePoint: point)
            annotation.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            annotation.title = point.name
            annotation.subtitle = point.address
            mapView.addAnnotation(annotation)
        }
    }
    
    private func fitMapToContent(mapView: MKMapView) {
        var allCoords: [CLLocationCoordinate2D] = zones.flatMap { $0.polygonCoordinates }
        allCoords.append(contentsOf: salePoints.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        })
        
        guard !allCoords.isEmpty else { return }
        
        let rect = allCoords.reduce(MKMapRect.null) { rect, coord in
            let point = MKMapPoint(coord)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
            return rect.union(pointRect)
        }
        
        let padding = UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)
        mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ZonesMapView
        var lastZonesHash: Int = 0
        var lastPointsHash: Int = 0
        var isFirstLoad: Bool = true
        var shouldFitRegion: Bool = true
        var regionChangeDebounceTask: Task<Void, Never>?
        
        init(_ parent: ZonesMapView) {
            self.parent = parent
        }
        
        // MARK: - Region Change Handler con debounce
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Cancelar tarea anterior si existe
            regionChangeDebounceTask?.cancel()
            
            // Debounce de 300ms para no hacer muchas llamadas
            regionChangeDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                guard !Task.isCancelled else { return }
                parent.onRegionChanged?(mapView.region)
            }
        }
        
        // MARK: - Long Press Handler para asignar zona
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let mapView = gesture.view as? MKMapView else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Buscar si el punto está dentro de alguna zona
            for zone in parent.zones {
                let coords = zone.polygonCoordinates
                guard coords.count >= 3 else { continue }
                
                if isPoint(coordinate, insidePolygon: coords) {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Llamar callback de long press
                    parent.onZoneLongPress?(zone)
                    return
                }
            }
        }
        
        private func isPoint(_ point: CLLocationCoordinate2D, insidePolygon polygon: [CLLocationCoordinate2D]) -> Bool {
            var isInside = false
            var j = polygon.count - 1
            
            for i in 0..<polygon.count {
                let xi = polygon[i].longitude
                let yi = polygon[i].latitude
                let xj = polygon[j].longitude
                let yj = polygon[j].latitude
                
                if ((yi > point.latitude) != (yj > point.latitude)) &&
                   (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi) {
                    isInside = !isInside
                }
                j = i
            }
            
            return isInside
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? ZonePolygon, let zone = polygon.zone {
                let renderer = MKPolygonRenderer(polygon: polygon)
                let color = UIColor(zone.swiftUIDisplayColor)
                renderer.fillColor = color.withAlphaComponent(0.15)
                renderer.strokeColor = color.withAlphaComponent(0.8)
                renderer.lineWidth = 2.5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            // Anotación de zona
            if let zoneAnnotation = annotation as? ZoneAnnotation {
                let identifier = "ZoneAnnotation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: zoneAnnotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                    view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                } else {
                    view?.annotation = zoneAnnotation
                }
                
                let zone = zoneAnnotation.zone
                view?.markerTintColor = UIColor(zone.swiftUIDisplayColor)
                view?.glyphImage = UIImage(systemName: zone.isDangerous == true ? "exclamationmark.triangle.fill" : "hexagon.fill")
                view?.displayPriority = .required
                
                return view
            }
            
            // Anotación de punto de venta
            if let salePointAnnotation = annotation as? ZoneSalePointAnnotation {
                let identifier = "ZoneSalePointAnnotation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: salePointAnnotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                    
                    // Botón de detalle
                    let detailButton = UIButton(type: .detailDisclosure)
                    view?.rightCalloutAccessoryView = detailButton
                } else {
                    view?.annotation = salePointAnnotation
                }
                
                let salePoint = salePointAnnotation.salePoint
                let hasZone = salePoint.zoneId != nil
                let hasWhatsApp = salePoint.hasWhatsApp ?? false
                
                // Color según estado
                if salePoint.status == "inactive" {
                    view?.markerTintColor = UIColor(CaleiColors.gray400)
                } else if hasZone {
                    view?.markerTintColor = UIColor(CaleiColors.success)
                } else {
                    view?.markerTintColor = UIColor(CaleiColors.warning)
                }
                
                // Ícono según características
                if hasWhatsApp {
                    view?.glyphImage = UIImage(systemName: "message.fill")
                } else {
                    view?.glyphImage = UIImage(systemName: "storefront.fill")
                }
                
                view?.displayPriority = .defaultHigh
                
                return view
            }
            
            // Fallback para MarkedPointAnnotation (compatibilidad)
            if let markedAnnotation = annotation as? MarkedPointAnnotation {
                let identifier = "MarkedPointAnnotation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: markedAnnotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                    view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                } else {
                    view?.annotation = markedAnnotation
                }
                
                let hasZone = markedAnnotation.salePoint.zoneId != nil
                view?.markerTintColor = hasZone ? UIColor(CaleiColors.success) : UIColor(CaleiColors.warning)
                view?.glyphImage = UIImage(systemName: "storefront.fill")
                
                return view
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let zoneAnnotation = view.annotation as? ZoneAnnotation {
                parent.onZoneTap(zoneAnnotation.zone)
            } else if let salePointAnnotation = view.annotation as? ZoneSalePointAnnotation {
                parent.onSalePointTap?(salePointAnnotation.salePoint)
            } else if let markedAnnotation = view.annotation as? MarkedPointAnnotation {
                parent.onSalePointTap?(markedAnnotation.salePoint)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            // Haptic feedback al seleccionar
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Custom Map Annotations

class ZonePolygon: MKPolygon {
    var zone: GeoZone?
}

class ZoneAnnotation: MKPointAnnotation {
    let zone: GeoZone
    
    init(zone: GeoZone) {
        self.zone = zone
        super.init()
    }
}

class ZoneSalePointAnnotation: MKPointAnnotation {
    let salePoint: MarkedSalePoint
    
    init(salePoint: MarkedSalePoint) {
        self.salePoint = salePoint
        super.init()
    }
}

class MarkedPointAnnotation: MKPointAnnotation {
    let salePoint: MarkedSalePoint
    
    init(salePoint: MarkedSalePoint) {
        self.salePoint = salePoint
        super.init()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZonesManagementView()
    }
}
