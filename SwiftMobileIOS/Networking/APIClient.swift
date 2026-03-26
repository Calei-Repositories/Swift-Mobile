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
        // Ensure default key strategies (explicit) to avoid accidental snake_case conversion
        decoder.keyDecodingStrategy = .useDefaultKeys
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.decoder = decoder
        self.encoder = encoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        var request = try buildRequest(from: endpoint)
        cookieStore.attachCookies(to: &request)
        // Debug: log request details (URL, method, headers, body if present)
        if let url = request.url {
            DLog("➡️ Request:", request.httpMethod ?? "-", url.absoluteString)
            // Explicit prints for debug visibility in console
            print("➡️ Request")
            print("Method: \(request.httpMethod ?? "-")")
            print("URL: \(url.absoluteString)")
        }
        if let headers = request.allHTTPHeaderFields {
            DLog("➡️ Request headers:", headers)
            print("➡️ Request headers:")
            print(headers)
        }
        if let body = request.httpBody {
            if let bodyStr = String(data: body, encoding: .utf8) {
                DLog("➡️ Request body:", String(bodyStr.prefix(2000)))
                print("➡️ Request body:")
                print(bodyStr)
            } else {
                DLog("➡️ Request body: (binary / not utf8)")
                print("➡️ Request body:")
                print("<binary or non-utf8 body>")
            }
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

            cookieStore.saveCookies(from: http, for: request.url!)

            // Debug: log response status + body (if readable)
            DLog("⬅️ Response HTTP status:", http.statusCode)
            // Explicit prints for debug visibility in console
            print("⬅️ Response HTTP status:")
            print(http.statusCode)
            if let jsonString = String(data: data, encoding: .utf8) {
                DLog("⬅️ Response body:", String(jsonString.prefix(4000)))
                print("⬅️ Response body:")
                print(jsonString)
            } else {
                DLog("⬅️ Response body: (binary / not utf8)")
                print("⬅️ Response body:")
                print("<binary or non-utf8 body>")
            }

            if http.statusCode == 401 {
                throw APIError.notAuthenticated
            }

            guard (200...299).contains(http.statusCode) else {
                let bodyString = String(data: data, encoding: .utf8) ?? ""
                if !bodyString.isEmpty {
                    DLog("⚠️ API HTTP error:", http.statusCode)
                    DLog(String(bodyString.prefix(4000)))
                } else {
                    DLog("⚠️ API HTTP error:", http.statusCode, "(no readable body)")
                }

                // Include server body in the thrown error so callers can display it
                let userInfo: [String: Any] = [NSLocalizedDescriptionKey: bodyString.isEmpty ? "Error HTTP: \(http.statusCode)" : bodyString]
                let err = NSError(domain: "APIClient", code: http.statusCode, userInfo: userInfo)
                throw APIError.other(err)
            }

            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                // DEBUG: Mostrar el JSON que falló al decodificar
                if let jsonString = String(data: data, encoding: .utf8) {
                    DLog("❌ JSON que falló al decodificar para", String(describing: T.self))
                    DLog(String(jsonString.prefix(2000)))
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
