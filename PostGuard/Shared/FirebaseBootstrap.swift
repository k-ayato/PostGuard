import FirebaseAppCheck
import FirebaseCore
import Foundation

// Shared by both targets. Each target bundles its own GoogleService-Info.plist
// (the keyboard is registered as a separate Firebase app), so Bundle.main
// resolves to the right one. Skips configuration while the plist is still the
// committed placeholder, so the project builds and runs without a Firebase
// project.
enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfAvailable() {
        guard !isConfigured else { return }
        if FirebaseApp.app() != nil {
            isConfigured = true
            return
        }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path),
              isRealConfiguration(options) else {
            return
        }
        AppCheck.setAppCheckProviderFactory(PostGuardAppCheckProviderFactory())
        FirebaseApp.configure(options: options)
        isConfigured = true
    }

    private static func isRealConfiguration(_ options: FirebaseOptions) -> Bool {
        guard let apiKey = options.apiKey, !apiKey.isEmpty, !apiKey.contains("YOUR_") else {
            return false
        }
        // Real Firebase iOS app IDs always start with "1:"; the placeholder uses "0:".
        return options.googleAppID.hasPrefix("1:")
    }
}

// App Attest is unsupported inside app extensions, so the keyboard falls back
// to DeviceCheck. Debug builds use the debug provider (register its token in
// the Firebase console for simulator runs).
final class PostGuardAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        if Bundle.main.bundleURL.pathExtension == "appex" {
            return DeviceCheckProvider(app: app)
        }
        return AppAttestProvider(app: app)
        #endif
    }
}
