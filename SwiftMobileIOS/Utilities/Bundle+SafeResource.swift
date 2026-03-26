import Foundation

extension Bundle {
    /// Safe resource URL lookup that logs a friendly message if not found.
    func safeURL(forResource name: String?, withExtension ext: String?) -> URL? {
        guard let name = name else { return nil }
        if let url = self.url(forResource: name, withExtension: ext) {
            return url
        }
        DLog("Resource not found in bundle:", "\(name)\(ext != nil ? ".\(ext!)" : "")")
        return nil
    }
}
