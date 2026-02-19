import SwiftUI

struct ProductSearchView: View {
    @StateObject private var viewModel = ProductSearchViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Buscar", text: $viewModel.query)
                        .textFieldStyle(.roundedBorder)
                    Button("Buscar") {
                        Task { await viewModel.search() }
                    }
                }
                .padding()

                List(viewModel.results) { product in
                    VStack(alignment: .leading) {
                        Text(product.description ?? product.code ?? "Producto")
                        Text(product.unitPrice.map { "$\($0)" } ?? "-")
                            .foregroundColor(.secondary)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Productos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Perfil") {
                            // TODO: navegar a perfil
                        }
                        if appState.currentUser?.isAdmin == true {
                            Button("Administrador") {
                                // TODO: navegar a admin
                            }
                        }
                        Button("Cerrar sesión", role: .destructive) {
                            Task { await appState.logout() }
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
    }
}
