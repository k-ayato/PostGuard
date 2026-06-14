import FirebaseAuth
import Foundation

// Firebase Auth が返す英語のエラーを日本語化し、開発者が報告しやすいよう
// 識別用コード（PG-AUTH-XXX）を併記するためのヘルパ。
// 画面側は display(_:) を呼べば「日本語メッセージ＋コード」を一度に得られる。
enum PostGuardError {

    // エラーを (code, message) のペアに正規化する。
    // - 既存の AuthServiceError（日本語の errorDescription を持つ）はそのまま採用
    // - それ以外は Firebase Auth の NSError として AuthErrorCode で分類
    static func authMessage(_ error: Error) -> (code: String, message: String) {
        // アプリ独自の認証エラー（日本語メッセージ済み）
        if let serviceError = error as? AuthServiceError {
            return ("PG-AUTH-000", serviceError.errorDescription ?? "認証エラーが発生しました。")
        }

        let nsError = error as NSError

        // Firebase Auth 以外のドメインのエラーは未知扱いにする
        guard nsError.domain == AuthErrors.domain else {
            return ("PG-AUTH-999", "認証エラーが発生しました。（コード: \(nsError.code)）")
        }

        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return ("PG-AUTH-001", "このメールアドレスは既に登録されています。")
        case AuthErrorCode.invalidEmail.rawValue:
            return ("PG-AUTH-002", "メールアドレスの形式が正しくありません。")
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return ("PG-AUTH-003", "メールアドレスまたはパスワードが正しくありません。")
        case AuthErrorCode.userNotFound.rawValue:
            return ("PG-AUTH-004", "アカウントが見つかりません。")
        case AuthErrorCode.weakPassword.rawValue:
            return ("PG-AUTH-005", "パスワードは6文字以上で設定してください。")
        case AuthErrorCode.networkError.rawValue:
            return ("PG-AUTH-006", "通信エラーが発生しました。電波の良い場所で再度お試しください。")
        case AuthErrorCode.tooManyRequests.rawValue:
            return ("PG-AUTH-007", "試行回数が多すぎます。しばらくしてから再度お試しください。")
        case AuthErrorCode.userDisabled.rawValue:
            return ("PG-AUTH-008", "このアカウントは無効化されています。")
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return ("PG-AUTH-009", "セキュリティのため再ログインが必要です。")
        default:
            return ("PG-AUTH-999", "認証エラーが発生しました。（コード: \(nsError.code)）")
        }
    }

    // UI 表示用。日本語メッセージとコードを 2 行にまとめて返す。
    static func display(_ error: Error) -> String {
        let result = authMessage(error)
        return "\(result.message)\n(コード: \(result.code))"
    }
}
