import Foundation

// 機能フラグ。本体アプリ・キーボード拡張の両方から参照される（Shared）。
//
// v1（無料リリース）では有料プランUIをすべて隠す。App Store審査通過後の
// アップデートで `paidPlansEnabled` を true にすると、プラン選択画面・
// アップグレード導線・ペイウォール・キーボードのアップグレード案内が
// 一括で復活する（コード変更は原則この1行のみ）。
enum FeatureFlags {
    static let paidPlansEnabled = false
}
