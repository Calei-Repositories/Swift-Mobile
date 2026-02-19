import SwiftUI

// MARK: - Navigation Destinations
enum TracksNavigationDestination: Hashable {
    case trackDetail(trackId: Int)
    case gpsRecording(track: Track)
}

struct TracksListView: View {
    @StateObject private var viewModel = TracksListViewModel()
    @StateObject private var offlineService = OfflineSyncService.shared
    @State private var showCreateTrack = false
    @State private var showActiveRecordingAlert = false
    @State private var navigationPath = NavigationPath()
    @State private var trackToDelete: Track?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Fondo
                CaleiColors.gray50
                    .ignoresSafeArea()
                
                Group {
                    switch viewModel.state {
                    case .loading:
                        loadingView
                        
                    case .error(let message):
                        errorView(message: message)
                        
                    case .idle, .loaded:
                        if viewModel.tracks.isEmpty {
                            emptyState
                        } else {
                            tracksContent
                        }
                    }
                }
            }
            .navigationTitle("Recorridos")
            .navigationDestination(for: TracksNavigationDestination.self) { destination in
                switch destination {
                case .trackDetail(let trackId):
                    TrackDetailView(trackId: trackId)
                case .gpsRecording(let track):
                    GPSRecordingView(track: track)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Verificar si hay un recorrido activo
                        if offlineService.hasActiveRecording {
                            showActiveRecordingAlert = true
                        } else {
                            showCreateTrack = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(CaleiColors.accent)
                    }
                }
                
                // Indicador de sincronización pendiente
                if offlineService.hasPendingData {
                    ToolbarItem(placement: .navigationBarLeading) {
                        syncIndicator
                    }
                }
            }
            .sheet(isPresented: $showCreateTrack) {
                CreateTrackView { createdTrack in
                    showCreateTrack = false
                    Task { await viewModel.loadTracks() }
                }
            }
            .alert("Recorrido activo", isPresented: $showActiveRecordingAlert) {
                Button("Continuar grabando") {
                    // Navegar al recorrido activo
                    if let state = offlineService.currentRecordingState,
                       let track = viewModel.tracks.first(where: { $0.id == state.trackId }) {
                        navigationPath.append(TracksNavigationDestination.gpsRecording(track: track))
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Ya tenés un recorrido en progreso. ¿Querés continuar con la grabación?")
            }
            .alert("¿Eliminar recorrido?", isPresented: $showDeleteConfirmation) {
                Button("Eliminar", role: .destructive) {
                    if let track = trackToDelete {
                        Task {
                            await viewModel.deleteTrack(track)
                        }
                    }
                }
                Button("Cancelar", role: .cancel) {
                    trackToDelete = nil
                }
            } message: {
                if let track = trackToDelete {
                    Text("Se eliminará el recorrido \"\(track.name)\" y todos sus puntos de venta. Esta acción no se puede deshacer.")
                }
            }
            .task {
                await viewModel.loadTracks()
            }
            .onReceive(offlineService.$currentRecordingState) { newState in
                // Cuando se detiene una grabación (newState == nil), recargar la lista
                // para actualizar el orden según la última actividad
                if newState == nil {
                    Task {
                        await viewModel.loadTracks()
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: CaleiSpacing.space4) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(CaleiColors.accent)
            
            Text("Cargando recorridos...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: CaleiSpacing.space6) {
            ZStack {
                Circle()
                    .fill(CaleiColors.warning.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(CaleiColors.warning)
            }
            
            Text("Error al cargar")
                .font(CaleiTypography.h3)
                .foregroundColor(CaleiColors.dark)
            
            Text(message)
                .font(CaleiTypography.bodySmall)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task { await viewModel.loadTracks() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Reintentar")
                }
                .caleiSecondaryButton()
            }
        }
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: CaleiSpacing.space6) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 50))
                    .foregroundColor(CaleiColors.accent)
            }
            .scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                value: UUID()
            )
            
            VStack(spacing: CaleiSpacing.space3) {
                Text("No tenés recorridos")
                    .font(CaleiTypography.h2)
                    .foregroundColor(CaleiColors.dark)
                
                Text("Creá tu primer recorrido para empezar a grabar rutas y marcar puntos de venta.")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showCreateTrack = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Crear recorrido")
                }
                .caleiPrimaryButton()
            }
            .padding(.top, CaleiSpacing.space4)
            
            Spacer()
        }
    }
    
    // MARK: - Tracks Content
    
    private var tracksContent: some View {
        ScrollView {
            LazyVStack(spacing: CaleiSpacing.space4) {
                // Recorrido activo (si hay uno)
                if let activeState = offlineService.currentRecordingState,
                   let activeTrack = viewModel.tracks.first(where: { $0.id == activeState.trackId }) {
                    activeTrackCard(track: activeTrack, state: activeState)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Lista de recorridos
                ForEach(viewModel.tracks) { track in
                    // No mostrar el activo de nuevo
                    if track.id != offlineService.currentRecordingState?.trackId {
                        Button {
                            navigationPath.append(TracksNavigationDestination.trackDetail(trackId: track.id))
                        } label: {
                            TrackCardView(track: track, onDelete: {
                                trackToDelete = track
                                showDeleteConfirmation = true
                            })
                        }
                        .buttonStyle(CardButtonStyle())
                        .contextMenu {
                            Button {
                                navigationPath.append(TracksNavigationDestination.trackDetail(trackId: track.id))
                            } label: {
                                Label("Ver detalles", systemImage: "info.circle")
                            }
                            
                            Button {
                                navigationPath.append(TracksNavigationDestination.gpsRecording(track: track))
                            } label: {
                                Label("Grabar", systemImage: "record.circle")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                trackToDelete = track
                                showDeleteConfirmation = true
                            } label: {
                                Label("Eliminar recorrido", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                trackToDelete = track
                                showDeleteConfirmation = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadTracks()
        }
    }
    
    // MARK: - Active Track Card
    
    private func activeTrackCard(track: Track, state: RecordingState) -> some View {
        Button {
            navigationPath.append(TracksNavigationDestination.gpsRecording(track: track))
        } label: {
            VStack(spacing: 0) {
                // Header con indicador de grabación
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(state.isPaused ? CaleiColors.warning : CaleiColors.error)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(state.isPaused ? CaleiColors.warning : CaleiColors.error, lineWidth: 2)
                                    .scaleEffect(1.5)
                                    .opacity(state.isPaused ? 0 : 0.5)
                            )
                        
                        Text(state.isPaused ? "EN PAUSA" : "GRABANDO")
                            .font(CaleiTypography.overline)
                            .foregroundColor(state.isPaused ? CaleiColors.warning : CaleiColors.error)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CaleiColors.gray400)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(state.isPaused ? CaleiColors.warning.opacity(0.1) : CaleiColors.error.opacity(0.1))
                
                // Contenido
                VStack(alignment: .leading, spacing: 12) {
                    Text(track.name)
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.dark)
                    
                    HStack(spacing: 20) {
                        statLabel(
                            icon: "arrow.triangle.swap",
                            value: formatDistance(state.totalDistance)
                        )
                        
                        statLabel(
                            icon: "mappin.circle.fill",
                            value: "\(state.pointsCount) puntos"
                        )
                        
                        statLabel(
                            icon: "clock.fill",
                            value: formatDuration(from: state.startTime)
                        )
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: CaleiColors.error.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(state.isPaused ? CaleiColors.warning : CaleiColors.error, lineWidth: 2)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
    
    // MARK: - Sync Indicator
    
    private var syncIndicator: some View {
        HStack(spacing: 6) {
            if offlineService.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "icloud.and.arrow.up")
            }
            Text("\(offlineService.totalPendingCount)")
                .font(CaleiTypography.caption)
        }
        .foregroundColor(offlineService.isOnline ? CaleiColors.accent : CaleiColors.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CaleiColors.accentSoft)
        .cornerRadius(20)
        .onTapGesture {
            offlineService.syncPendingData()
        }
    }
    
    // MARK: - Helpers
    
    private func statLabel(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CaleiColors.accent)
            Text(value)
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Track Card View

struct TrackCardView: View {
    let track: Track
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(CaleiTypography.h4)
                        .foregroundColor(CaleiColors.dark)
                        .lineLimit(1)
                    
                    if let description = track.description, !description.isEmpty {
                        Text(description)
                            .font(CaleiTypography.bodySmall)
                            .foregroundColor(CaleiColors.gray500)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CaleiColors.gray400)
            }
            
            Divider()
                .background(CaleiColors.gray200)
            
            // Stats
            HStack(spacing: 16) {
                trackStat(
                    icon: "mappin.circle.fill",
                    value: "\(track.pointsCount)",
                    label: "puntos"
                )
                
                if track.totalDistance > 0 {
                    trackStat(
                        icon: "arrow.triangle.swap",
                        value: formatDistance(track.totalDistance),
                        label: ""
                    )
                }
                
                Spacer()
                
                // Botón eliminar
                if let onDelete = onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(CaleiColors.gray400)
                            .frame(width: 32, height: 32)
                            .background(CaleiColors.gray100)
                            .clipShape(Circle())
                    }
                }
                
                Text(track.formattedDate)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray400)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private func trackStat(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(CaleiColors.accent)
            
            Text(value)
                .font(CaleiTypography.buttonSmall)
                .foregroundColor(CaleiColors.dark)
            
            if !label.isEmpty {
                Text(label)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(CaleiAnimations.quick, value: configuration.isPressed)
    }
}

#Preview {
    TracksListView()
}
