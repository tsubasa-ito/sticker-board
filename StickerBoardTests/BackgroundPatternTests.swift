import Testing
import Foundation
import SwiftUI
@testable import StickerBoard

struct BackgroundPatternTests {

    // MARK: - BackgroundPatternType

    @Test func 全ケースが6種類ある() {
        #expect(BackgroundPatternType.allCases.count == 6)
    }

    @Test func pickerCasesからcustomが除外される() {
        let pickerCases = BackgroundPatternType.pickerCases

        #expect(pickerCases.contains(.custom) == false)
        #expect(pickerCases.count == 5)
    }

    @Test(arguments: [
        (BackgroundPatternType.solid, "無地"),
        (.dot, "ドット"),
        (.grid, "グリッド"),
        (.stripe, "ストライプ"),
        (.gradient, "グラデーション"),
        (.custom, "写真"),
    ])
    func displayNameが正しい(patternType: BackgroundPatternType, expected: String) {
        #expect(patternType.displayName == expected)
    }

    @Test func rawValueからの初期化が正しい() {
        #expect(BackgroundPatternType(rawValue: "solid") == .solid)
        #expect(BackgroundPatternType(rawValue: "dot") == .dot)
        #expect(BackgroundPatternType(rawValue: "unknown") == nil)
    }

    // MARK: - BackgroundPatternConfig

    @Test func デフォルト設定が正しい() {
        let config = BackgroundPatternConfig.default

        #expect(config.patternType == .solid)
        #expect(config.primaryColorHex == "FFFFFF")
        #expect(config.secondaryColorHex == "E5DDD0")
        #expect(config.customImageFileName == nil)
    }

    @Test func プリセットが5種類ある() {
        #expect(BackgroundPatternConfig.presets.count == 5)
    }

    @Test func プリセットのパターン種別が正しい() {
        let types = BackgroundPatternConfig.presets.map(\.patternType)

        #expect(types == [.solid, .dot, .grid, .stripe, .gradient])
    }

    @Test func Codableで往復できる() throws {
        let config = BackgroundPatternConfig(
            patternType: .custom,
            primaryColorHex: "FF0000",
            secondaryColorHex: "00FF00",
            customImageFileName: "bg.jpg",
            customImageCropX: 0.3,
            customImageCropY: 0.7
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(BackgroundPatternConfig.self, from: data)

        #expect(decoded == config)
    }

    @Test func Equatableが正しく動作する() {
        let a = BackgroundPatternConfig(patternType: .solid, primaryColorHex: "FFFFFF", secondaryColorHex: "000000")
        let b = BackgroundPatternConfig(patternType: .solid, primaryColorHex: "FFFFFF", secondaryColorHex: "000000")
        let c = BackgroundPatternConfig(patternType: .dot, primaryColorHex: "FFFFFF", secondaryColorHex: "000000")

        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Color hex 変換

    @Test func hex文字列からColorを生成できる() {
        // 白
        let white = Color(hexString: "FFFFFF")
        #expect(white.toHexString() == "FFFFFF")

        // 黒
        let black = Color(hexString: "000000")
        #expect(black.toHexString() == "000000")
    }

    @Test func ハッシュ記号付きhexも正しくパースできる() {
        let color = Color(hexString: "#FF0000")
        #expect(color.toHexString() == "FF0000")
    }
}
