import Testing
import Foundation
@testable import StickerBoard

// MARK: - ローカライズテスト
// Bundle.main はテストターゲット実行時に StickerBoard.app バンドルを参照する

struct LocalizationTests {

    // en.lproj バンドルを直接使うことで言語を確実に英語に固定する
    // （sourceLanguage = ja のため locale: パラメータは言語選択に効かない）
    private var enBundle: Bundle {
        Bundle.main.path(forResource: "en", ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? Bundle.main
    }

    // MARK: - 主要UI文字列の英語翻訳確認

    @Test func スキップが英語でSkipになる() {
        #expect(String(localized: "スキップ", bundle: enBundle) == "Skip")
    }

    @Test func 次へが英語でNextになる() {
        #expect(String(localized: "次へ", bundle: enBundle) == "Next")
    }

    @Test func はじめるが英語でGetStartedになる() {
        #expect(String(localized: "はじめる", bundle: enBundle) == "Get Started")
    }

    @Test func 設定が英語でSettingsになる() {
        #expect(String(localized: "設定", bundle: enBundle) == "Settings")
    }

    @Test func キャンセルが英語でCancelになる() {
        #expect(String(localized: "キャンセル", bundle: enBundle) == "Cancel")
    }

    @Test func 削除が英語でDeleteになる() {
        #expect(String(localized: "削除", bundle: enBundle) == "Delete")
    }

    // MARK: - フィルター displayName

    @Test func オリジナルが英語でOriginalになる() {
        #expect(String(localized: "オリジナル", bundle: enBundle) == "Original")
    }

    @Test func キラキラが英語でSparkleになる() {
        #expect(String(localized: "キラキラ", bundle: enBundle) == "Sparkle")
    }

    @Test func レトロが英語でRetroになる() {
        #expect(String(localized: "レトロ", bundle: enBundle) == "Retro")
    }

    @Test func パステルが英語でPastelになる() {
        #expect(String(localized: "パステル", bundle: enBundle) == "Pastel")
    }

    // MARK: - サブスクリプション displayName

    @Test func 月額プランが英語でMonthlyPlanになる() {
        #expect(String(localized: "月額プラン", bundle: enBundle) == "Monthly Plan")
    }

    @Test func 年額プランが英語でYearlyPlanになる() {
        #expect(String(localized: "年額プラン", bundle: enBundle) == "Yearly Plan")
    }

    // MARK: - 背景パターン displayName

    @Test func 無地が英語でSolidになる() {
        #expect(String(localized: "無地", bundle: enBundle) == "Solid")
    }

    @Test func ドットが英語でDotsになる() {
        #expect(String(localized: "ドット", bundle: enBundle) == "Dots")
    }

    // MARK: - ランタイム非依存チェック（現在のロケールでも動作することを確認）

    @Test func 全フィルターのdisplayNameが空でない() {
        for filter in StickerFilter.allCases {
            #expect(!filter.displayName.isEmpty, "フィルター \(filter.rawValue) の displayName が空")
        }
    }

    @Test func 全枠線幅のdisplayNameが空でない() {
        for width in StickerBorderWidth.allCases {
            #expect(!width.displayName.isEmpty, "枠線幅 \(width.rawValue) の displayName が空")
        }
    }

    @Test func 全背景パターンのdisplayNameが空でない() {
        for pattern in BackgroundPatternType.allCases {
            #expect(!pattern.displayName.isEmpty, "背景パターン \(pattern.rawValue) の displayName が空")
        }
    }

    @Test func 全サブスクリプション商品のdisplayNameが空でない() {
        for product in SubscriptionProduct.allCases {
            #expect(!product.displayName.isEmpty, "商品 \(product.rawValue) の displayName が空")
        }
    }

    @Test func 全Pro特典のtitleとvalueが空でない() {
        for benefit in ProBenefit.allCases {
            #expect(!benefit.title.isEmpty)
            #expect(!benefit.value.isEmpty)
        }
    }
}
