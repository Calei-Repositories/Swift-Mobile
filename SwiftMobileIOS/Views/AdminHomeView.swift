import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var navigateToZones: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                adminHeader
                
                // Secciones de administración
                VStack(spacing: 12) {
                    // Puntos Marcados
                    NavigationLink(destination: AdminMarkedPointsView()) {
                        AdminMenuCard(
                            icon: "mappin.circle.fill",
                            title: "Puntos Marcados",
                            subtitle: "Ver puntos de venta marcados por vendedores",
                            color: CaleiColors.success
                        )
                    }
                    
                    // Usuarios por Rol
                    NavigationLink(destination: AdminUsersView()) {
                        AdminMenuCard(
                            icon: "person.2.fill",
                            title: "Usuarios por Rol",
                            subtitle: "Gestionar usuarios y asignaciones",
                            color: CaleiColors.info
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(CaleiColors.gray50)
        .navigationTitle("Administración")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        // TODO: navegar a perfil
                    } label: {
                        Label("Perfil", systemImage: "person")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        Task { await appState.logout() }
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(CaleiColors.accent)
                }
            }
        }
    }
    
    // MARK: - Admin Header
    
    private var adminHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = appState.currentUser {
                Text("Hola, \(user.username)")
                    .font(CaleiTypography.h3)
                    .foregroundColor(CaleiColors.dark)
                
                Text("Panel de administración")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Admin Menu Card

struct AdminMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícono
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                Text(subtitle)
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CaleiColors.gray400)
        }
        .padding(16)
        .background(CaleiColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        AdminHomeView(navigateToZones: .constant(false))
            .environmentObject(AppState())
    }
}
