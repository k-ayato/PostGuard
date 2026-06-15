import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: StoreService
    @EnvironmentObject private var usage: UsageService
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showPasswordPrompt = false
    @State private var showAppleReauth = false
    @State private var deletePassword = ""
    @State private var deleteNonce: String?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    // TODO: リリース前に実際のホスティングURLへ差し替え
    static let privacyPolicyURL = URL(string: "https://k-ayato.github.io/PostGuard/privacy.html")!
    static let termsURL = URL(string: "https://k-ayato.github.io/PostGuard/terms.html")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pgBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        profileCard
                        planCard
                        if FeatureFlags.paidPlansEnabled {
                            menuCard
                        }
                        legalCard
                        signOutButton
                        deleteButton

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.pgWarning)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("アカウント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.pgTextSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "アカウントを削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) { beginDeletion() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("分析履歴・使用状況などすべてのデータが削除されます。この操作は取り消せません。")
        }
        .alert("本人確認", isPresented: $showPasswordPrompt) {
            SecureField("パスワード", text: $deletePassword)
            Button("削除する", role: .destructive) {
                runDeletion { try await auth.deleteAccount(password: deletePassword) }
            }
            Button("キャンセル", role: .cancel) { deletePassword = "" }
        } message: {
            Text("アカウント削除のため、パスワードを入力してください。")
        }
        .sheet(isPresented: $showAppleReauth) {
            appleReauthSheet
                .presentationDetents([.height(220)])
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
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if !signedIn { dismiss() }
        }
    }

    // MARK: - Cards

    private var profileCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.pgAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text(auth.user?.email ?? auth.user?.displayName ?? "ログイン中")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.pgTextPrimary)
                    .lineLimit(1)
                Text(providerLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("プラン")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: store.isPro ? "crown.fill" : "person")
                    .font(.system(size: 16))
                    .foregroundColor(store.isPro ? .pgCaution : .pgTextSecondary)
                Text(store.isPro ? "PostGuard Pro" : "無料プラン")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
                Spacer()
                if !store.isPro {
                    Text("今月あと \(usage.remaining) 回")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(usage.remaining > 0 ? .pgSafe : .pgWarning)
                }
            }

            if !store.isPro, FeatureFlags.paidPlansEnabled {
                Button {
                    openPlanSelection()
                } label: {
                    Text("プランをアップグレード")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.pgAccent, Color(hex: "#9B5CFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if FeatureFlags.paidPlansEnabled {
                Button {
                    Task { await store.restore() }
                } label: {
                    Text("購入を復元")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.pgTextSecondary)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var menuCard: some View {
        Button {
            openPlanSelection()
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.pgAccent)
                Text("プラン変更")
                    .font(.system(size: 14))
                    .foregroundColor(.pgTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.pgTextTertiary)
            }
            .padding(16)
        }
        .glassCard()
    }

    private func openPlanSelection() {
        dismiss()
        // sheetのdismissが完了してからfullScreenCoverを出す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            router.showPlanSelection = true
        }
    }

    private var legalCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                LegalDocumentView(kind: .terms)
            } label: {
                legalRow(title: "利用規約")
            }
            Divider().background(Color.pgBorder)
            NavigationLink {
                LegalDocumentView(kind: .privacy)
            } label: {
                legalRow(title: "プライバシーポリシー")
            }
        }
        .glassCard()
    }

    private func legalRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.pgTextPrimary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11))
                .foregroundColor(.pgTextTertiary)
        }
        .padding(16)
    }

    private var signOutButton: some View {
        Button {
            do {
                try auth.signOut()
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Text("ログアウト")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pgTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pgBorder, lineWidth: 1)
                )
        }
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text("アカウントを削除")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.pgWarning)
        }
        .padding(.top, 4)
    }

    // MARK: - Deletion flows

    private var providerLabel: String {
        switch auth.primaryProviderID {
        case "apple.com": return "Appleでログイン中"
        case "google.com": return "Googleでログイン中"
        case "password": return "メールアドレスでログイン中"
        default: return "ログイン中"
        }
    }

    private func beginDeletion() {
        let providers = auth.user?.providerData.map(\.providerID) ?? []
        if providers.contains("apple.com") {
            showAppleReauth = true
        } else if providers.contains("password") {
            showPasswordPrompt = true
        } else {
            // Google: re-auth flow is presented by the SDK itself.
            runDeletion { try await auth.deleteAccount() }
        }
    }

    private var appleReauthSheet: some View {
        VStack(spacing: 16) {
            Text("本人確認")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.pgTextPrimary)
            Text("アカウント削除のため、もう一度Appleでサインインしてください。")
                .font(.system(size: 13))
                .foregroundColor(.pgTextSecondary)
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.signIn) { request in
                let nonce = AppleSignInHelper.randomNonce()
                deleteNonce = nonce
                request.requestedScopes = []
                request.nonce = AppleSignInHelper.sha256(nonce)
            } onCompletion: { result in
                showAppleReauth = false
                switch result {
                case .success(let authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                          let nonce = deleteNonce else { return }
                    runDeletion {
                        try await auth.deleteAccount(appleCredential: credential, appleRawNonce: nonce)
                    }
                case .failure:
                    break
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pgSurface)
        .preferredColorScheme(.dark)
    }

    private func runDeletion(_ operation: @escaping () async throws -> Void) {
        errorMessage = nil
        isProcessing = true
        Task {
            defer {
                isProcessing = false
                deletePassword = ""
                deleteNonce = nil
            }
            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
