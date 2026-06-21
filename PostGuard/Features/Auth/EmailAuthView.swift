import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showPasswordReset = false

    private var canSubmit: Bool {
        guard email.contains("@"), password.count >= 6, !isProcessing else { return false }
        if isRegistering {
            return password == confirmPassword
        }
        return true
    }

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(isRegistering ? "アカウントを作成" : "メールアドレスでログイン")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                        .padding(.top, 24)

                    VStack(spacing: 12) {
                        inputField(
                            label: "メールアドレス",
                            placeholder: "mail@example.com"
                        ) {
                            TextField("", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        inputField(
                            label: "パスワード（6文字以上）",
                            placeholder: ""
                        ) {
                            SecureField("", text: $password)
                                .textContentType(isRegistering ? .newPassword : .password)
                        }

                        if isRegistering {
                            inputField(
                                label: "パスワード（確認）",
                                placeholder: ""
                            ) {
                                SecureField("", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }

                            if !confirmPassword.isEmpty, password != confirmPassword {
                                Text("パスワードが一致しません。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.pgWarning)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.pgWarning)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        submit()
                    } label: {
                        Group {
                            if isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Text(isRegistering ? "登録する" : "ログイン")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canSubmit ? Color.pgAccent : Color.pgSurface)
                        )
                    }
                    .disabled(!canSubmit)

                    Button {
                        isRegistering.toggle()
                        confirmPassword = ""
                        errorMessage = nil
                    } label: {
                        Text(isRegistering ? "アカウントをお持ちの方はログイン" : "アカウントをお持ちでない方は登録")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.pgAccent)
                    }

                    if !isRegistering {
                        VStack(spacing: 4) {
                            Button {
                                showPasswordReset = true
                            } label: {
                                Text("パスワードをお忘れですか？")
                                    .font(.system(size: 12))
                                    .foregroundColor(.pgTextSecondary)
                            }
                            Text("メールアドレスを入力して再設定リンクを受け取れます。")
                                .font(.system(size: 11))
                                .foregroundColor(.pgTextTertiary)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $showPasswordReset) {
            PasswordResetView(initialEmail: email)
        }
        // 匿名→本会員（連携/サインイン）が完了したら閉じる。匿名認証では isSignedIn は
        // 常に true のため、本会員化＝isAnonymous が false になった時点で判定する。
        .onChange(of: auth.isAnonymous) { _, anon in
            if !anon { dismiss() }
        }
    }

    private func inputField<Content: View>(
        label: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.pgTextSecondary)
            content()
                .font(.system(size: 16))
                .foregroundColor(.pgTextPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pgBorder, lineWidth: 1)
                        )
                )
        }
    }

    private func submit() {
        errorMessage = nil
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                if isRegistering {
                    try await auth.signUp(email: email, password: password)
                } else {
                    try await auth.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = PostGuardError.display(error)
            }
        }
    }
}
