import SwiftUI

// パスワード再設定の専用フロー。メールログイン画面（EmailAuthView）から push され、
// メールアドレスを入力 → 送信 → 送信完了画面 → 5秒後に自動で元の画面へ戻る。
struct PasswordResetView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case input
        case sent
    }

    @State private var phase: Phase = .input
    @State private var email: String
    @State private var isProcessing = false
    @State private var errorMessage: String?

    // 登録の有無を問わず同一の汎用文言を出す（account enumeration 対策）。
    // userNotFound も成功と同じ扱いにして「そのメールが登録済みか」を漏らさない。
    private static let genericMessage =
        "このメールアドレスが登録されている場合、パスワード再設定メールを送信しました。\n受信箱（迷惑メールフォルダを含む）をご確認ください。"

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            switch phase {
            case .input:
                inputView
            case .sent:
                sentView
            }
        }
        .preferredColorScheme(.dark)
        // .sent になったら5秒後に自動で元の画面へ戻る。画面が消える/フェーズが
        // 変わると .task は自動キャンセルされるため、手動で戻っても二重 pop しない。
        .task(id: phase) {
            guard phase == .sent else { return }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled { dismiss() }
        }
    }

    // MARK: - 入力画面

    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.pgAccent)
                    Text("パスワードの再設定")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                    Text("再設定リンクを送るメールアドレスを入力してください。")
                        .font(.system(size: 13))
                        .foregroundColor(.pgTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text("メールアドレス")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.pgTextSecondary)
                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.pgWarning)
                        .multilineTextAlignment(.center)
                }

                Button {
                    sendReset()
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("再設定メールを送信")
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
            }
            .padding(.horizontal, 24)
        }
    }

    private var canSubmit: Bool {
        email.contains("@") && !isProcessing
    }

    // MARK: - 送信完了画面

    private var sentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.pgSafe)
            Text("送信完了")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pgTextPrimary)
            Text(Self.genericMessage)
                .font(.system(size: 13))
                .foregroundColor(.pgTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Text("5秒後にログイン画面に戻ります。")
                .font(.system(size: 12))
                .foregroundColor(.pgTextTertiary)
                .padding(.top, 4)

            Button {
                dismiss()
            } label: {
                Text("今すぐ戻る")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pgAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pgBorder, lineWidth: 1)
                    )
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 送信処理

    private func sendReset() {
        errorMessage = nil
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                try await auth.sendPasswordReset(email: email)
                phase = .sent
            } catch {
                // 未登録メール（userNotFound）も成功と同一の完了画面に進め、
                // アカウントの存在有無を攻撃者に推測させない。
                if PostGuardError.authMessage(error).code == "PG-AUTH-004" {
                    phase = .sent
                } else {
                    errorMessage = PostGuardError.display(error)
                }
            }
        }
    }
}
