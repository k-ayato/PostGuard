import SwiftUI

// 利用規約・プライバシーポリシーをアプリ内に表示するビュー。
// 外部URL（App Store ConnectのプライバシーポリシーURL欄）とは別に、
// アプリ内でもオフラインで全文を読めるようにして審査時のリンク切れリスクを避ける。
struct LegalDocumentView: View {
    enum Kind: Identifiable {
        case privacy, terms
        var id: String { title }
        var title: String { self == .privacy ? "プライバシーポリシー" : "利用規約" }
        var text: String { self == .privacy ? LegalText.privacyPolicy : LegalText.terms }
    }

    let kind: Kind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            ScrollView(showsIndicators: true) {
                Text(kind.text)
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

enum LegalText {
    static let contactEmail = "kenmei.26.ayato@gmail.com"
    static let operatorName = "綾戸健明"
    static let effectiveDate = "2026年6月15日"

    static let privacyPolicy = """
    PostGuard プライバシーポリシー
    最終更新日: \(effectiveDate)

    \(operatorName)（以下「当方」）は、iOSアプリ「PostGuard」（以下「本アプリ」）における\
    ユーザーの個人情報の取扱いについて、以下のとおりプライバシーポリシーを定めます。

    1. 取得する情報
    ・アカウント情報: ログイン方式に応じたメールアドレス、ユーザー識別子（UID）、表示名（Google／Appleログイン時に提供される範囲）。
    ・利用状況: 月間の分析回数。
    ・入力テキスト: ユーザーが分析のために入力・取り込んだ投稿文。

    2. 入力テキストの取扱い
    入力された文章は、リスク分析のため Google のAI（Gemini／Firebase AI Logic）に送信され処理されます。事実確認のため、文章の一部がGoogle検索に送信される場合があります。分析した投稿文と結果は、ユーザーの端末内（履歴）にのみ保存され、当方のサーバーには保存しません。

    3. 利用目的
    ・本アプリの機能（投稿文のリスク分析・修正提案）の提供。
    ・アカウント管理および利用回数の管理。
    ・不正利用の防止（端末認証 App Check 等）。

    4. 第三者サービス
    本アプリは以下を利用します。各社のプライバシーポリシーが適用されます。
    ・Google Firebase（認証・データベース・AI分析・端末認証）
    ・Apple「Appleでサインイン」（ログインを選択した場合）

    5. 広告・トラッキング
    本アプリは広告を表示せず、トラッキング目的でのデータ収集・第三者提供を行いません。

    6. データの保存期間・削除
    ・アカウント情報・利用状況はアカウント有効期間中保存されます。
    ・アプリ内の「アカウントを削除」により、当方が保持するアカウント情報・利用状況は削除されます。
    ・端末内の履歴は、アプリの削除または履歴削除操作により消去されます。

    7. お子様の利用
    本アプリは13歳未満の利用を想定していません。

    8. 改定
    本ポリシーは必要に応じて改定され、改定後は本アプリまたは当方の公開ページで告知します。

    9. お問い合わせ
    \(contactEmail)
    """

    static let terms = """
    PostGuard 利用規約
    最終更新日: \(effectiveDate)

    本規約は、\(operatorName)（以下「当方」）が提供するアプリ「PostGuard」（以下「本サービス」）の\
    利用条件を定めるものです。ユーザーは本規約に同意の上で本サービスを利用するものとします。

    第1条（サービス内容）
    本サービスは、ユーザーが入力したSNS投稿文等について、AIを用いて炎上リスク等を分析し、参考情報および修正案を提示するものです。

    第2条（AI分析に関する免責）
    1. 分析結果・スコア・修正案はAIによる推定であり、正確性・完全性・特定の結果を保証するものではありません。
    2. 実際に投稿するか否か、その内容についての最終判断と責任はユーザーに帰属します。当方は分析結果に基づくユーザーの投稿等によって生じた損害について責任を負いません。

    第3条（アカウント）
    ユーザーは自己の責任でアカウントを管理するものとし、不正利用について当方は責任を負いません。

    第4条（禁止事項）
    法令・公序良俗に反する利用、本サービスの不正・過度な利用、リバースエンジニアリング等を禁止します。

    第5条（免責・責任の制限）
    本サービスは現状有姿で提供され、当方は事実上または法律上の瑕疵がないことを保証しません。当方の責任は、法令で許容される範囲で制限されます。

    第6条（規約の変更）
    当方は必要に応じて本規約を変更でき、変更後の規約は本サービス上での告知をもって効力を生じます。

    第7条（準拠法・裁判管轄）
    本規約は日本法に準拠し、紛争が生じた場合は当方所在地を管轄する裁判所を専属的合意管轄とします。

    第8条（お問い合わせ）
    \(contactEmail)
    """
}
