import UIKit

struct ImageStorage {

    private static var stickersDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Stickers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 切り抜いた画像をPNGとして保存し、ファイル名を返す
    static func save(_ image: UIImage) throws -> String {
        let fileName = UUID().uuidString + ".png"
        let fileURL = stickersDirectory.appendingPathComponent(fileName)

        guard let data = image.pngData() else {
            throw ImageStorageError.encodingFailed
        }

        try data.write(to: fileURL)
        return fileName
    }

    /// ファイル名からUIImageを読み込む
    static func load(fileName: String) -> UIImage? {
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// ファイルを削除する
    static func delete(fileName: String) {
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum ImageStorageError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "画像の保存に失敗しました"
        }
    }
}
