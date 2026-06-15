import SwiftUI

struct ConsentView: View {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @State private var presentedDoc: LegalDocumentView.Kind?

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
                        descriptionCard
                        legalCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }

                footerButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $presentedDoc) { doc in
            NavigationStack {
                LegalDocumentView(kind: doc)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pgAccent)
                    .neonGlow(color: .pgAccent, radius: 6)
                Text("ご利用の前に")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
            }
            Text("PostGuardを安心してお使いいただくために、ご確認ください。")
                .font(.system(size: 13))
                .foregroundColor(.pgTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var descriptionCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.pgAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.pgAccent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("AIによるリスク分析について")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
                Text("本アプリは入力された文章をAI（Google Gemini）に送信してリスク分析を行います。ご利用には利用規約とプライバシーポリシーへの同意が必要です。")
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }

    private var legalCard: some View {
        VStack(spacing: 0) {
            Button { presentedDoc = .terms } label: {
                legalRow(title: "利用規約")
            }
            Divider().background(Color.pgBorder)
            Button { presentedDoc = .privacy } label: {
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

    private var footerButton: some View {
        Button {
            hasAgreedToTerms = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                Text("同意して始める")
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
    }
}
