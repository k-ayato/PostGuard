import Foundation

// App Groups shared storage. Accessible from both the main app and the
// keyboard extension (the latter only when Full Access is granted).
final class SharedStore {
    static let shared = SharedStore()
    private init() {}

    private enum Key {
        static let pendingResult = "pending_result"
        static let history = "analysis_history"
        static let uid = "user_uid"
        static let isPro = "is_pro"
        static let usageMonth = "usage_month"
        static let usageCount = "usage_count"
        static let pendingKeyboardCount = "pending_keyboard_count"
    }

    private let historyLimit = 50
    static let freeMonthlyLimit = 10

    private var defaults: UserDefaults? { AppGroup.defaults }

    // MARK: - User / plan cache (written by the main app, read by the keyboard)

    var uid: String? {
        get { defaults?.string(forKey: Key.uid) }
        set { defaults?.set(newValue, forKey: Key.uid) }
    }

    var isPro: Bool {
        get { defaults?.bool(forKey: Key.isPro) ?? false }
        set { defaults?.set(newValue, forKey: Key.isPro) }
    }

    func clearUserCache() {
        defaults?.removeObject(forKey: Key.uid)
        defaults?.removeObject(forKey: Key.isPro)
        defaults?.removeObject(forKey: Key.usageMonth)
        defaults?.removeObject(forKey: Key.usageCount)
        defaults?.removeObject(forKey: Key.pendingKeyboardCount)
    }

    // MARK: - Usage quota cache

    static func currentMonth(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    var usageMonth: String? {
        get { defaults?.string(forKey: Key.usageMonth) }
        set { defaults?.set(newValue, forKey: Key.usageMonth) }
    }

    var usageCount: Int {
        get { defaults?.integer(forKey: Key.usageCount) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.usageCount) }
    }

    // Analyses performed in the keyboard that have not been written to
    // Firestore yet. The main app reconciles them in UsageService.sync().
    var pendingKeyboardCount: Int {
        get { defaults?.integer(forKey: Key.pendingKeyboardCount) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.pendingKeyboardCount) }
    }

    // Month-aware count including unsynced keyboard usage.
    var effectiveUsageCount: Int {
        let base = usageMonth == Self.currentMonth() ? usageCount : 0
        return base + pendingKeyboardCount
    }

    var freeRemaining: Int {
        max(0, Self.freeMonthlyLimit - effectiveUsageCount)
    }

    // MARK: - Pending result (keyboard → app handoff)

    func savePendingRecord(_ record: AnalysisRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults?.set(data, forKey: Key.pendingResult)
    }

    func consumePendingRecord() -> AnalysisRecord? {
        guard let data = defaults?.data(forKey: Key.pendingResult),
              let record = try? JSONDecoder().decode(AnalysisRecord.self, from: data) else {
            return nil
        }
        defaults?.removeObject(forKey: Key.pendingResult)
        return record
    }

    // MARK: - History

    func history() -> [AnalysisRecord] {
        guard let data = defaults?.data(forKey: Key.history),
              let records = try? JSONDecoder().decode([AnalysisRecord].self, from: data) else {
            return []
        }
        return records
    }

    func appendHistory(_ record: AnalysisRecord) {
        var records = history()
        records.insert(record, at: 0)
        if records.count > historyLimit {
            records = Array(records.prefix(historyLimit))
        }
        saveHistory(records)
    }

    func deleteHistory(id: UUID) {
        saveHistory(history().filter { $0.id != id })
    }

    func clearHistory() {
        defaults?.removeObject(forKey: Key.history)
    }

    private func saveHistory(_ records: [AnalysisRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults?.set(data, forKey: Key.history)
    }
}
