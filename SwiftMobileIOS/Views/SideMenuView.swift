import SwiftUI

// MARK: - Side Menu View

struct SideMenuView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool
    @Binding var navigateToZones: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo oscuro
                if isPresented {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isPresented = false
                            }
                        }
                }
                
                // Panel del menú
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header con usuario
                        menuHeader
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Opciones del menú
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                // Gestión de Zonas
                                MenuItemButton(
                                    icon: "hexagon.fill",
                                    title: "Gestión de Zonas",
                                    color: CaleiColors.accent
                                ) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isPresented = false
                                    }
                                    // Cambiar al tab de Admin y navegar a zonas
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedTab = 3 // Tab de Admin
                                        navigateToZones = true
                                    }
                                }
                                
                                Divider()
                                    .padding(.vertical, 12)
                                
                                // Configuración (placeholder)
                                MenuItemButton(
                                    icon: "gearshape.fill",
                                    title: "Configuración",
                                    color: CaleiColors.gray500
                                ) {
                                    // TODO: Navegar a configuración
                                }
                                
                                // Ayuda (placeholder)
                                MenuItemButton(
                                    icon: "questionmark.circle.fill",
                                    title: "Ayuda",
                                    color: CaleiColors.gray500
                                ) {
                                    // TODO: Navegar a ayuda
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                        
                        Divider()
                        
                        // Cerrar sesión
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isPresented = false
                            }
                            Task { await appState.logout() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(CaleiColors.error)
                                
                                Text("Cerrar sesión")
                                    .font(CaleiTypography.body)
                                    .foregroundColor(CaleiColors.error)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.8, 300))
                    .background(CaleiColors.cardBackground)
                    .offset(x: isPresented ? 0 : -min(geometry.size.width * 0.8, 300))
                    
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
    }
    
    // MARK: - Menu Header
    
    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 56, height: 56)
                
                Text(appState.currentUser?.username.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(CaleiColors.accent)
            }
            
            // Nombre de usuario
            Text(appState.currentUser?.username ?? "Usuario")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            // Email o rol
            if let roles = appState.currentUser?.roles, !roles.isEmpty {
                Text(roles.map { $0.name }.joined(separator: ", "))
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
        }
        .padding(20)
        .padding(.top, 8)
    }
}

// MARK: - Menu Item Button

struct MenuItemButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.dark)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CaleiColors.gray400)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SideMenuView(isPresented: .constant(true), navigateToZones: .constant(false), selectedTab: .constant(0))
        .environmentObject(AppState())
}
