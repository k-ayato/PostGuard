import AuthenticationServices
import SwiftUI

// ログインゲート画面。RootViewが未ログイン時のルートとして全画面表示する
// （ログイン必須のため閉じるボタンはない）。サインイン成功はAuthServiceの
// 状態変化をRootViewが検知してホームへ切り替える。
struct LoginView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var currentNonce: String?
    @State private var showEmailAuth = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pgBackground.ignoresSafeArea()

                Circle()
                    .fill(Color.pgAccent.opacity(0.08))
                    .frame(width: 360, height: 360)
                    .offset(x: -120, y: -280)
                    .blur(radius: 90)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.top, 40)

                    if !FirebaseBootstrap.isConfigured {
                        Text("サービスのセットアップが完了していません。\nGoogleService-Info.plist を設定してください。")
                            .font(.system(size: 12))
                            .foregroundColor(.pgCaution)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        appleButton
                        googleButton
                        emailButton
                    }
                    .padding(.horizontal, 24)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.pgWarning)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    Text("ログインすると分析機能が利用できます。\n無料プランでは月\(SharedStore.freeMonthlyLimit)回まで分析できます。")
                        .font(.system(size: 12))
                        .foregroundColor(.pgTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
                .overlay {
                    if isProcessing {
                        ProgressView()
                            .tint(.pgAccent)
                            .scaleEffect(1.4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.pgBackground.opacity(0.6))
                    }
                }
            }
            .navigationDestination(isPresented: $showEmailAuth) {
                EmailAuthView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.pgAccent)
                .neonGlow(color: .pgAccent, radius: 10)
            Text("PostGuardにログイン")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pgTextPrimary)
            Text("投稿前のリスク分析をはじめましょう")
                .font(.system(size: 13))
                .foregroundColor(.pgTextSecondary)
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = AppleSignInHelper.randomNonce()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = AppleSignInHelper.sha256(nonce)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let nonce = currentNonce else {
                    errorMessage = AuthServiceError.missingToken.localizedDescription
                    return
                }
                run { try await auth.signInWithApple(credential: credential, rawNonce: nonce) }
            case .failure(let error):
                if (error as? ASAuthorizationError)?.code != .canceled {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var googleButton: some View {
        Button {
            run { try await auth.signInWithGoogle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 18))
                Text("Googleで続ける")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.pgTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pgBorder, lineWidth: 1)
                    )
            )
        }
    }

    private var emailButton: some View {
        Button {
            showEmailAuth = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                    .font(.system(size: 15))
                Text("メールアドレスで続ける")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.pgTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.pgBorder, lineWidth: 1)
            )
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) {
        errorMessage = nil
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
