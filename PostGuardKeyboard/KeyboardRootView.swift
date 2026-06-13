import SwiftUI

// キーボード拡張のルートビュー。viewModel.phase に応じて
// 未許可 / 未ログイン / 上限 / 入力待ち / 分析中 / 結果 を切り替える。
struct KeyboardRootView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.pgBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.pgAccent)
            Text("PostGuard")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.pgTextPrimary)
            Spacer()
            Button {
                viewModel.cancel()
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.pgTextSecondary)
                    .frame(width: 36, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.pgSurface)
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .needsFullAccess:
            messageView(
                icon: "lock.shield",
                iconColor: .pgCaution,
                title: "フルアクセスが必要です",
                message: "設定 > 一般 > キーボード > PostGuardKeyboard で「フルアクセスを許可」をオンにしてください。"
            )
        case .needsSignIn:
            actionMessageView(
                icon: "person.crop.circle.badge.exclamationmark",
                iconColor: .pgCaution,
                title: "ログインが必要です",
                message: "PostGuardアプリでログインすると、キーボードから分析できるようになります。",
                buttonTitle: "アプリを開いてログイン"
            ) {
                viewModel.openAppForSignIn()
            }
        case .quotaExceeded:
            actionMessageView(
                icon: "gauge.with.needle",
                iconColor: .pgWarning,
                title: "今月の無料分析回数を使い切りました",
                message: "プランをアップグレードすると無制限で分析できます。",
                buttonTitle: "プランを変更"
            ) {
                viewModel.openAppForPaywall()
            }
        case .empty:
            messageView(
                icon: "text.bubble",
                iconColor: .pgTextSecondary,
                title: "投稿文を入力してください。",
                message: "投稿フォームに文章を入力してからこのキーボードに切り替えると、炎上リスクを分析できます。"
            )
        case .ready(let text):
            readyView(text: text)
        case .loading:
            loadingView(
                title: "リスクを分析中…",
                message: "キーボードを閉じずにお待ちください。"
            )
        case .result(let record):
            KeyboardResultView(record: record, viewModel: viewModel)
        case .replacing:
            loadingView(
                title: "修正文を反映中…",
                message: "キーボードを閉じずにお待ちください。"
            )
        case .error(let message):
            errorView(message: message)
        }
    }

    private func readyView(text: String) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("取り込んだ投稿文")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.pgTextSecondary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pgTextPrimary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .glassCard()

            Button {
                viewModel.analyze()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("分析する")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.pgAccent, Color.pgAccent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .neonGlow(color: .pgAccentGlow, radius: 10)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func loadingView(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.pgAccent)
                .scaleEffect(1.3)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.pgTextPrimary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.pgTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func actionMessageView(
        icon: String,
        iconColor: Color,
        title: String,
        message: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.pgTextPrimary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.pgTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pgAccent)
                    )
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func messageView(icon: String, iconColor: Color, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.pgTextPrimary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.pgTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(Color.pgWarning)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.pgTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, 20)
            Button {
                viewModel.retry()
            } label: {
                Text("やり直す")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.pgAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.pgAccent, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
