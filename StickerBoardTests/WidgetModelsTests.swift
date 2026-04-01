import Testing
import Foundation
@testable import StickerBoard

struct WidgetModelsTests {

    // MARK: - BoardMetadata エンコード・デコード

    @Test func BoardMetadataをJSONエンコード・デコードできる() throws {
        let id = UUID()
        let date = Date()
        let metadata = BoardMetadata(
            id: id.uuidString,
            title: "テストボード",
            stickerCount: 5,
            updatedAt: date,
            snapshotFileName: "\(id.uuidString).jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BoardMetadata.self, from: data)

        #expect(decoded.id == id.uuidString)
        #expect(decoded.title == "テストボード")
        #expect(decoded.stickerCount == 5)
        #expect(decoded.snapshotFileName == "\(id.uuidString).jpg")
    }

    @Test func BoardMetadata配列をJSONエンコード・デコードできる() throws {
        let metadata1 = BoardMetadata(
            id: UUID().uuidString,
            title: "ボード1",
            stickerCount: 3,
            updatedAt: Date(),
            snapshotFileName: "board1.jpg"
        )
        let metadata2 = BoardMetadata(
            id: UUID().uuidString,
            title: "ボード2",
            stickerCount: 0,
            updatedAt: Date(),
            snapshotFileName: "board2.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode([metadata1, metadata2])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([BoardMetadata].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded[0].title == "ボード1")
        #expect(decoded[1].title == "ボード2")
    }

    @Test func BoardMetadataのstickerCountが0の場合も正しくエンコードされる() throws {
        let metadata = BoardMetadata(
            id: UUID().uuidString,
            title: "空のボード",
            stickerCount: 0,
            updatedAt: Date(),
            snapshotFileName: "empty.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BoardMetadata.self, from: data)

        #expect(decoded.stickerCount == 0)
        #expect(decoded.title == "空のボード")
    }
}
