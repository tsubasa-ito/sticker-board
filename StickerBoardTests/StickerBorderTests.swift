import Testing
import Foundation
import UIKit
@testable import StickerBoard

struct StickerBorderTests {

    // MARK: - StickerBorderWidth

    @Test func 全枠線太さが4種類ある() {
        #expect(StickerBorderWidth.allCases.count == 4)
    }

    @Test(arguments: [
        (StickerBorderWidth.none, 0.0 as CGFloat),
        (.thin, 0.015),
        (.medium, 0.03),
        (.thick, 0.05),
    ])
    func radiusRatioが正しい(width: StickerBorderWidth, expected: CGFloat) {
        #expect(width.radiusRatio == expected)
    }

    @Test(arguments: [
        (StickerBorderWidth.none, "なし"),
        (.thin, "細"),
        (.medium, "中"),
        (.thick, "太"),
    ])
    func displayNameが正しい(width: StickerBorderWidth, expected: String) {
        #expect(width.displayName == expected)
    }

    @Test func noneのradiusRatioはゼロ() {
        #expect(StickerBorderWidth.none.radiusRatio == 0)
    }

    @Test func 太さの順序が正しい() {
        let ratios = StickerBorderWidth.allCases.map(\.radiusRatio)
        // none < thin < medium < thick の順で増加
        for i in 0..<(ratios.count - 1) {
            #expect(ratios[i] < ratios[i + 1])
        }
    }

    // MARK: - StickerBorderColor

    @Test func プリセットが9色ある() {
        #expect(StickerBorderColor.presets.count == 9)
    }

    @Test func デフォルトカラーはホワイト() {
        let defaultColor = StickerBorderColor.defaultColor
        #expect(defaultColor.id == "white")
        #expect(defaultColor.hex == "FFFFFF")
    }

    @Test func hex値からUIColorが正しく生成される() {
        // 赤
        let red = StickerBorderColor(id: "red", displayName: "レッド", hex: "FF0000")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        red.color.getRed(&r, green: &g, blue: &b, alpha: nil)
        #expect(r == 1.0)
        #expect(g == 0.0)
        #expect(b == 0.0)
    }

    @Test func 不正なhex値はblackにフォールバックする() {
        let invalid = StickerBorderColor(id: "bad", displayName: "不正", hex: "ZZZZZZ")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        invalid.color.getRed(&r, green: &g, blue: &b, alpha: nil)
        #expect(r == 0.0)
        #expect(g == 0.0)
        #expect(b == 0.0)
    }

    @Test func 全プリセットのIDがユニーク() {
        let ids = StickerBorderColor.presets.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
