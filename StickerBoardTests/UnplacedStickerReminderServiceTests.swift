import Testing
import Foundation
import SwiftData
@testable import StickerBoard

struct UnplacedStickerReminderServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Sticker.self, Board.self, configurations: config)
    }

    private func makeStickerWith(fileName: String, in context: ModelContext) -> Sticker {
        let sticker = Sticker(imageFileName: fileName)
        context.insert(sticker)
        return sticker
    }

    private func makeBoardWith(placements: [String], in context: ModelContext) -> Board {
        let board = Board(title: "テスト")
        context.insert(board)
        board.placements = placements.map { fileName in
            StickerPlacement(
                stickerId: UUID(),
                imageFileName: fileName,
                positionX: 0,
                positionY: 0,
                scale: 1,
                rotation: 0,
                zIndex: 0
            )
        }
        return board
    }

    // MARK: - detectUnplaced

    @Test func シールが全てボードに配置済みなら未配置は空() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let sticker = makeStickerWith(fileName: "sticker1.png", in: context)
        let _ = makeBoardWith(placements: [sticker.imageFileName], in: context)

        let stickers = [sticker]
        let boards = (try? context.fetch(FetchDescriptor<Board>())) ?? []

        let unplaced = service.detectUnplaced(stickers: stickers, boards: boards)
        #expect(unplaced.isEmpty)
    }

    @Test func ボードに配置されていないシールが未配置として検出される() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let placed = makeStickerWith(fileName: "placed.png", in: context)
        let unplacedSticker = makeStickerWith(fileName: "unplaced.png", in: context)
        let _ = makeBoardWith(placements: [placed.imageFileName], in: context)

        let stickers = [placed, unplacedSticker]
        let boards = (try? context.fetch(FetchDescriptor<Board>())) ?? []

        let unplaced = service.detectUnplaced(stickers: stickers, boards: boards)
        #expect(unplaced.count == 1)
        #expect(unplaced[0].imageFileName == "unplaced.png")
    }

    @Test func ボードが0件なら全シールが未配置() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let sticker1 = makeStickerWith(fileName: "a.png", in: context)
        let sticker2 = makeStickerWith(fileName: "b.png", in: context)

        let unplaced = service.detectUnplaced(stickers: [sticker1, sticker2], boards: [])
        #expect(unplaced.count == 2)
    }

    @Test func シールが0件なら未配置も空() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let _ = makeBoardWith(placements: [], in: context)

        let unplaced = service.detectUnplaced(stickers: [], boards: [])
        #expect(unplaced.isEmpty)
    }

    @Test func 複数ボードに跨る配置を正しく検出できる() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let s1 = makeStickerWith(fileName: "s1.png", in: context)
        let s2 = makeStickerWith(fileName: "s2.png", in: context)
        let s3 = makeStickerWith(fileName: "s3.png", in: context)

        let _ = makeBoardWith(placements: [s1.imageFileName], in: context)
        let _ = makeBoardWith(placements: [s2.imageFileName], in: context)

        let boards = (try? context.fetch(FetchDescriptor<Board>())) ?? []
        let unplaced = service.detectUnplaced(stickers: [s1, s2, s3], boards: boards)
        #expect(unplaced.count == 1)
        #expect(unplaced[0].imageFileName == "s3.png")
    }

    @Test func 同じシールが複数ボードに配置されていても重複排除される() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let service = UnplacedStickerReminderService.shared

        let s1 = makeStickerWith(fileName: "shared.png", in: context)
        let s2 = makeStickerWith(fileName: "solo.png", in: context)

        let _ = makeBoardWith(placements: [s1.imageFileName], in: context)
        let _ = makeBoardWith(placements: [s1.imageFileName], in: context)

        let boards = (try? context.fetch(FetchDescriptor<Board>())) ?? []
        let unplaced = service.detectUnplaced(stickers: [s1, s2], boards: boards)
        #expect(unplaced.count == 1)
        #expect(unplaced[0].imageFileName == "solo.png")
    }

    // MARK: - isEnabled / setEnabled

    @Test func デフォルト状態でisEnabledはfalse() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let service = UnplacedStickerReminderService.shared

        #expect(service.isEnabled(in: defaults) == false)
    }

    @Test func setEnabledでtrueにするとisEnabledがtrueになる() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let service = UnplacedStickerReminderService.shared

        service.setEnabled(true, in: defaults)
        #expect(service.isEnabled(in: defaults) == true)
    }

    @Test func setEnabledでfalseにするとisEnabledがfalseになる() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let service = UnplacedStickerReminderService.shared

        service.setEnabled(true, in: defaults)
        service.setEnabled(false, in: defaults)
        #expect(service.isEnabled(in: defaults) == false)
    }

    // MARK: - parseStickerId

    @Test func 正しいURLスキームからstickerIdを取得できる() {
        let url = URL(string: "stickerboard://library?stickerId=12345678-1234-1234-1234-123456789012")!
        let id = UnplacedStickerReminderService.parseStickerId(from: url)
        #expect(id == UUID(uuidString: "12345678-1234-1234-1234-123456789012"))
    }

    @Test func stickerIdが無いURLはnilを返す() {
        let url = URL(string: "stickerboard://library")!
        let id = UnplacedStickerReminderService.parseStickerId(from: url)
        #expect(id == nil)
    }

    @Test func 不正なUUID文字列はnilを返す() {
        let url = URL(string: "stickerboard://library?stickerId=invalid-id")!
        let id = UnplacedStickerReminderService.parseStickerId(from: url)
        #expect(id == nil)
    }

    @Test func 異なるスキームはnilを返す() {
        let url = URL(string: "https://example.com/library?stickerId=12345678-1234-1234-1234-123456789012")!
        let id = UnplacedStickerReminderService.parseStickerId(from: url)
        #expect(id == nil)
    }

    @Test func ホストがlibraryでない場合はnilを返す() {
        let url = URL(string: "stickerboard://board?stickerId=12345678-1234-1234-1234-123456789012")!
        let id = UnplacedStickerReminderService.parseStickerId(from: url)
        #expect(id == nil)
    }
}
