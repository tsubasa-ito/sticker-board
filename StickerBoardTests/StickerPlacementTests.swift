import Testing
import Foundation
@testable import StickerBoard

struct StickerPlacementTests {

    // MARK: - 初期化

    @Test func デフォルト値で初期化できる() {
        let placement = StickerPlacement(
            stickerId: UUID(),
            imageFileName: "test.png"
        )

        #expect(placement.positionX == 0)
        #expect(placement.positionY == 0)
        #expect(placement.scale == 1.0)
        #expect(placement.rotation == 0)
        #expect(placement.zIndex == 0)
        #expect(placement.filter == .original)
        #expect(placement.borderWidth == .none)
        #expect(placement.borderColorHex == "FFFFFF")
    }

    @Test func カスタム値で初期化できる() {
        let stickerId = UUID()
        let placement = StickerPlacement(
            stickerId: stickerId,
            imageFileName: "sticker.png",
            positionX: 100,
            positionY: 200,
            scale: 1.5,
            rotation: 45,
            zIndex: 3,
            filterType: .sparkle,
            borderWidth: .thick,
            borderColorHex: "FF0000"
        )

        #expect(placement.stickerId == stickerId)
        #expect(placement.imageFileName == "sticker.png")
        #expect(placement.positionX == 100)
        #expect(placement.positionY == 200)
        #expect(placement.scale == 1.5)
        #expect(placement.rotation == 45)
        #expect(placement.zIndex == 3)
        #expect(placement.filter == .sparkle)
        #expect(placement.borderWidth == .thick)
        #expect(placement.borderColorHex == "FF0000")
    }

    // MARK: - Computed properties

    @Test func filterのgetとsetが正しく動作する() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")

        placement.filter = .retro
        #expect(placement.filterType == "retro")
        #expect(placement.filter == .retro)
    }

    @Test func borderWidthのgetとsetが正しく動作する() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")

        placement.borderWidth = .medium
        #expect(placement.borderWidthType == "medium")
        #expect(placement.borderWidth == .medium)
    }

    @Test func hasBorderが枠線の有無を正しく返す() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")

        #expect(placement.hasBorder == false)

        placement.borderWidth = .thin
        #expect(placement.hasBorder == true)

        placement.borderWidth = .none
        #expect(placement.hasBorder == false)
    }

    // MARK: - Codable

    @Test func JSONエンコードとデコードが往復できる() throws {
        let original = StickerPlacement(
            stickerId: UUID(),
            imageFileName: "round_trip.png",
            positionX: 50,
            positionY: 75,
            scale: 2.0,
            rotation: 90,
            zIndex: 5,
            filterType: .neon,
            borderWidth: .medium,
            borderColorHex: "00FF00"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StickerPlacement.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.stickerId == original.stickerId)
        #expect(decoded.imageFileName == original.imageFileName)
        #expect(decoded.positionX == original.positionX)
        #expect(decoded.positionY == original.positionY)
        #expect(decoded.scale == original.scale)
        #expect(decoded.rotation == original.rotation)
        #expect(decoded.zIndex == original.zIndex)
        #expect(decoded.filter == original.filter)
        #expect(decoded.borderWidth == original.borderWidth)
        #expect(decoded.borderColorHex == original.borderColorHex)
    }

    @Test func 旧フォーマットJSONからフォールバック値でデコードできる() throws {
        // filterType, borderWidthType, borderColorHex が含まれない旧フォーマット
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "stickerId": "22222222-2222-2222-2222-222222222222",
            "imageFileName": "old_format.png",
            "positionX": 10,
            "positionY": 20,
            "scale": 1.0,
            "rotation": 0,
            "zIndex": 0
        }
        """

        let decoded = try JSONDecoder().decode(StickerPlacement.self, from: Data(json.utf8))

        #expect(decoded.filter == .original)
        #expect(decoded.borderWidth == .none)
        #expect(decoded.borderColorHex == "FFFFFF")
    }

    @Test func 不正なfilterType文字列はoriginalにフォールバックする() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")
        placement.filterType = "invalid_filter"

        #expect(placement.filter == .original)
    }

    @Test func 不正なborderWidthType文字列はnoneにフォールバックする() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")
        placement.borderWidthType = "invalid_width"

        #expect(placement.borderWidth == .none)
    }

    // MARK: - ロック機能

    @Test func デフォルトでisLockedはfalse() {
        let placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")
        #expect(placement.isLocked == false)
    }

    @Test func isLockedをtrueに設定できる() {
        var placement = StickerPlacement(stickerId: UUID(), imageFileName: "test.png")
        placement.isLocked = true
        #expect(placement.isLocked == true)
    }

    @Test func isLockedがJSONエンコードデコードで往復できる() throws {
        var original = StickerPlacement(stickerId: UUID(), imageFileName: "lock_test.png")
        original.isLocked = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StickerPlacement.self, from: data)

        #expect(decoded.isLocked == true)
    }

    @Test func isLockedを含まない旧JSONはfalseにフォールバックする() throws {
        let json = """
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "stickerId": "44444444-4444-4444-4444-444444444444",
            "imageFileName": "old.png",
            "positionX": 0,
            "positionY": 0,
            "scale": 1.0,
            "rotation": 0,
            "zIndex": 0
        }
        """

        let decoded = try JSONDecoder().decode(StickerPlacement.self, from: Data(json.utf8))
        #expect(decoded.isLocked == false)
    }
}
