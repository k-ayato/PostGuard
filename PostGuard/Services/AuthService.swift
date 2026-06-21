import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn
import UIKit

enum AuthServiceError: LocalizedError {
    case notConfigured
    case missingToken
    case noPresenter
    case passwordRequired
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "サービスのセットアップが完了していません。"
        case .missingToken: return "認証トークンを取得できませんでした。"
        case .noPresenter: return "画面の表示に失敗しました。"
        case .passwordRequired: return "本人確認のためパスワードを入力してください。"
        case .notSignedIn: return "ログインしていません。"
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var user: FirebaseAuth.User?

    private var listener: AuthStateDidChangeListenerHandle?

    private init() {
        start()
    }

    var isSignedIn: Bool { user != nil }

    // 匿名（ゲスト）ログイン中かどうか。本会員（Apple/Google/メール連携済み）と
    // 区別して、ログイン導線や退会導線の出し分けに使う。
    var isAnonymous: Bool { user?.isAnonymous ?? false }

    // App Store審査 5.1.1(v) 対応: アカウント登録なしでコア機能（分析）を使える
    // よう、未ログイン時は匿名認証でゲスト uid を発行する。利用規約同意後にのみ
    // 呼ぶこと（同意前にユーザーを作らない）。失敗は致命的でないためログのみ。
    func signInAnonymouslyIfNeeded() async {
        guard FirebaseBootstrap.isConfigured, Auth.auth().currentUser == nil else { return }
        do {
            try await Auth.auth().signInAnonymously()
        } catch {
            print("[AuthService] anonymous sign-in failed: \(error)")
        }
    }

    // Safe to call repeatedly; attaches the listener once Firebase is configured.
    func start() {
        guard listener == nil, FirebaseBootstrap.isConfigured else { return }
        // ログインゲートの初回表示が一瞬で正しく分岐するよう、リスナー登録前に同期復元
        user = Auth.auth().currentUser
        SharedStore.shared.uid = user?.uid
        listener = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                self.user = user
                SharedStore.shared.uid = user?.uid
                if user == nil {
                    SharedStore.shared.clearUserCache()
                }
            }
        }
    }

    // MARK: - Google

    func signInWithGoogle() async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthServiceError.notConfigured }
        guard let presenter = Self.topViewController() else { throw AuthServiceError.noPresenter }

        if GIDSignIn.sharedInstance.configuration == nil,
           let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else { throw AuthServiceError.missingToken }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await linkOrSignIn(with: credential)
    }

    // 匿名ユーザーなら credential をリンクして本会員へ昇格し、ゲスト時の uid と
    // 使用回数を引き継ぐ。その credential が既に別アカウントで使われている場合は、
    // そのアカウントへサインインする（リンクは諦める）。匿名でなければ通常サインイン。
    private func linkOrSignIn(with credential: AuthCredential) async throws {
        if let current = Auth.auth().currentUser, current.isAnonymous {
            do {
                try await current.link(with: credential)
                return
            } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                let updated = error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential
                try await Auth.auth().signIn(with: updated ?? credential)
                return
            }
        }
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthServiceError.notConfigured }
        let firebaseCredential = try Self.firebaseCredential(from: credential, rawNonce: rawNonce)
        try await linkOrSignIn(with: firebaseCredential)
    }

    private static func firebaseCredential(
        from credential: ASAuthorizationAppleIDCredential,
        rawNonce: String
    ) throws -> AuthCredential {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthServiceError.missingToken
        }
        return OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )
    }

    // MARK: - Email / password

    func signUp(email: String, password: String) async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthServiceError.notConfigured }
        // 匿名ユーザーならメール資格情報をリンクしてゲストのまま本会員化（uid維持）。
        if let current = Auth.auth().currentUser, current.isAnonymous {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await current.link(with: credential)
        } else {
            try await Auth.auth().createUser(withEmail: email, password: password)
        }
    }

    func signIn(email: String, password: String) async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthServiceError.notConfigured }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthServiceError.notConfigured }
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Sign out / delete

    func signOut() throws {
        try Auth.auth().signOut()
        SharedStore.shared.clearUserCache()
    }

    var primaryProviderID: String? {
        user?.providerData.first?.providerID
    }

    // Account deletion (App Review Guideline 5.1.1(v)). Recent sign-in is
    // required, so each provider re-authenticates first. Apple accounts also
    // revoke the SiwA token (required by Apple).
    //
    // - Apple: pass a fresh ASAuthorizationAppleIDCredential + rawNonce.
    // - Email: pass the account password.
    // - Google: re-runs the Google sign-in flow internally.
    func deleteAccount(
        appleCredential: ASAuthorizationAppleIDCredential? = nil,
        appleRawNonce: String? = nil,
        password: String? = nil
    ) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthServiceError.notSignedIn }
        let providers = user.providerData.map(\.providerID)

        if providers.contains("apple.com") {
            guard let appleCredential, let rawNonce = appleRawNonce else {
                throw AuthServiceError.missingToken
            }
            let credential = try Self.firebaseCredential(from: appleCredential, rawNonce: rawNonce)
            try await user.reauthenticate(with: credential)
            if let codeData = appleCredential.authorizationCode,
               let code = String(data: codeData, encoding: .utf8) {
                try await Auth.auth().revokeToken(withAuthorizationCode: code)
            }
        } else if providers.contains("google.com") {
            guard let presenter = Self.topViewController() else { throw AuthServiceError.noPresenter }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthServiceError.missingToken }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await user.reauthenticate(with: credential)
        } else if providers.contains("password") {
            guard let password, let email = user.email else { throw AuthServiceError.passwordRequired }
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
        }

        // Best effort: remove server-side usage data before the auth record.
        // Firestoreの書き込みawaitはオフライン/DB未作成時に返らないため、
        // 5秒で打ち切って退会フローが固まらないようにする。
        let uid = user.uid
        try? await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await Firestore.firestore().collection("users").document(uid).delete()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            }
            try await group.next()
            group.cancelAll()
        }

        try await user.delete()
        SharedStore.shared.clearUserCache()
    }

    // MARK: - Helpers

    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
