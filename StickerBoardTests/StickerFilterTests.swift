import Testing
import Foundation
@testable import StickerBoard

struct StickerFilterTests {

    @Test func 全フィルターが7種類ある() {
        #expect(StickerFilter.allCases.count == 7)
    }

    @Test(arguments: [
        (StickerFilter.original, "オリジナル"),
        (.sparkle, "キラキラ"),
        (.retro, "レトロ"),
        (.pastel, "パステル"),
        (.neon, "ネオン"),
        (.puffy, "ぷっくり"),
        (.wappen, "ワッペン"),
    ])
    func displayNameが正しい(filter: StickerFilter, expected: String) {
        #expect(filter.displayName == expected)
    }

    @Test func 全フィルターにiconNameが設定されている() {
        for filter in StickerFilter.allCases {
            #expect(!filter.iconName.isEmpty)
        }
    }

    @Test func rawValueからの初期化が正しい() {
        #expect(StickerFilter(rawValue: "sparkle") == .sparkle)
        #expect(StickerFilter(rawValue: "retro") == .retro)
        #expect(StickerFilter(rawValue: "nonexistent") == nil)
    }

    @Test func idがrawValueと一致する() {
        for filter in StickerFilter.allCases {
            #expect(filter.id == filter.rawValue)
        }
    }

    @Test func Codableで往復できる() throws {
        for filter in StickerFilter.allCases {
            let data = try JSONEncoder().encode(filter)
            let decoded = try JSONDecoder().decode(StickerFilter.self, from: data)
            #expect(decoded == filter)
        }
    }
}
