import Foundation

final class SessionCookieStore {
    static let shared = SessionCookieStore()

    private let storage = HTTPCookieStorage.shared
    private let defaults = UserDefaults.standard
    private let cookieKey = "sessionId.cookie"

    private init() {
        restoreCookie()
    }

    func saveCookies(from response: HTTPURLResponse, for url: URL) {
        let headers = response.allHeaderFields
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers as? [String: String] ?? [:], for: url)
        guard !cookies.isEmpty else { return }

        cookies.forEach { storage.setCookie($0) }

        if let sessionCookie = cookies.first(where: { $0.name == "sessionId" }) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: sessionCookie, requiringSecureCoding: false) {
                defaults.set(data, forKey: cookieKey)
            }
        }
    }

    func attachCookies(to request: inout URLRequest) {
        guard let url = request.url else { return }
        let cookies = storage.cookies(for: url) ?? []
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    func clear() {
        if let data = defaults.data(forKey: cookieKey) {
            if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) {
                unarchiver.requiresSecureCoding = false
                if let cookie = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? HTTPCookie {
                    storage.deleteCookie(cookie)
                }
            }
        }
        defaults.removeObject(forKey: cookieKey)
    }

    private func restoreCookie() {
        guard let data = defaults.data(forKey: cookieKey) else { return }
        if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) {
            unarchiver.requiresSecureCoding = false
            if let cookie = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? HTTPCookie {
                storage.setCookie(cookie)
            }
        }
    }
}
