import Foundation
import os

/// Lightweight debug logger. Compiles out in Release builds for `print`,
/// but also emits to the unified logging system so logs can be observed
/// in Console.app or when Xcode isn't showing the debug area.
public func DLog(_ items: Any...) {
    let message = items.map { "\($0)" }.joined(separator: " ")
    #if DEBUG
    print("[D] " + message)
    #endif

    if #available(iOS 14.0, *) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SwiftMobileIOS", category: "debug")
        logger.log(level: .debug, "%{public}", message)
    } else {
        os_log("%{public}@", log: OSLog.default, type: .debug, message)
    }
}
