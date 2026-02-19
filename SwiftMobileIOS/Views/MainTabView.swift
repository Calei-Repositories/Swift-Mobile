import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSideMenu = false
    @State private var navigateToZones = false
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
                            }
                            .tabItem {
                                Label("Admin", systemImage: "person.badge.key")
                            }
                            .tag(3)
                        }
                    }
                    
                    // Side Menu Overlay
                    SideMenuView(isPresented: $showSideMenu, navigateToZones: $navigateToZones, selectedTab: $selectedTab)
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
