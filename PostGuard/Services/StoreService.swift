import FirebaseAuth
import FirebaseFirestore
import Foundation
import StoreKit

// StoreKit 2 subscription state. StoreKit is the single source of truth for
// entitlement; SharedStore.isPro is a cache for the keyboard extension and
// Firestore's plan field is a display-only mirror.
@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()
    static let monthlyProductID = "com.postguard.app.pro.monthly"

    @Published private(set) var isPro = SharedStore.shared.isPro

    private var updatesTask: Task<Void, Never>?

    private init() {}

    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task { await refreshEntitlements() }
    }

    func refreshEntitlements() async {
        var pro = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.monthlyProductID,
               transaction.revocationDate == nil {
                pro = true
            }
        }
        let changed = pro != isPro
        isPro = pro
        SharedStore.shared.isPro = pro
        if changed {
            // Firestoreの書き込み待ちで購入完了UIをブロックしない（表示用ミラーのため）
            Task { await self.mirrorPlanToFirestore(pro) }
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func mirrorPlanToFirestore(_ pro: Bool) async {
        guard FirebaseBootstrap.isConfigured, let uid = Auth.auth().currentUser?.uid else { return }
        try? await Firestore.firestore().collection("users").document(uid).setData([
            "plan": pro ? "pro" : "free",
            "updatedAt": FieldValue.serverTimestamp(),
        ], merge: true)
    }
}
