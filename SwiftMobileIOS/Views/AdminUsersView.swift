import SwiftUI

struct AdminUsersView: View {
    @StateObject private var viewModel = AdminUsersViewModel()
    @State private var roleIdText: String = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Role ID", text: $roleIdText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                Button("Cargar") {
                    if let roleId = Int(roleIdText) {
                        Task { await viewModel.loadByRole(roleId: roleId) }
                    }
                }
                Button("Sellers/Deliverers") {
                    Task { await viewModel.loadSellersAndDeliverers() }
                }
            }
            .padding()

            List(viewModel.users) { user in
                VStack(alignment: .leading) {
                    Text(user.username)
                    Text(user.email ?? "-")
                        .foregroundColor(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .navigationTitle("Usuarios")
    }
}
