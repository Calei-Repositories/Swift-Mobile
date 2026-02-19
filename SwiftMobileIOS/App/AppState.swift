import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    func loadSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await authService.me()
            currentUser = user
        } catch {
            currentUser = nil
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.logout()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
