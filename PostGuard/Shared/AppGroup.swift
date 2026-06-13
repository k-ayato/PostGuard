import Foundation

enum AppGroup {
    static let id = "group.com.postguard.app"

    // nil when the App Group is unavailable (e.g. keyboard without Full Access).
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: id)
    }
}
