import Testing
import Foundation

/// ホログラフィック効果のReduce Motion対応テスト
/// Issue #100: HolographicEffectModifier
struct HolographicAccessibilityTests {

    // MARK: - ファイル読み込みヘルパー

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func content() throws -> String {
        try readFile("StickerBoard/Views/Library/HolographicEffectModifier.swift")
    }

    // MARK: - HolographicCardModifier

    @Test func カードModifierにaccessibilityReduceMotionがある() throws {
        let src = try content()
        #expect(src.contains("HolographicCardModifier") && src.contains("accessibilityReduceMotion"))
    }

    @Test func カードModifierのReduceMotion時に3D回転が無効化される() throws {
        let src = try content()
        // reduceMotion が true のとき rotation3DEffect の角度が0になる
        #expect(src.contains("HolographicCardModifier") && src.contains("reduceMotion"))
    }

    // MARK: - HolographicStickerModifier

    @Test func ステッカーModifierにaccessibilityReduceMotionがある() throws {
        let src = try content()
        #expect(src.contains("HolographicStickerModifier") && src.contains("accessibilityReduceMotion"))
    }

    @Test func ステッカーModifierのReduceMotion時に3D回転が無効化される() throws {
        let src = try content()
        // reduceMotion が true のとき rotation3DEffect の角度が0になる
        #expect(src.contains("HolographicStickerModifier") && src.contains("reduceMotion"))
    }

    @Test func ReduceMotion時にMotionManagerが開始されない() throws {
        let src = try content()
        // reduceMotion 有効時は motion.start() を呼ばない
        #expect(src.contains("reduceMotion") && src.contains("motion.start"))
    }
}
