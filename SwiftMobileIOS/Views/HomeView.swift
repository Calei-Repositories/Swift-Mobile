import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    
    // Destinos de navegación
    @State private var navigateToTracks = false
    @State private var navigateToProducts = false
    @State private var navigateToDeliveries = false
    @State private var navigateToZones = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CaleiSpacing.space10) {
                    // Logo y título
                    headerSection
                    
                    // Bienvenida
                    welcomeSection
                    
                    // Grid de opciones
                    optionsGrid
                    
                    Spacer(minLength: CaleiSpacing.space10)
                }
                .padding(.horizontal, CaleiSpacing.space6)
                .padding(.top, CaleiSpacing.space10)
            }
            .background(CaleiColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToTracks) {
                TracksListView()
            }
            .navigationDestination(isPresented: $navigateToProducts) {
                ProductSearchView()
            }
            .navigationDestination(isPresented: $navigateToDeliveries) {
                DeliveriesListView()
            }
            .navigationDestination(isPresented: $navigateToZones) {
                ZonesManagementView()
            }
        }
    }
    
    // MARK: - Header con Logo
    
    private var headerSection: some View {
        VStack(spacing: CaleiSpacing.space2) {
            // Logo
            Image("Logotipo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
            
            Text("Sistema de Gestión de Rutas y Puntos de Venta")
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
        }
        .padding(.top, CaleiSpacing.space6)
    }
    
    // MARK: - Bienvenida
    
    private var welcomeSection: some View {
        VStack(spacing: CaleiSpacing.space1) {
            HStack(spacing: 4) {
                Text("Bienvenido,")
                    .font(CaleiTypography.h3)
                    .foregroundColor(CaleiColors.dark)
                
                if let user = appState.currentUser {
                    Text(user.username)
                        .font(CaleiTypography.h3)
                        .foregroundColor(CaleiColors.accent)
                }
            }
            
            Text("Accede a las funcionalidades disponibles:")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CaleiSpacing.space4)
    }
    
    // MARK: - Grid de Opciones
    
    private var optionsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: CaleiSpacing.space4),
            GridItem(.flexible(), spacing: CaleiSpacing.space4)
        ]
        
        return LazyVGrid(columns: columns, spacing: CaleiSpacing.space4) {
            // Gestionar Rutas (para usuarios con acceso a tracks)
            if appState.currentUser?.canAccessTracks == true {
                HomeOptionCard(
                    icon: "map.fill",
                    iconSecondary: "location.fill",
                    title: "Gestionar Rutas",
                    subtitle: "Controla tus recorridos",
                    gradient: CaleiGradients.accent
                ) {
                    navigateToTracks = true
                }
            }
            
            // Visitar Puntos (para usuarios con acceso a productos/ventas)
            if appState.currentUser?.canAccessProducts == true {
                HomeOptionCard(
                    icon: "storefront.fill",
                    iconSecondary: nil,
                    title: "Visitar Puntos",
                    subtitle: "Gestiona ventas",
                    gradient: CaleiGradients.warning
                ) {
                    navigateToProducts = true
                }
            }
            
            // Entregas (para usuarios con acceso a deliveries)
            if appState.currentUser?.canAccessDeliveries == true {
                HomeOptionCard(
                    icon: "shippingbox.fill",
                    iconSecondary: nil,
                    title: "Entregas",
                    subtitle: "Entregar exhibidores",
                    gradient: CaleiGradients.success
                ) {
                    navigateToDeliveries = true
                }
            }
            
            // Gestionar Zonas (solo admin)
            if appState.currentUser?.isAdmin == true {
                HomeOptionCard(
                    icon: "map.fill",
                    iconSecondary: nil,
                    title: "Gestionar Zonas",
                    subtitle: "Configurar territorios",
                    gradient: CaleiGradients.info
                ) {
                    navigateToZones = true
                }
            }
        }
    }
}

// MARK: - Home Option Card

struct HomeOptionCard: View {
    let icon: String
    let iconSecondary: String?
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: CaleiSpacing.space4) {
                // Iconos
                HStack(spacing: -8) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if let secondary = iconSecondary {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: secondary)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Textos
                VStack(spacing: 2) {
                    Text(title)
                        .font(CaleiTypography.h4)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text(subtitle)
                        .font(CaleiTypography.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CaleiSpacing.space10)
            .padding(.horizontal, CaleiSpacing.space4)
            .background(gradient)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Calei Gradients

struct CaleiGradients {
    /// Gradiente principal (accent/teal)
    static let accent = LinearGradient(
        colors: [
            Color(red: 0.310, green: 0.820, blue: 0.773), // #4fd1c5
            Color(red: 0.220, green: 0.698, blue: 0.675)  // #38b2ac
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente success (verde)
    static let success = LinearGradient(
        colors: [
            Color(red: 0.063, green: 0.725, blue: 0.506), // #10b981
            Color(red: 0.047, green: 0.600, blue: 0.420)  // verde más oscuro
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente warning (amarillo/dorado)
    static let warning = LinearGradient(
        colors: [
            Color(red: 0.961, green: 0.620, blue: 0.043), // #f59e0b
            Color(red: 0.850, green: 0.530, blue: 0.020)  // más oscuro
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente info (azul/púrpura)
    static let info = LinearGradient(
        colors: [
            Color(red: 0.549, green: 0.463, blue: 0.973), // púrpura suave
            Color(red: 0.420, green: 0.340, blue: 0.850)  // púrpura más oscuro
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente dark (principal)
    static let dark = LinearGradient(
        colors: [
            Color(red: 0.118, green: 0.145, blue: 0.188), // #1e2530
            Color(red: 0.059, green: 0.090, blue: 0.165)  // #0f172a
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
