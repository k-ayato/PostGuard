import SwiftUI

struct LoadingView: View {
    /// Set to true when the API call has finished — triggers 88→100% animation then calls onComplete.
    @Binding var isCompleting: Bool
    var onComplete: () -> Void

    // MARK: - Stage definition
    private struct Stage {
        let message: String
        let targetProgress: Double
        let duration: Double  // seconds to reach target from previous stage
    }
    private let stages: [Stage] = [
        Stage(message: "投稿文を解析中...",       targetProgress: 0.18, duration: 1.0),
        Stage(message: "リスクを評価中...",       targetProgress: 0.50, duration: 2.2),
        Stage(message: "ファクトチェック実行中...", targetProgress: 0.76, duration: 2.4),
        Stage(message: "レポートを生成中...",      targetProgress: 0.88, duration: 1.6),
    ]

    // MARK: - State
    @State private var progress: Double = 0
    @State private var stageIndex: Int = 0
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var finishing: Bool = false

    private let stageTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.pgBackground.opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 28) {
                    spinnerView
                    progressSection
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 36)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.pgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.pgBorder, lineWidth: 1)
                        )
                )
                .shadow(color: Color.pgAccent.opacity(0.08), radius: 40, y: 12)
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear {
            startSpinnerAnimations()
            advanceToStage(0)
        }
        .onChange(of: isCompleting) { completing in
            if completing { finishProgress() }
        }
        .onReceive(stageTimer) { _ in
            advanceStageIfNeeded()
        }
    }

    // MARK: - Spinner
    private var spinnerView: some View {
        ZStack {
            Circle()
                .stroke(Color.pgAccent.opacity(0.12), lineWidth: 1)
                .frame(width: 88, height: 88)
                .scaleEffect(pulseScale)
                .opacity(2.0 - pulseScale)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [Color.pgAccent, Color.pgAccent.opacity(0)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(rotation))

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.pgAccent)
                .neonGlow(color: .pgAccent, radius: 5)
        }
    }

    // MARK: - Progress section
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Stage message
            Text(stages[min(stageIndex, stages.count - 1)].message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.pgTextPrimary)
                .id(stageIndex)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.35), value: stageIndex)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color.pgBorder)
                            .frame(height: 6)

                        // Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pgAccent.opacity(0.7), Color.pgAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 6)
                            .shadow(color: Color.pgAccent.opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 6)

                // Percentage + stage indicator
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.pgAccent)

                    Spacer()

                    // Stage dots
                    HStack(spacing: 5) {
                        ForEach(0..<stages.count, id: \.self) { i in
                            Capsule()
                                .fill(i <= stageIndex ? Color.pgAccent : Color.pgBorder)
                                .frame(width: i <= stageIndex ? 14 : 6, height: 4)
                                .animation(.spring(response: 0.3), value: stageIndex)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logic
    private func startSpinnerAnimations() {
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.35
        }
    }

    private func advanceToStage(_ index: Int) {
        guard index < stages.count else { return }
        stageIndex = index
        let stage = stages[index]
        withAnimation(.easeInOut(duration: stage.duration)) {
            progress = stage.targetProgress
        }
    }

    private func advanceStageIfNeeded() {
        guard !finishing else { return }
        let stage = stages[min(stageIndex, stages.count - 1)]
        // Move to next stage when current animation is nearly done
        if progress >= stage.targetProgress - 0.005 && stageIndex < stages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                stageIndex += 1
            }
            let next = stages[stageIndex]
            withAnimation(.easeInOut(duration: next.duration)) {
                progress = next.targetProgress
            }
        }
    }

    private func finishProgress() {
        finishing = true
        withAnimation(.easeOut(duration: 0.5)) {
            stageIndex = stages.count - 1
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            onComplete()
        }
    }
}
