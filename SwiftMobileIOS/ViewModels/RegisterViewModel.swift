import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case success
        case error(String)
    }

    @Published var state: State = .idle
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var termsAccepted = false

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    var isFormValid: Bool {
        isUsernameValid && isEmailValid && isPasswordValid && isConfirmPasswordValid && termsAccepted
    }

    var isUsernameValid: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var isEmailValid: Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    var isPasswordValid: Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasMinLength && hasUppercase && hasNumber
    }

    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && confirmPassword == password
    }

    func register() async -> User? {
        guard isFormValid else {
            state = .error("Revisá los campos y aceptá los términos")
            return nil
        }

        state = .loading
        do {
            let user = try await authService.register(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            state = .success
            return user
        } catch {
            state = .error(error.localizedDescription)
            return nil
        }
    }
}
