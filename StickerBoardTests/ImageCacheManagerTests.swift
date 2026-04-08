import Testing
import UIKit
@testable import StickerBoard

struct ImageCacheManagerTests {

    // MARK: - ヘルパー

    /// 100×100 の不透明なテスト画像を生成
    private func makeTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - フル解像度キャッシュ

    @Test func setFullResolutionで保存した画像をfullResolutionで取得できる() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFullResolution(image, for: fileName)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        let cached = ImageCacheManager.shared.fullResolution(for: fileName)
        #expect(cached != nil)
    }

    @Test func removeAllでフル解像度キャッシュが無効化される() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFullResolution(image, for: fileName)
        ImageCacheManager.shared.removeAll(for: fileName)

        // ディスクにも存在しないためnilになる
        let cached = ImageCacheManager.shared.fullResolution(for: fileName)
        #expect(cached == nil)
    }

    // MARK: - フィルター適用済みキャッシュ

    @Test func setFilteredで保存した画像をfilteredで取得できる() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFiltered(image, for: fileName, filter: .sparkle)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        let cached = ImageCacheManager.shared.filtered(for: fileName, filter: .sparkle)
        #expect(cached != nil)
    }

    @Test func filteredでoriginalフィルターを指定するとfullResolutionにフォールバックする() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFullResolution(image, for: fileName)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        let cached = ImageCacheManager.shared.filtered(for: fileName, filter: .original)
        #expect(cached != nil)
    }

    @Test func removeAllでフィルターキャッシュも無効化される() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFiltered(image, for: fileName, filter: .sparkle)
        ImageCacheManager.shared.removeAll(for: fileName)

        // ディスクに存在しないためnilになる
        let cached = ImageCacheManager.shared.filtered(for: fileName, filter: .sparkle)
        #expect(cached == nil)
    }

    // MARK: - 加工済みキャッシュ (processed)

    @Test func setProcessedで保存した画像をprocessedで取得できる() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setProcessed(image, for: fileName, filter: .sparkle, borderWidth: .thin, borderColorHex: "#FFFFFF")
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        let cached = ImageCacheManager.shared.processed(for: fileName, filter: .sparkle, borderWidth: .thin, borderColorHex: "#FFFFFF")
        #expect(cached != nil)
    }

    @Test func processedでフィルターも枠線もなしならfullResolutionにフォールバックする() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFullResolution(image, for: fileName)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        let cached = ImageCacheManager.shared.processed(for: fileName, filter: .original, borderWidth: .none, borderColorHex: "#000000")
        #expect(cached != nil)
    }

    @Test func removeAllでprocessedキャッシュも無効化される() throws {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setProcessed(image, for: fileName, filter: .retro, borderWidth: .medium, borderColorHex: "#FF0000")
        ImageCacheManager.shared.removeAll(for: fileName)

        // ディスクに存在しないためnilになる
        let cached = ImageCacheManager.shared.processed(for: fileName, filter: .retro, borderWidth: .medium, borderColorHex: "#FF0000")
        #expect(cached == nil)
    }

    // MARK: - 並行アクセス（スレッドセーフティ）

    @Test func 複数スレッドからsetとremoveを同時実行してもクラッシュしない() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                let fileName = "concurrent_test_\(i)_\(UUID().uuidString).png"
                let image = makeTestImage()

                group.addTask {
                    ImageCacheManager.shared.setFullResolution(image, for: fileName)
                }
                group.addTask {
                    _ = ImageCacheManager.shared.fullResolution(for: fileName)
                }
                group.addTask {
                    ImageCacheManager.shared.removeAll(for: fileName)
                }
            }
        }
        // クラッシュせずに完了すればスレッドセーフ確認済み
    }

    @Test func 複数スレッドからfullResolutionAsyncを並行呼び出ししてもクラッシュしない() async throws {
        let fileName = "async_concurrent_test_\(UUID().uuidString).png"
        let image = makeTestImage()

        // ディスクに保存してキャッシュヒット・ミス両方をテスト
        let savedName = try ImageStorage.save(image)
        defer { try? ImageStorage.delete(fileName: savedName) }

        await withTaskGroup(of: UIImage?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await ImageCacheManager.shared.fullResolutionAsync(for: savedName)
                }
            }
        }
        // クラッシュせずに完了すればスレッドセーフ確認済み
        ImageCacheManager.shared.removeAll(for: savedName)
    }
}

// MARK: - メモリ警告ハンドラ
// didReceiveMemoryWarningNotification は全キャッシュを一括削除するため、
// 並行実行すると他のテストのキャッシュも消えてしまう。.serialized で直列化する。
@Suite("メモリ警告ハンドラ", .serialized)
struct ImageCacheManagerMemoryWarningTests {

    private func makeTestImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100), format: format)
        return renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        }
    }

    @Test func メモリ警告後はsetFullResolutionで保存したキャッシュがクリアされる() {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFullResolution(image, for: fileName)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        // メモリ警告通知を手動発火（全キャッシュを一括削除）
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // ディスクに存在しないためnilになる
        let cached = ImageCacheManager.shared.fullResolution(for: fileName)
        #expect(cached == nil)
    }

    @Test func メモリ警告後はsetFilteredで保存したキャッシュがクリアされる() {
        let fileName = "test_\(UUID().uuidString).png"
        let image = makeTestImage()

        ImageCacheManager.shared.setFiltered(image, for: fileName, filter: .neon)
        defer { ImageCacheManager.shared.removeAll(for: fileName) }

        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        let cached = ImageCacheManager.shared.filtered(for: fileName, filter: .neon)
        #expect(cached == nil)
    }
}
