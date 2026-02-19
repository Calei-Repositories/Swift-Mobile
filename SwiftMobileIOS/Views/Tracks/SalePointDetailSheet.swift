import SwiftUI

struct SalePointDetailSheet: View {
    let salePoint: SalePoint
    let track: Track
    let onDelete: () -> Void
    let onTransfer: (Int) -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var showTransferSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con ícono
                headerSection
                
                // Información del punto
                infoSection
                
                Spacer()
                
                // Botones de acción
                actionButtons
            }
            .background(CaleiColors.gray50)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(CaleiColors.gray500)
                            .frame(width: 32, height: 32)
                            .background(CaleiColors.gray200)
                            .clipShape(Circle())
                    }
                }
            }
            .confirmationDialog(
                "¿Eliminar punto de venta?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    onDelete()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer. El punto \"\(salePoint.name)\" será eliminado permanentemente.")
            }
            .sheet(isPresented: $showTransferSheet) {
                TransferSalePointSheet(
                    salePoint: salePoint,
                    currentTrack: track,
                    onTransfer: { newTrackId in
                        showTransferSheet = false
                        onTransfer(newTrackId)
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: CaleiSpacing.space4) {
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(CaleiColors.accent)
            }
            
            Text(salePoint.name)
                .font(CaleiTypography.h3)
                .foregroundColor(CaleiColors.dark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CaleiSpacing.space6)
        .background(Color.white)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: CaleiSpacing.space4) {
            // Coordenadas
            if let coord = salePoint.coordinate {
                infoRow(
                    icon: "location.fill",
                    title: "Ubicación",
                    value: String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
                )
            }
            
            // Recorrido actual
            infoRow(
                icon: "map.fill",
                title: "Recorrido",
                value: track.name
            )
            
            // Fecha de creación
            if let createdAt = salePoint.createdAt {
                infoRow(
                    icon: "calendar",
                    title: "Creado",
                    value: formatDate(createdAt)
                )
            }
        }
        .padding(CaleiSpacing.space4)
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: CaleiSpacing.space4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(CaleiColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                
                Text(value)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.dark)
            }
            
            Spacer()
        }
        .padding(CaleiSpacing.space4)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: CaleiSpacing.space3) {
            // Botón transferir
            Button {
                showTransferSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 16))
                    Text("Transferir a otro recorrido")
                }
                .font(CaleiTypography.button)
                .foregroundColor(CaleiColors.dark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CaleiColors.accent)
                .cornerRadius(14)
            }
            
            // Botón eliminar
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    Text("Eliminar punto")
                }
                .font(CaleiTypography.button)
                .foregroundColor(CaleiColors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CaleiColors.error.opacity(0.1))
                .cornerRadius(14)
            }
        }
        .padding(CaleiSpacing.space4)
        .background(Color.white)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_AR")
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Transfer Sale Point Sheet

struct TransferSalePointSheet: View {
    let salePoint: SalePoint
    let currentTrack: Track
    let onTransfer: (Int) -> Void
    
    @StateObject private var viewModel = TransferViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrackId: Int?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: CaleiSpacing.space3) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 32))
                        .foregroundColor(CaleiColors.accent)
                    
                    Text("Transferir punto")
                        .font(CaleiTypography.h3)
                        .foregroundColor(CaleiColors.dark)
                    
                    Text("Seleccioná el recorrido destino para \"\(salePoint.name)\"")
                        .font(CaleiTypography.bodySmall)
                        .foregroundColor(CaleiColors.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, CaleiSpacing.space6)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                
                // Lista de recorridos
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(CaleiColors.accent)
                    Spacer()
                } else if viewModel.availableTracks.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: CaleiSpacing.space3) {
                            ForEach(viewModel.availableTracks) { track in
                                trackOptionRow(track)
                            }
                        }
                        .padding()
                    }
                }
                
                // Botón confirmar
                if selectedTrackId != nil {
                    confirmButton
                }
            }
            .background(CaleiColors.gray50)
            .navigationTitle("Transferir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(CaleiColors.gray500)
                }
            }
            .task {
                await viewModel.loadTracks(excluding: currentTrack.id)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: CaleiSpacing.space4) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(CaleiColors.gray400)
            
            Text("No hay otros recorridos")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            Text("Creá otro recorrido primero para poder transferir puntos")
                .font(CaleiTypography.bodySmall)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func trackOptionRow(_ track: Track) -> some View {
        Button {
            withAnimation(CaleiAnimations.quick) {
                selectedTrackId = track.id
            }
        } label: {
            HStack(spacing: CaleiSpacing.space4) {
                ZStack {
                    Circle()
                        .fill(selectedTrackId == track.id ? CaleiColors.accent : CaleiColors.gray200)
                        .frame(width: 24, height: 24)
                    
                    if selectedTrackId == track.id {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(CaleiTypography.buttonSmall)
                        .foregroundColor(CaleiColors.dark)
                    
                    HStack(spacing: 12) {
                        Label("\(track.pointsCount) puntos", systemImage: "mappin")
                        Text(track.formattedDate)
                    }
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                }
                
                Spacer()
            }
            .padding(CaleiSpacing.space4)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedTrackId == track.id ? CaleiColors.accent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var confirmButton: some View {
        Button {
            if let trackId = selectedTrackId {
                onTransfer(trackId)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill")
                Text("Confirmar transferencia")
            }
            .font(CaleiTypography.button)
            .foregroundColor(CaleiColors.dark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(CaleiColors.accent)
            .cornerRadius(14)
        }
        .padding()
        .background(Color.white)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Transfer ViewModel

@MainActor
final class TransferViewModel: ObservableObject {
    @Published var availableTracks: [Track] = []
    @Published var isLoading = false
    
    private let trackService = TrackService()
    
    func loadTracks(excluding currentTrackId: Int) async {
        isLoading = true
        do {
            let allTracks = try await trackService.listTracks()
            availableTracks = allTracks.filter { $0.id != currentTrackId }
        } catch {
            availableTracks = []
        }
        isLoading = false
    }
}

#Preview {
    SalePointDetailSheet(
        salePoint: SalePoint(
            id: 1,
            trackId: 1,
            name: "Punto 1 - Test",
            address: nil,
            latitude: -34.6037,
            longitude: -58.3816,
            phone: nil,
            email: nil,
            contactName: nil,
            notes: nil,
            statusId: nil,
            zoneId: nil,
            createdAt: "2026-01-25T14:00:00.000Z",
            status: nil,
            zone: nil
        ),
        track: Track(
            id: 1,
            name: "Recorrido Test",
            description: nil,
            userId: 1,
            completed: false,
            createdAt: "2026-01-25T14:00:00.000Z",
            updatedAt: nil,
            subTracks: nil,
            salePoints: nil,
            salePointsCount: nil,
            _count: nil
        ),
        onDelete: {},
        onTransfer: { _ in }
    )
}
