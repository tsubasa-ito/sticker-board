import Testing
import Foundation
@testable import StickerBoard

struct SubscriptionProductTests {

    @Test func 商品が2種類ある() {
        #expect(SubscriptionProduct.allCases.count == 2)
    }

    @Test func 商品IDが正しいフォーマット() {
        #expect(SubscriptionProduct.monthlyPro.rawValue == "com.tebasaki.StickerBoard.pro.monthly")
        #expect(SubscriptionProduct.yearlyPro.rawValue == "com.tebasaki.StickerBoard.pro.yearly")
    }

    @Test func allIdentifiersが全商品IDを含む() {
        let identifiers = SubscriptionProduct.allIdentifiers

        #expect(identifiers.count == 2)
        #expect(identifiers.contains("com.tebasaki.StickerBoard.pro.monthly"))
        #expect(identifiers.contains("com.tebasaki.StickerBoard.pro.yearly"))
    }

    @Test func groupIDが正しい() {
        #expect(SubscriptionProduct.groupID == "StickerBoardPro")
    }

    @Test func displayNameが空でない() {
        for product in SubscriptionProduct.allCases {
            #expect(!product.displayName.isEmpty)
        }
    }
}
