import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Encodable?

    init(path: String,
         method: HTTPMethod,
         queryItems: [URLQueryItem] = [],
         headers: [String: String] = [:],
         body: Encodable? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }

    var url: URL? {
        var components = URLComponents(url: AppConfig.baseURL, resolvingAgainstBaseURL: false)
        components?.path = path
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}
