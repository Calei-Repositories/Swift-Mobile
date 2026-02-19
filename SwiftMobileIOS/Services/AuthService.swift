import Foundation

final class AuthService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(username: String, password: String) async throws -> User {
        let body = LoginRequest(username: username, password: password)
        let endpoint = Endpoint(path: "/auth/login", method: .post, body: body)
        return try await client.request(endpoint, responseType: User.self)
    }

    func me() async throws -> User {
        let endpoint = Endpoint(path: "/auth/me", method: .get)
        return try await client.request(endpoint, responseType: User.self)
    }

    func logout() async throws {
        let endpoint = Endpoint(path: "/auth/logout", method: .post)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
        SessionCookieStore.shared.clear()
    }

    func register(username: String, email: String, password: String) async throws -> User {
        let body = RegisterRequest(username: username, email: email, password: password)
        let endpoint = Endpoint(path: "/users/register", method: .post, body: body)
        return try await client.request(endpoint, responseType: User.self)
    }

    func listRoles() async throws -> [Role] {
        let endpoint = Endpoint(path: "/roles", method: .get)
        return try await client.request(endpoint, responseType: [Role].self)
    }

    func assignRoles(userId: Int, roleIds: [Int]) async throws {
        let body = AssignRolesRequest(roleIds: roleIds)
        let endpoint = Endpoint(path: "/users/\(userId)/roles", method: .put, body: body)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }
}
