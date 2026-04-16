import Foundation
import SwiftData

/// 手帳モデル。複数のボード（ページ）をグループ化する。
@Model
final class Notebook {
    var id: UUID
    var title: String
    var createdAt: Date
    /// この手帳の表紙として使うBoardのUUID文字列
    var coverBoardId: String

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.coverBoardId = ""
    }
}
