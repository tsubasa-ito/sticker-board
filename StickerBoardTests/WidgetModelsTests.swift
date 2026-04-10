import Testing
import Foundation
@testable import StickerBoard

struct WidgetModelsTests {

    // MARK: - SharedBoardMetadata エンコード・デコード

    @Test func SharedBoardMetadataをJSONエンコード・デコードできる() throws {
        let id = UUID()
        let date = Date()
        let metadata = SharedBoardMetadata(
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
        let decoded = try decoder.decode(SharedBoardMetadata.self, from: data)

        #expect(decoded.id == id.uuidString)
        #expect(decoded.title == "テストボード")
        #expect(decoded.stickerCount == 5)
        #expect(decoded.snapshotFileName == "\(id.uuidString).jpg")
    }

    @Test func SharedBoardMetadata配列をJSONエンコード・デコードできる() throws {
        let metadata1 = SharedBoardMetadata(
            id: UUID().uuidString,
            title: "ボード1",
            stickerCount: 3,
            updatedAt: Date(),
            snapshotFileName: "board1.jpg"
        )
        let metadata2 = SharedBoardMetadata(
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
        let decoded = try decoder.decode([SharedBoardMetadata].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded[0].title == "ボード1")
        #expect(decoded[1].title == "ボード2")
    }

    @Test func SharedBoardMetadataのstickerCountが0の場合も正しくエンコードされる() throws {
        let metadata = SharedBoardMetadata(
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
        let decoded = try decoder.decode(SharedBoardMetadata.self, from: data)

        #expect(decoded.stickerCount == 0)
        #expect(decoded.title == "空のボード")
    }

    // MARK: - largeSnapshotFileName

    @Test func largeSnapshotFileNameがエンコード・デコードできる() throws {
        let id = UUID()
        let metadata = SharedBoardMetadata(
            id: id.uuidString,
            title: "テストボード",
            stickerCount: 3,
            updatedAt: Date(),
            snapshotFileName: "\(id.uuidString).jpg",
            largeSnapshotFileName: "\(id.uuidString)_large.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SharedBoardMetadata.self, from: data)

        #expect(decoded.largeSnapshotFileName == "\(id.uuidString)_large.jpg")
    }

    @Test func largeSnapshotFileNameがない古いJSONはnilとしてデコードされる() throws {
        // largeSnapshotFileName を含まない旧フォーマットのJSON
        let oldJSON = """
        {
            "id": "AAAAAAAA-0000-0000-0000-000000000001",
            "title": "古いボード",
            "stickerCount": 2,
            "updatedAt": "2025-01-01T00:00:00Z",
            "snapshotFileName": "AAAAAAAA-0000-0000-0000-000000000001.jpg"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SharedBoardMetadata.self, from: oldJSON)

        #expect(decoded.largeSnapshotFileName == nil)
        #expect(decoded.title == "古いボード")
    }

    @Test func largeSnapshotFileNameがnilの場合はJSONにキーが含まれない() throws {
        let metadata = SharedBoardMetadata(
            id: UUID().uuidString,
            title: "テストボード",
            stickerCount: 1,
            updatedAt: Date(),
            snapshotFileName: "board.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // nil の場合はキーが含まれないこと（decodeIfPresent を使うため）
        #expect(jsonObject?["largeSnapshotFileName"] == nil)
    }
}
