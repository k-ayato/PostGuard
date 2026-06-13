import SwiftUI

struct SuggestionView: View {
    let originalText: String
    let suggestedText: String
    let onReset: () -> Void

    @State private var copied = false
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            // Ambient gradient
            Circle()
                .fill(Color.pgSafe.opacity(0.05))
                .frame(width: 400)
                .offset(x: -50, y: -300)
                .blur(radius: 80)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Suggested text card
                    suggestedCard
                        .padding(.horizontal, 20)

                    // Actions
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pgAccent.opacity(0.2), Color(hex: "#9B5CFF").opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(Color.pgAccent.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.pgAccent, Color(hex: "#9B5CFF")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .neonGlow(color: .pgAccent, radius: 8)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0.0)

            VStack(spacing: 6) {
                Text("修正提案")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
                Text("リスクを低減しながら、あなたの意図を保った文章を提案します")
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Suggested Card
    private var suggestedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(.pgAccent)
                Text("提案テキスト")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)
                    .tracking(0.5)
                Spacer()
                copyButton
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider()
                .background(Color.pgBorder)

            Text(suggestedText)
                .font(.system(size: 16))
                .foregroundColor(.pgTextPrimary)
                .lineSpacing(6)
                .padding(18)
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.pgAccent.opacity(0.4), Color(hex: "#9B5CFF").opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color.pgAccent.opacity(0.1), radius: 20, y: 8)
    }

    // MARK: - Copy Button
    private var copyButton: some View {
        Button(action: copyText) {
            HStack(spacing: 5) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                Text(copied ? "コピー済み" : "コピー")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(copied ? .pgSafe : .pgAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((copied ? Color.pgSafe : Color.pgAccent).opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke((copied ? Color.pgSafe : Color.pgAccent).opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .animation(.spring(response: 0.3), value: copied)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Post as-is note
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextTertiary)
                Text("投稿するかどうかの最終判断はあなたに委ねられています")
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextTertiary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 4)

            // Use original button
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("分析結果に戻る")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.pgTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.pgSurface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pgBorder, lineWidth: 1))
                )
            }

            // New analysis button
            Button(action: onReset) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("新しい投稿を分析する")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.pgTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.pgSurface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pgBorder, lineWidth: 1))
                )
            }
        }
    }

    // MARK: - Actions
    private func copyText() {
        UIPasteboard.general.string = suggestedText
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
