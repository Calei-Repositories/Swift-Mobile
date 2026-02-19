import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
}

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let roles: [Role]?

    private enum CodingKeys: String, CodingKey {
        case id, username, email, roles
    }

    init(id: Int, username: String, email: String?, roles: [Role]?) {
        self.id = id
        self.username = username
        self.email = email
        self.roles = roles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)

        if let roleObjects = try? container.decode([Role].self, forKey: .roles) {
            roles = roleObjects
        } else if let roleStrings = try? container.decode([String].self, forKey: .roles) {
            roles = roleStrings.map { Role(roleId: nil, number: nil, name: $0) }
        } else if let roleNumbers = try? container.decode([Int].self, forKey: .roles) {
            roles = roleNumbers.map { Role(roleId: nil, number: $0, name: "") }
        } else {
            roles = nil
        }
    }
}

extension User {
    private var normalizedRoles: [String] {
        roles?.map {
            $0.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
        } ?? []
    }

    private func hasRole(keywords: [String]) -> Bool {
        normalizedRoles.contains { role in
            keywords.contains { role.contains($0) }
        }
    }

    var isAdmin: Bool {
        hasRole(keywords: ["admin", "administrator", "super", "owner", "root"])
    }

    var isSeller: Bool {
        hasRole(keywords: ["seller", "sales", "vendedor", "venta", "preventa", "preventista", "dealer", "distribuidor", "stock", "inventario"])
    }

    var isDeliverer: Bool {
        hasRole(keywords: ["deliverer", "delivery", "repartidor", "reparto", "driver", "cadete", "logistica", "logistics", "entregador"])
    }

    var canAccessProducts: Bool {
        isSeller || isAdmin
    }

    var canAccessDeliveries: Bool {
        isDeliverer || isAdmin
    }

    var canAccessTracks: Bool {
        isSeller || isAdmin
    }
}

struct Role: Codable, Identifiable {
    let roleId: Int?
    let number: Int?
    let name: String

    var id: Int { roleId ?? number ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case roleId = "id"
        case number
        case name
        case role
        case rol
        case roleName
    }

    init(roleId: Int?, number: Int?, name: String) {
        self.roleId = roleId
        self.number = number
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roleId = try container.decodeIfPresent(Int.self, forKey: .roleId)
        number = try container.decodeIfPresent(Int.self, forKey: .number)

        if let nameValue = try container.decodeIfPresent(String.self, forKey: .name) {
            name = nameValue
        } else if let roleValue = try container.decodeIfPresent(String.self, forKey: .role) {
            name = roleValue
        } else if let rolValue = try container.decodeIfPresent(String.self, forKey: .rol) {
            name = rolValue
        } else if let roleNameValue = try container.decodeIfPresent(String.self, forKey: .roleName) {
            name = roleNameValue
        } else {
            name = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(roleId, forKey: .roleId)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encode(name, forKey: .name)
    }
}

struct AssignRolesRequest: Encodable {
    let roleIds: [Int]
}
