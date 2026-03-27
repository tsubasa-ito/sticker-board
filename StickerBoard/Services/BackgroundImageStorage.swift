import UIKit

/// ボード背景画像の保存・読み込み・削除を管理する
struct BackgroundImageStorage {

    private static var backgroundsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Backgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 背景画像の最大解像度（ボード全体をカバーするため大きめ）
    private static let maxDimension: CGFloat = 2048

    /// 背景画像をJPEGとして保存し、ファイル名を返す
    static func save(_ image: UIImage) throws -> String {
        let resized = image.resized(maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw BackgroundImageStorageError.encodingFailed
        }
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileName
    }

    /// ファイル名から背景画像を読み込む
    static func load(fileName: String) -> UIImage? {
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// 背景画像ファイルを削除する
    static func delete(fileName: String) {
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum BackgroundImageStorageError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "背景画像の保存に失敗しました"
        }
    }
}
