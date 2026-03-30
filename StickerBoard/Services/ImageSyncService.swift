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
        // iCloud Documents ディレクトリ配下に配置（CloudDocuments同期の要件）
        let documentsURL = cloudContainerURL.appendingPathComponent("Documents", isDirectory: true)
        let cloudStickersURL = documentsURL.appendingPathComponent("Stickers", isDirectory: true)
        let cloudBackgroundsURL = documentsURL.appendingPathComponent("Backgrounds", isDirectory: true)

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
        // ファイルI/Oをバックグラウンドで実行（メインスレッドブロック回避）
        try await Task.detached {
            let fm = FileManager.default

            let localFiles = Set(try fileNames(at: localURL))
            let cloudFiles = Set(try fileNames(at: cloudURL))

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
        }.value
    }

    /// ディレクトリが存在しない場合は空配列を返す（新規インストール時）。
    /// それ以外のエラー（権限不足等）はthrowして呼び出し元に伝搬する。
    private func fileNames(at directoryURL: URL) throws -> [String] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directoryURL.path) else { return [] }
        let contents = try fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        return contents.map(\.lastPathComponent)
    }
}
