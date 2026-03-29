import Testing
import Foundation
import SwiftData
@testable import StickerBoard

struct BoardTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Board.self, configurations: config)
    }

    // MARK: - 初期化

    @Test func デフォルト値で初期化できる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        #expect(board.title == "テスト")
        #expect(board.placementsData == nil)
        #expect(board.backgroundPatternData == nil)
        #expect(board.placements.isEmpty)
        #expect(board.backgroundPattern == .default)
    }

    // MARK: - placements キャッシュ

    @Test func placementsのsetとgetが往復できる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        let placement = StickerPlacement(
            stickerId: UUID(),
            imageFileName: "test.png",
            positionX: 10,
            positionY: 20,
            scale: 1.5,
            rotation: 45,
            zIndex: 1
        )
        board.placements = [placement]

        let result = board.placements
        #expect(result.count == 1)
        #expect(result[0].imageFileName == "test.png")
        #expect(result[0].positionX == 10)
        #expect(result[0].positionY == 20)
        #expect(result[0].scale == 1.5)
    }

    @Test func placementsの連続アクセスでキャッシュが使われる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        let placements = (0..<10).map { i in
            StickerPlacement(
                stickerId: UUID(),
                imageFileName: "sticker_\(i).png",
                positionX: Double(i * 10),
                positionY: Double(i * 10),
                zIndex: i
            )
        }
        board.placements = placements

        let first = board.placements
        let second = board.placements

        #expect(first.count == 10)
        #expect(second.count == 10)
        #expect(first[0].id == second[0].id)
        #expect(first[9].id == second[9].id)
    }

    @Test func placementsを更新するとキャッシュが正しく更新される() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        let placement1 = StickerPlacement(stickerId: UUID(), imageFileName: "a.png")
        board.placements = [placement1]
        #expect(board.placements.count == 1)
        #expect(board.placements[0].imageFileName == "a.png")

        let placement2 = StickerPlacement(stickerId: UUID(), imageFileName: "b.png")
        board.placements = [placement1, placement2]
        #expect(board.placements.count == 2)
        #expect(board.placements[1].imageFileName == "b.png")
    }

    @Test func placementsを空にリセットできる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        board.placements = [StickerPlacement(stickerId: UUID(), imageFileName: "test.png")]
        #expect(board.placements.count == 1)

        board.placements = []
        #expect(board.placements.isEmpty)
    }

    // MARK: - backgroundPattern キャッシュ

    @Test func backgroundPatternのsetとgetが往復できる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        let config = BackgroundPatternConfig(
            patternType: .dot,
            primaryColorHex: "FFF8F0",
            secondaryColorHex: "E5DDD0"
        )
        board.backgroundPattern = config

        let result = board.backgroundPattern
        #expect(result.patternType == .dot)
        #expect(result.primaryColorHex == "FFF8F0")
        #expect(result.secondaryColorHex == "E5DDD0")
    }

    @Test func backgroundPatternの連続アクセスでキャッシュが使われる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        board.backgroundPattern = BackgroundPatternConfig(
            patternType: .grid,
            primaryColorHex: "FFFFFF",
            secondaryColorHex: "D4E8D4"
        )

        let first = board.backgroundPattern
        let second = board.backgroundPattern

        #expect(first == second)
        #expect(first.patternType == .grid)
    }

    @Test func backgroundPatternを更新するとキャッシュが正しく更新される() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        board.backgroundPattern = BackgroundPatternConfig(
            patternType: .solid,
            primaryColorHex: "FFFFFF",
            secondaryColorHex: "FFFFFF"
        )
        #expect(board.backgroundPattern.patternType == .solid)

        board.backgroundPattern = BackgroundPatternConfig(
            patternType: .stripe,
            primaryColorHex: "FFF0F5",
            secondaryColorHex: "F2A7B0"
        )
        #expect(board.backgroundPattern.patternType == .stripe)
        #expect(board.backgroundPattern.secondaryColorHex == "F2A7B0")
    }

    // MARK: - placementsData 直接変更時のキャッシュ無効化

    @Test func placementsDataを直接変更した場合もキャッシュが無効化される() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let board = Board(title: "テスト")
        context.insert(board)

        let placement = StickerPlacement(stickerId: UUID(), imageFileName: "original.png")
        board.placements = [placement]
        #expect(board.placements[0].imageFileName == "original.png")

        let newPlacement = StickerPlacement(stickerId: UUID(), imageFileName: "replaced.png")
        board.placementsData = try? JSONEncoder().encode([newPlacement])

        #expect(board.placements.count == 1)
        #expect(board.placements[0].imageFileName == "replaced.png")
    }
}
