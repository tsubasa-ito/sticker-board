import UIKit

final class ImageCacheManager {

    static let shared = ImageCacheManager()

    // MARK: - キャッシュ層

    /// フル解像度画像キャッシュ（上限: 50MB）
    private let fullResolutionCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024
        cache.countLimit = 30
        return cache
    }()

    /// サムネイルキャッシュ（上限: 20MB）- キーは "fileName_WxH" 形式
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 20 * 1024 * 1024
        cache.countLimit = 100
        return cache
    }()

    /// フィルター適用済みキャッシュ（上限: 40MB）- キーは "fileName_filterType" 形式
    private let filteredCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 40 * 1024 * 1024
        cache.countLimit = 30
        return cache
    }()

    // MARK: - 初期化

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(purgeAllCaches),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - フル解像度

    func fullResolution(for fileName: String) -> UIImage? {
        let key = fileName as NSString
        if let cached = fullResolutionCache.object(forKey: key) {
            return cached
        }
        guard let image = ImageStorage.loadFromDisk(fileName: fileName) else { return nil }
        let cost = image.estimatedMemoryCost
        fullResolutionCache.setObject(image, forKey: key, cost: cost)
        return image
    }

    func setFullResolution(_ image: UIImage, for fileName: String) {
        let key = fileName as NSString
        fullResolutionCache.setObject(image, forKey: key, cost: image.estimatedMemoryCost)
    }

    // MARK: - サムネイル

    func thumbnail(for fileName: String, size: CGFloat) -> UIImage? {
        let key = thumbnailKey(fileName: fileName, size: size)
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }
        guard let original = fullResolution(for: fileName) else { return nil }
        let thumbnail = original.resized(maxDimension: size)
        thumbnailCache.setObject(thumbnail, forKey: key, cost: thumbnail.estimatedMemoryCost)
        return thumbnail
    }

    // MARK: - フィルター適用済み

    func filtered(for fileName: String, filter: StickerFilter) -> UIImage? {
        guard filter != .original else { return fullResolution(for: fileName) }
        let key = filteredKey(fileName: fileName, filter: filter)
        if let cached = filteredCache.object(forKey: key) {
            return cached
        }
        guard let original = fullResolution(for: fileName) else { return nil }
        let result = StickerFilterService.apply(filter, to: original)
        filteredCache.setObject(result, forKey: key, cost: result.estimatedMemoryCost)
        return result
    }

    func setFiltered(_ image: UIImage, for fileName: String, filter: StickerFilter) {
        let key = filteredKey(fileName: fileName, filter: filter)
        filteredCache.setObject(image, forKey: key, cost: image.estimatedMemoryCost)
    }

    // MARK: - キャッシュ無効化

    func removeAll(for fileName: String) {
        let key = fileName as NSString
        fullResolutionCache.removeObject(forKey: key)
        for filter in StickerFilter.allCases where filter != .original {
            filteredCache.removeObject(forKey: filteredKey(fileName: fileName, filter: filter))
        }
        // サムネイルはサイズ別で複数あるため一括クリアは行わない（NSCache が LRU で自動管理）
    }

    @objc func purgeAllCaches() {
        fullResolutionCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
        filteredCache.removeAllObjects()
    }

    // MARK: - キー生成

    private func thumbnailKey(fileName: String, size: CGFloat) -> NSString {
        "\(fileName)_\(Int(size))" as NSString
    }

    private func filteredKey(fileName: String, filter: StickerFilter) -> NSString {
        "\(fileName)_\(filter.rawValue)" as NSString
    }
}

// MARK: - UIImage 拡張

extension UIImage {

    var estimatedMemoryCost: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return self }
        let scale = maxDimension / currentMax
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
