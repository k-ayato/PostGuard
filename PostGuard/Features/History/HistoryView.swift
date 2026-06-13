import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: AnalysisRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pgBackground.ignoresSafeArea()

                if viewModel.records.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(Color.pgBackground)
            }
            .navigationDestination(item: $selectedRecord) { record in
                AnalysisView(
                    result: record.result,
                    originalText: record.sourceText,
                    onReset: { selectedRecord = nil }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.pgTextSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.pgSurface))
            }

            Text("分析履歴")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.pgTextPrimary)

            Spacer()

            if !viewModel.records.isEmpty {
                Button {
                    viewModel.clearAll()
                } label: {
                    Text("全削除")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pgWarning)
                }
            }
        }
    }

    // MARK: - List

    private var recordList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.records) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        recordRow(record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    private func recordRow(_ record: AnalysisRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: record.riskLevel.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(record.riskLevel.label)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(record.riskLevel.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(record.riskLevel.glowColor))

                Text("スコア \(record.result.overallScore)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pgTextSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: record.origin == .keyboard ? "keyboard" : "iphone")
                        .font(.system(size: 9))
                    Text(record.origin.label)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.pgTextTertiary)

                Button {
                    viewModel.delete(id: record.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.pgTextTertiary)
                        .frame(width: 28, height: 28)
                }
            }

            Text(record.sourceText)
                .font(.system(size: 14))
                .foregroundColor(.pgTextPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11))
                .foregroundColor(.pgTextTertiary)
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundColor(.pgTextTertiary)
            Text("履歴はまだありません")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.pgTextSecondary)
            Text("アプリまたはキーボードで分析すると\nここに記録されます。")
                .font(.system(size: 12))
                .foregroundColor(.pgTextTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [AnalysisRecord] = []

    func reload() {
        records = SharedStore.shared.history()
    }

    func delete(id: UUID) {
        SharedStore.shared.deleteHistory(id: id)
        reload()
    }

    func clearAll() {
        SharedStore.shared.clearHistory()
        reload()
    }
}
