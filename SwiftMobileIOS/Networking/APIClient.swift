import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let cookieStore: SessionCookieStore
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared,
         cookieStore: SessionCookieStore = .shared,
         decoder: JSONDecoder = JSONDecoder(),
         encoder: JSONEncoder = JSONEncoder()) {
        self.session = session
        self.cookieStore = cookieStore
        self.decoder = decoder
        self.encoder = encoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        var request = try buildRequest(from: endpoint)
        cookieStore.attachCookies(to: &request)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

            cookieStore.saveCookies(from: http, for: request.url!)

            if http.statusCode == 401 {
                throw APIError.notAuthenticated
            }

            guard (200...299).contains(http.statusCode) else {
                throw APIError.httpStatus(http.statusCode)
            }

            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                // DEBUG: Mostrar el JSON que falló al decodificar
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ JSON que falló al decodificar para \(T.self):")
                    print(jsonString.prefix(2000))
                }
                throw APIError.decoding(error)
            }
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.other(error)
        }
    }

    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard let url = endpoint.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw APIError.encoding(error)
            }
        }

        return request
    }
}

struct EmptyResponse: Decodable {}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
