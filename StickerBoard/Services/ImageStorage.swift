import UIKit
import ImageIO

struct ImageStorage {

    private static var stickersDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Stickers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 保存時の最大解像度（ステッカー用途では1024pxで十分）
    private static let maxSaveDimension: CGFloat = 1024

    /// 切り抜いた画像をPNGとして保存し、ファイル名を返す
    static func save(_ image: UIImage) throws -> String {
        let fileName = UUID().uuidString + ".png"
        let fileURL = stickersDirectory.appendingPathComponent(fileName)

        let trimmed = image.alphaTrimmed()
        let optimized = trimmed.resized(maxDimension: maxSaveDimension)

        guard let data = optimized.pngData() else {
            throw ImageStorageError.encodingFailed
        }

        try data.write(to: fileURL)
        ImageCacheManager.shared.setFullResolution(optimized, for: fileName)
        return fileName
    }

    /// ファイル名からUIImageを読み込む（キャッシュ経由）
    static func load(fileName: String) -> UIImage? {
        ImageCacheManager.shared.fullResolution(for: fileName)
    }

    /// サムネイルを読み込む（キャッシュ経由、指定サイズにリサイズ）
    static func loadThumbnail(fileName: String, size: CGFloat) -> UIImage? {
        ImageCacheManager.shared.thumbnail(for: fileName, size: size)
    }

    /// ディスクから直接読み込む（ImageCacheManager から呼ばれる）
    static func loadFromDisk(fileName: String) -> UIImage? {
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// ImageIO を使ってディスクから直接サムネイルを生成する（フル解像度をメモリに展開しない）
    static func createThumbnailFromDisk(fileName: String, maxPixelSize: CGFloat) -> UIImage? {
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// ファイルを削除する
    static func delete(fileName: String) {
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        ImageCacheManager.shared.removeAll(for: fileName)
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
