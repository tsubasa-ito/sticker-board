import Foundation

/// サブスクリプション商品の定義
enum SubscriptionProduct: String, CaseIterable {
    case monthlyPro = "com.tebasaki.StickerBoard.pro.monthly"
    case yearlyPro = "com.tebasaki.StickerBoard.pro.yearly"

    static let allIdentifiers: Set<String> = Set(allCases.map(\.rawValue))

    static let groupID = "StickerBoardPro"

    var displayName: String {
        switch self {
        case .monthlyPro: "月額プラン"
        case .yearlyPro: "年額プラン"
        }
    }
}
