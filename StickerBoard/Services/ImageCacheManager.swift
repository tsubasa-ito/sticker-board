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
        guard let thumbnail = ImageStorage.createThumbnailFromDisk(fileName: fileName, maxPixelSize: size) else { return nil }
        thumbnailCache.setObject(thumbnail, forKey: key, cost: thumbnail.estimatedMemoryCost)
        return thumbnail
    }

    // MARK: - 加工済みサムネイル（フィルター＋枠線）

    func processedThumbnail(for fileName: String, size: CGFloat, filter: StickerFilter, borderWidth: StickerBorderWidth, borderColorHex: String) -> UIImage? {
        // フィルターも枠線もなし → 通常サムネイル
        if filter == .original && borderWidth == .none {
            return thumbnail(for: fileName, size: size)
        }

        let key = processedThumbnailKey(fileName: fileName, size: size, filter: filter, borderWidth: borderWidth, borderColorHex: borderColorHex)
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        guard let thumb = thumbnail(for: fileName, size: size) else { return nil }

        var image = filter == .original ? thumb : StickerFilterService.apply(filter, to: thumb)
        if borderWidth != .none, let bordered = StickerBorderService.applyBorder(to: image, width: borderWidth, colorHex: borderColorHex) {
            image = bordered
        }
        thumbnailCache.setObject(image, forKey: key, cost: image.estimatedMemoryCost)
        return image
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

    // MARK: - フィルター＋枠線適用済み

    func processed(for fileName: String, filter: StickerFilter, borderWidth: StickerBorderWidth, borderColorHex: String) -> UIImage? {
        // フィルターも枠線もなし → フル解像度
        if filter == .original && borderWidth == .none {
            return fullResolution(for: fileName)
        }
        // 枠線なし → 既存のフィルターキャッシュを使用
        if borderWidth == .none {
            return filtered(for: fileName, filter: filter)
        }

        let key = processedKey(fileName: fileName, filter: filter, borderWidth: borderWidth, borderColorHex: borderColorHex)
        if let cached = filteredCache.object(forKey: key) {
            return cached
        }

        // ベース画像を取得（フィルター適用 or オリジナル）
        let baseImage: UIImage?
        if filter == .original {
            baseImage = fullResolution(for: fileName)
        } else {
            baseImage = filtered(for: fileName, filter: filter)
        }
        guard let base = baseImage else { return nil }

        // 枠線を適用
        guard let result = StickerBorderService.applyBorder(to: base, width: borderWidth, colorHex: borderColorHex) else {
            return base
        }
        filteredCache.setObject(result, forKey: key, cost: result.estimatedMemoryCost)
        return result
    }

    func setProcessed(_ image: UIImage, for fileName: String, filter: StickerFilter, borderWidth: StickerBorderWidth, borderColorHex: String) {
        let key = processedKey(fileName: fileName, filter: filter, borderWidth: borderWidth, borderColorHex: borderColorHex)
        filteredCache.setObject(image, forKey: key, cost: image.estimatedMemoryCost)
    }

    // MARK: - キャッシュ無効化

    /// サムネイルキャッシュで使用されるサイズ一覧
    private static let knownThumbnailSizes: [CGFloat] = [112, 200]

    func removeAll(for fileName: String) {
        let key = fileName as NSString
        fullResolutionCache.removeObject(forKey: key)
        for size in Self.knownThumbnailSizes {
            thumbnailCache.removeObject(forKey: thumbnailKey(fileName: fileName, size: size))
        }
        for filter in StickerFilter.allCases where filter != .original {
            filteredCache.removeObject(forKey: filteredKey(fileName: fileName, filter: filter))
        }
    }

    @objc private func purgeAllCaches() {
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

    private func processedThumbnailKey(fileName: String, size: CGFloat, filter: StickerFilter, borderWidth: StickerBorderWidth, borderColorHex: String) -> NSString {
        "\(fileName)_\(Int(size))_\(filter.rawValue)_\(borderWidth.rawValue)_\(borderColorHex)" as NSString
    }

    private func processedKey(fileName: String, filter: StickerFilter, borderWidth: StickerBorderWidth, borderColorHex: String) -> NSString {
        "\(fileName)_\(filter.rawValue)_\(borderWidth.rawValue)_\(borderColorHex)" as NSString
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

    /// 透明ピクセルの余白をトリミングして、不透明領域の外接矩形で切り抜く
    func alphaTrimmed() -> UIImage {
        guard let cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return self }

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return self }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        // アルファチャンネルの位置を特定
        let alphaInfo = cgImage.alphaInfo
        let alphaOffset: Int
        switch alphaInfo {
        case .premultipliedFirst, .first, .alphaOnly:
            alphaOffset = 0
        case .premultipliedLast, .last:
            alphaOffset = bytesPerPixel - 1
        case .none, .noneSkipFirst, .noneSkipLast:
            return self // アルファなし → トリミング不要
        @unknown default:
            return self // 未知のフォーマットはトリミングしない
        }

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let pixelOffset = rowOffset + x * bytesPerPixel + alphaOffset
                if bytes[pixelOffset] > 0 {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        // 不透明ピクセルが見つからなかった場合
        guard minX <= maxX, minY <= maxY else { return self }

        let trimRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let croppedCGImage = cgImage.cropping(to: trimRect) else { return self }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
}
