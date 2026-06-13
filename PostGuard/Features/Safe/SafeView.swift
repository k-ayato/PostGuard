import SwiftUI

struct SafeView: View {
    let onReset: () -> Void
    @State private var appeared = false
    @State private var particleOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            // Safe green ambient glow
            Circle()
                .fill(Color.pgSafe.opacity(0.08))
                .frame(width: 500)
                .blur(radius: 80)
                .offset(y: -100)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: particleOffset)

            VStack(spacing: 0) {
                Spacer()

                // Main icon
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.pgSafe.opacity(0.1 - Double(i) * 0.03), lineWidth: 1)
                            .frame(width: CGFloat(120 + i * 50), height: CGFloat(120 + i * 50))
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6).delay(Double(i) * 0.1),
                                value: appeared
                            )
                    }

                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pgSafe.opacity(0.25), Color.pgSafe.opacity(0.05)],
                                center: .center, startRadius: 0, endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(Circle().stroke(Color.pgSafe.opacity(0.5), lineWidth: 2))
                        .scaleEffect(appeared ? 1 : 0.3)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)

                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pgSafe, Color(hex: "#00F5A0")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .neonGlow(color: .pgSafe, radius: 16)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: appeared)
                }
                .padding(.bottom, 36)

                // Text
                VStack(spacing: 12) {
                    Text("問題なし")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                    Text("この投稿文にリスクは検出されませんでした")
                        .font(.system(size: 16))
                        .foregroundColor(.pgTextSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(.spring(response: 0.5).delay(0.4), value: appeared)

                    // Score badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.pgSafe)
                        Text("リスクスコア 30点以下")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pgSafe)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.pgSafe.opacity(0.1))
                            .overlay(Capsule().stroke(Color.pgSafe.opacity(0.3), lineWidth: 1))
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5).delay(0.5), value: appeared)
                }

                Spacer()

                // New analysis button
                Button(action: onReset) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("新しい投稿を分析する")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color.pgSafe.opacity(0.8), Color(hex: "#00A86B")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.pgSafe.opacity(0.4), radius: 20, y: 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.5).delay(0.6), value: appeared)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                particleOffset = 10
            }
        }
    }
}
