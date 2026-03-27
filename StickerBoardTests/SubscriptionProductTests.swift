import Testing
import Foundation
@testable import StickerBoard

struct SubscriptionProductTests {

    @Test func 商品が2種類ある() {
        #expect(SubscriptionProduct.allCases.count == 2)
    }

    @Test func 商品IDが正しいフォーマット() {
        #expect(SubscriptionProduct.monthlyPro.rawValue == "com.solodev.StickerBoard.pro.monthly")
        #expect(SubscriptionProduct.yearlyPro.rawValue == "com.solodev.StickerBoard.pro.yearly")
    }

    @Test func allIdentifiersが全商品IDを含む() {
        let identifiers = SubscriptionProduct.allIdentifiers

        #expect(identifiers.count == 2)
        #expect(identifiers.contains("com.solodev.StickerBoard.pro.monthly"))
        #expect(identifiers.contains("com.solodev.StickerBoard.pro.yearly"))
    }

    @Test func groupIDが正しい() {
        #expect(SubscriptionProduct.groupID == "StickerBoardPro")
    }

    @Test func displayNameが日本語で設定されている() {
        #expect(SubscriptionProduct.monthlyPro.displayName == "月額プラン")
        #expect(SubscriptionProduct.yearlyPro.displayName == "年額プラン")
    }
}
