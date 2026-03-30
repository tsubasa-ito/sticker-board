import Foundation

// MARK: - Protocol

protocol ImageSyncServiceProtocol: Sendable {
    func syncImages(
        localStickersURL: URL,
        localBackgroundsURL: URL,
        cloudContainerURL: URL
    ) async throws -> ImageSyncResult
}

// MARK: - Implementation

struct ImageSyncService: ImageSyncServiceProtocol {

    func syncImages(
        localStickersURL: URL,
        localBackgroundsURL: URL,
        cloudContainerURL: URL
    ) async throws -> ImageSyncResult {
        let cloudStickersURL = cloudContainerURL.appendingPathComponent("Stickers", isDirectory: true)
        let cloudBackgroundsURL = cloudContainerURL.appendingPathComponent("Backgrounds", isDirectory: true)

        // クラウドディレクトリを作成
        try FileManager.default.createDirectory(at: cloudStickersURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cloudBackgroundsURL, withIntermediateDirectories: true)

        // シール画像を同期
        let stickersResult = try await syncDirectory(
            localURL: localStickersURL,
            cloudURL: cloudStickersURL
        )

        // 背景画像を同期
        let backgroundsResult = try await syncDirectory(
            localURL: localBackgroundsURL,
            cloudURL: cloudBackgroundsURL
        )

        return ImageSyncResult(
            uploadedCount: stickersResult.uploaded + backgroundsResult.uploaded,
            downloadedCount: stickersResult.downloaded + backgroundsResult.downloaded
        )
    }

    // MARK: - Private

    private struct DirectorySyncResult {
        let uploaded: Int
        let downloaded: Int
    }

    private func syncDirectory(localURL: URL, cloudURL: URL) async throws -> DirectorySyncResult {
        let fm = FileManager.default

        let localFiles = Set(fileNames(at: localURL))
        let cloudFiles = Set(fileNames(at: cloudURL))

        var uploaded = 0
        var downloaded = 0

        // ローカル → クラウド（ローカルにのみ存在するファイル）
        let toUpload = localFiles.subtracting(cloudFiles)
        for fileName in toUpload {
            let source = localURL.appendingPathComponent(fileName)
            let destination = cloudURL.appendingPathComponent(fileName)
            try fm.copyItem(at: source, to: destination)
            uploaded += 1
        }

        // クラウド → ローカル（クラウドにのみ存在するファイル）
        let toDownload = cloudFiles.subtracting(localFiles)
        for fileName in toDownload {
            let source = cloudURL.appendingPathComponent(fileName)
            let destination = localURL.appendingPathComponent(fileName)
            try fm.copyItem(at: source, to: destination)
            downloaded += 1
        }

        return DirectorySyncResult(uploaded: uploaded, downloaded: downloaded)
    }

    private func fileNames(at directoryURL: URL) -> [String] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return contents.map(\.lastPathComponent)
    }
}
