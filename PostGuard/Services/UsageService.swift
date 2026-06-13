import FirebaseAuth
import FirebaseFirestore
import Foundation

// Monthly usage quota. Firestore (users/{uid}) is the source of truth and is
// only written by the main app; the keyboard increments
// SharedStore.pendingKeyboardCount, which sync() reconciles here.
@MainActor
final class UsageService: ObservableObject {
    static let shared = UsageService()

    @Published private(set) var remaining: Int = SharedStore.freeMonthlyLimit

    private init() {
        refreshFromCache()
    }

    func canAnalyze(isPro: Bool) -> Bool {
        isPro || SharedStore.shared.freeRemaining > 0
    }

    func refreshFromCache() {
        remaining = SharedStore.shared.freeRemaining
    }

    // Records one analysis performed in the main app.
    // NOTE: Firestoreの書き込みawaitはサーバー確定まで返らない（オフラインや
    // DB未作成時は永遠に保留される）ため、UIの完了を書き込みでブロックしない。
    // ローカルキャッシュが即時の真実となり、サーバーへは裏で送る（失敗しても
    // 次回sync()がmax()で整合させる）。
    func recordUsage() {
        bumpLocalCache(by: 1)
        refreshFromCache()
        Task { await pushToFirestore() }
    }

    // Reconciles unsynced keyboard usage and the month rollover with
    // Firestore. Call on launch / foreground / sign-in.
    func sync() async {
        guard FirebaseBootstrap.isConfigured, let uid = Auth.auth().currentUser?.uid else {
            refreshFromCache()
            return
        }
        let store = SharedStore.shared
        let month = SharedStore.currentMonth()
        let docRef = Firestore.firestore().collection("users").document(uid)

        do {
            let snapshot = try await docRef.getDocument()
            let serverMonth = snapshot.get("usageMonth") as? String
            let serverCount = snapshot.get("usageCount") as? Int ?? 0

            let base = serverMonth == month ? serverCount : 0
            let pending = store.pendingKeyboardCount
            let localBase = store.usageMonth == month ? store.usageCount : 0
            // Local cache may be ahead if a previous push failed.
            let merged = max(base, localBase) + pending

            try await docRef.setData([
                "plan": store.isPro ? "pro" : "free",
                "usageMonth": month,
                "usageCount": merged,
                "updatedAt": FieldValue.serverTimestamp(),
                "createdAt": snapshot.exists
                    ? (snapshot.get("createdAt") ?? FieldValue.serverTimestamp())
                    : FieldValue.serverTimestamp(),
            ], merge: true)

            store.usageMonth = month
            store.usageCount = merged
            store.pendingKeyboardCount = 0
        } catch {
            print("[UsageService] sync failed: \(error)")
        }
        refreshFromCache()
    }

    // MARK: - Private

    private func bumpLocalCache(by amount: Int) {
        let store = SharedStore.shared
        let month = SharedStore.currentMonth()
        if store.usageMonth != month {
            store.usageMonth = month
            store.usageCount = 0
        }
        store.usageCount += amount
    }

    private func pushToFirestore() async {
        guard FirebaseBootstrap.isConfigured, let uid = Auth.auth().currentUser?.uid else { return }
        let store = SharedStore.shared
        do {
            try await Firestore.firestore().collection("users").document(uid).setData([
                "plan": store.isPro ? "pro" : "free",
                "usageMonth": store.usageMonth ?? SharedStore.currentMonth(),
                "usageCount": store.usageCount,
                "updatedAt": FieldValue.serverTimestamp(),
            ], merge: true)
        } catch {
            // Cache stays ahead; the next sync() reconciles with max().
            print("[UsageService] push failed: \(error)")
        }
    }
}
