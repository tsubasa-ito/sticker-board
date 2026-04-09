import Foundation

/// MultipeerConnectivity で送受信するシールデータ
struct ExchangeMessage: Codable {
    let id: UUID
    let senderName: String
    let imageData: Data

    init(senderName: String, imageData: Data) {
        self.id = UUID()
        self.senderName = senderName
        self.imageData = imageData
    }
}

/// 受信済みシールデータ（表示・保存用）
struct ReceivedStickerData: Identifiable {
    let id: UUID
    let senderName: String
    let imageData: Data

    init(senderName: String, imageData: Data) {
        self.id = UUID()
        self.senderName = senderName
        self.imageData = imageData
    }
}
