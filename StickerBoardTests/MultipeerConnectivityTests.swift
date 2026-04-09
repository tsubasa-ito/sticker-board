import Testing
import Foundation
@testable import StickerBoard

struct MultipeerConnectivityTests {

    // MARK: - ExchangeMessage Codable

    @Test func ExchangeMessageをエンコードデコードできる() throws {
        let imageData = Data(repeating: 0xFF, count: 100)
        let message = ExchangeMessage(senderName: "テストユーザー", imageData: imageData)

        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(ExchangeMessage.self, from: encoded)

        #expect(decoded.id == message.id)
        #expect(decoded.senderName == message.senderName)
        #expect(decoded.imageData == message.imageData)
    }

    @Test func ExchangeMessageのIDは毎回異なる() {
        let imageData = Data(repeating: 0xFF, count: 100)
        let message1 = ExchangeMessage(senderName: "Alice", imageData: imageData)
        let message2 = ExchangeMessage(senderName: "Alice", imageData: imageData)

        #expect(message1.id != message2.id)
    }

    @Test func ExchangeMessageの送信者名が正しく保持される() throws {
        let imageData = Data(repeating: 0xAB, count: 50)
        let message = ExchangeMessage(senderName: "太郎のiPhone", imageData: imageData)

        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(ExchangeMessage.self, from: encoded)

        #expect(decoded.senderName == "太郎のiPhone")
    }

    // MARK: - ReceivedStickerData

    @Test func ReceivedStickerDataのIDは毎回異なる() {
        let imageData = Data(repeating: 0x00, count: 50)
        let data1 = ReceivedStickerData(senderName: "Bob", imageData: imageData)
        let data2 = ReceivedStickerData(senderName: "Bob", imageData: imageData)

        #expect(data1.id != data2.id)
    }

    @Test func ReceivedStickerDataのプロパティが正しく設定される() {
        let imageData = Data(repeating: 0xAB, count: 200)
        let received = ReceivedStickerData(senderName: "Carol", imageData: imageData)

        #expect(received.senderName == "Carol")
        #expect(received.imageData == imageData)
    }

    // MARK: - データサイズ検証

    @Test func 制限以下のデータサイズは有効() {
        let limit = MultipeerConnectivityManager.maxImageDataSize
        let validData = Data(repeating: 0xFF, count: limit - 1)

        #expect(MultipeerConnectivityManager.isValidImageData(validData) == true)
    }

    @Test func 制限と同じサイズのデータは有効() {
        let limit = MultipeerConnectivityManager.maxImageDataSize
        let borderData = Data(repeating: 0xFF, count: limit)

        #expect(MultipeerConnectivityManager.isValidImageData(borderData) == true)
    }

    @Test func 制限超過のデータは無効() {
        let limit = MultipeerConnectivityManager.maxImageDataSize
        let oversizedData = Data(repeating: 0xFF, count: limit + 1)

        #expect(MultipeerConnectivityManager.isValidImageData(oversizedData) == false)
    }

    @Test func 空のデータは無効() {
        let emptyData = Data()

        #expect(MultipeerConnectivityManager.isValidImageData(emptyData) == false)
    }

    // MARK: - MultipeerError

    @Test func notConnectedのエラーメッセージが正しい() {
        let error = MultipeerError.notConnected
        #expect(error.errorDescription == "デバイスが接続されていません")
    }

    @Test func invalidDataのエラーメッセージが正しい() {
        let error = MultipeerError.invalidData
        #expect(error.errorDescription == "受信データが無効です")
    }

    // MARK: - サービス定数

    @Test func serviceTypeが正しい() {
        #expect(MultipeerConnectivityManager.serviceType == "stickerboard")
    }

    @Test func maxImageDataSizeが10MBである() {
        #expect(MultipeerConnectivityManager.maxImageDataSize == 10 * 1024 * 1024)
    }
}
