import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    func login() async -> User? {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await authService.login(username: username, password: password)
            if let me = try? await authService.me() {
                return await resolveRoles(for: me)
            }
            return await resolveRoles(for: user)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func resolveRoles(for user: User) async -> User {
        guard let roles = user.roles, !roles.isEmpty else { return user }
        let hasNames = roles.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !hasNames else { return user }

        do {
            let catalog = try await authService.listRoles()
            let mapped = roles.map { role in
                let roleNumber = role.number ?? role.roleId
                let catalogName = catalog.first(where: { $0.number == roleNumber || $0.roleId == roleNumber })?.name ?? role.name
                return Role(roleId: role.roleId, number: role.number, name: catalogName)
            }
            return User(id: user.id, username: user.username, email: user.email, roles: mapped)
        } catch {
            return user
        }
    }
}
