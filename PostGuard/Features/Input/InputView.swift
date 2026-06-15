import SwiftUI

struct InputView: View {
    @StateObject private var viewModel = InputViewModel()
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var usage: UsageService
    @EnvironmentObject private var store: StoreService
    @State private var showQuotaPrompt = false
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
                // テキスト枠以外をタップしたらキーボードを閉じる（#2）
                .contentShape(Rectangle())
                .onTapGesture { isEditorFocused = false }

            // Ambient glow background
            GeometryReader { geo in
                Circle()
                    .fill(Color.pgAccent.opacity(0.06))
                    .frame(width: geo.size.width * 1.2)
                    .offset(x: -geo.size.width * 0.1, y: -100)
                    .blur(radius: 80)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        // Text editor card
                        textEditorCard
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        // Character count bar
                        characterCountBar
                            .padding(.horizontal, 20)

                        // Tips
                        tipsCard
                            .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                }
                // スクロール開始でキーボードを閉じる（#2）
                .scrollDismissesKeyboard(.immediately)

                // Analyze button
                analyzeButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .navigationDestination(item: $viewModel.analysisResult) { result in
            if result.safe {
                SafeView(onReset: viewModel.reset)
            } else {
                AnalysisView(result: result, onReset: viewModel.reset)
            }
        }
        .overlay {
            if viewModel.isAnalyzing {
                LoadingView(
                    isCompleting: $viewModel.analysisCompleting,
                    onComplete: viewModel.onLoadingFinished
                )
            }
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationBarHidden(true)
        // 分析結果から戻ったタイミングで、無料枠を使い切っていたら催促を表示
        .onChange(of: viewModel.analysisResult) { old, new in
            if old != nil, new == nil, !store.isPro, usage.remaining == 0 {
                showQuotaPrompt = true
            }
        }
        .alert("無料枠を使い切りました", isPresented: $showQuotaPrompt) {
            if FeatureFlags.paidPlansEnabled {
                Button("プランを見る") { router.showPlanSelection = true }
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(FeatureFlags.paidPlansEnabled
                ? "今月の無料分析回数（\(SharedStore.freeMonthlyLimit)回）をすべて使用しました。プランをアップグレードすると無制限で分析できます。"
                : "今月の無料分析回数（\(SharedStore.freeMonthlyLimit)回）をすべて使用しました。毎月1日にリセットされます。")
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.pgAccent)
                        .neonGlow(color: .pgAccent, radius: 6)
                    Text("PostGuard")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                }
                Text("投稿リスク分析ツール")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pgTextSecondary)
                    .tracking(1.5)
            }
            Spacer()
            headerIconButton(systemName: "clock.arrow.circlepath") {
                router.showHistory = true
            }
            headerIconButton(systemName: "keyboard") {
                router.showKeyboardSetup = true
            }
            headerIconButton(systemName: store.isPro ? "person.crop.circle.badge.checkmark" : "person.crop.circle") {
                router.showAccount = true
            }
        }
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.pgTextSecondary)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color.pgSurface)
                        .overlay(Circle().stroke(Color.pgBorder, lineWidth: 1))
                )
        }
    }

    // MARK: - Text Editor Card
    private var textEditorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("投稿文を入力", systemImage: "pencil.and.outline")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)
                    .tracking(0.5)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(Color.pgBorder)

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("今日の出来事、お知らせ、思ったことなど...\n\n投稿する前にリスクをチェックしましょう。")
                        .font(.system(size: 16))
                        .foregroundColor(.pgTextTertiary)
                        .padding(16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.inputText)
                    .font(.system(size: 16))
                    .foregroundColor(.pgTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 160, maxHeight: 260)
                    .padding(12)
                    .scrollDismissesKeyboard(.interactively)
                    .focused($isEditorFocused)
            }
        }
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    viewModel.inputText.isEmpty ? Color.pgBorder : Color.pgAccent.opacity(0.5),
                    lineWidth: viewModel.inputText.isEmpty ? 1 : 1.5
                )
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.inputText.isEmpty)
    }

    // MARK: - Character Count Bar
    private var characterCountBar: some View {
        HStack(spacing: 12) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.pgSurface)
                        .frame(height: 4)
                    Capsule()
                        .fill(characterCountColor)
                        .frame(width: geo.size.width * CGFloat(min(viewModel.inputText.count, 280)) / 280.0, height: 4)
                        .animation(.spring(response: 0.3), value: viewModel.inputText.count)
                }
            }
            .frame(height: 4)

            Text("\(viewModel.inputText.count) / 280")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(characterCountColor)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    private var characterCountColor: Color {
        let count = viewModel.inputText.count
        if count > 280 { return .pgWarning }
        if count > 230 { return .pgCaution }
        return .pgTextSecondary
    }

    // MARK: - Tips
    private var tipsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.pgCaution)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("分析内容")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)

                let tips = ["感情・攻撃性", "差別・ハラスメント", "政治・宗教リスク", "法的リスク", "ブランド整合性", "TPO・文脈", "虚偽情報"]
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.pgAccent.opacity(0.6))
                                .frame(width: 4, height: 4)
                            Text(tip)
                                .font(.system(size: 11))
                                .foregroundColor(.pgTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pgSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pgCaution.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Analyze Button
    private var analyzeButton: some View {
        VStack(spacing: 8) {
            analyzeButtonBody
            if !store.isPro {
                Text("今月あと \(usage.remaining) 回分析できます")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(usage.remaining > 0 ? .pgTextSecondary : .pgWarning)
            }
        }
    }

    // ログインはRootViewのゲートで保証済み。残回数のみ確認する
    private func handleAnalyzeTap() {
        // 分析開始時にキーボードを収納（#1）
        isEditorFocused = false
        guard usage.canAnalyze(isPro: store.isPro) else {
            showQuotaPrompt = true
            return
        }
        viewModel.analyze()
    }

    private var analyzeButtonBody: some View {
        Button(action: handleAnalyzeTap) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 16, weight: .bold))
                Text("リスクを分析する")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if viewModel.canAnalyze {
                        LinearGradient(
                            colors: [Color.pgAccent, Color(hex: "#9B5CFF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.pgSurface
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(viewModel.canAnalyze ? Color.clear : Color.pgBorder, lineWidth: 1)
            )
            .shadow(
                color: viewModel.canAnalyze ? Color.pgAccent.opacity(0.4) : .clear,
                radius: 20, y: 8
            )
        }
        .disabled(!viewModel.canAnalyze)
        .animation(.spring(response: 0.3), value: viewModel.canAnalyze)
    }
}

