import SwiftUI

struct KeyboardSetupView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Step {
        let number: Int
        let icon: String
        let title: String
        let detail: String
    }

    private let steps: [Step] = [
        Step(number: 1, icon: "gearshape.fill",
             title: "設定アプリを開く",
             detail: "下の「設定を開く」ボタンからPostGuardの設定ページに移動します。"),
        Step(number: 2, icon: "keyboard.fill",
             title: "キーボードを追加",
             detail: "「キーボード」をタップし、「PostGuardKeyboard」をオンにします。"),
        Step(number: 3, icon: "lock.open.fill",
             title: "フルアクセスを許可",
             detail: "「フルアクセスを許可」をオンにします。AI分析のための通信に必要です。"),
        Step(number: 4, icon: "globe",
             title: "SNSアプリで使う",
             detail: "投稿フォームで地球儀キーを長押しして「PostGuardKeyboard」に切り替えると、入力中の文章をその場で分析できます。"),
    ]

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            Circle()
                .fill(Color.pgAccent.opacity(0.08))
                .frame(width: 360, height: 360)
                .offset(x: 130, y: -260)
                .blur(radius: 90)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(steps, id: \.number) { step in
                            stepCard(step)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }

                footerButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pgAccent)
                    .neonGlow(color: .pgAccent, radius: 6)
                Text("キーボードを設定")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
            }
            Text("SNSアプリの投稿フォームから直接リスク分析できるようになります。")
                .font(.system(size: 13))
                .foregroundColor(.pgTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepCard(_ step: Step) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.pgAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: step.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.pgAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("STEP \(step.number)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.pgAccent)
                    Text(step.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                }
                Text(step.detail)
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }

    private var footerButtons: some View {
        VStack(spacing: 12) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .bold))
                    Text("設定を開く")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.pgAccent, Color(hex: "#9B5CFF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.pgAccent.opacity(0.4), radius: 16, y: 6)
            }

            Button {
                dismiss()
            } label: {
                Text("あとで設定する")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pgTextSecondary)
            }
        }
    }
}