// MARK: - ViewModel
@MainActor
final class InputViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var isAnalyzing = false
    @Published var analysisCompleting = false   // signals LoadingView to run 88→100%
    @Published var analysisResult: AnalysisResult?
    @Published var showError = false
    @Published var errorMessage = ""

    private var pendingResult: AnalysisResult?  // holds result until loading animation finishes

    var canAnalyze: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && inputText.count <= 280
    }

    func analyze() {
        guard canAnalyze else { return }
        isAnalyzing = true
        analysisCompleting = false
        pendingResult = nil

        Task {
            do {
                let result = try await GeminiService.shared.analyze(text: inputText)
                pendingResult = result
                SharedStore.shared.appendHistory(
                    AnalysisRecord(sourceText: inputText, result: result, origin: .app)
                )
                // Signal LoadingView: finish the bar, then call onLoadingFinished
                analysisCompleting = true
            } catch {
                isAnalyzing = false
                analysisCompleting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Called by LoadingView after the 100% animation completes.
    func onLoadingFinished() {
        isAnalyzing = false
        analysisCompleting = false
        // 無料枠は「結果を実際に表示できたとき」のみ消費する。
        // エラーで出力が得られなかった場合（catch側）はここに到達しない。
        if pendingResult != nil {
            UsageService.shared.recordUsage()
        }
        analysisResult = pendingResult
    }

    func reset() {
        inputText = ""
        analysisResult = nil
        pendingResult = nil
    }
}
