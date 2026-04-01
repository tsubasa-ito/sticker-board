import Foundation

final class AppUpdateChecker: Sendable {
    static let shared = AppUpdateChecker()

    private static let checkInterval: TimeInterval = 24 * 60 * 60 // 24時間

    struct AppStoreInfo: Sendable {
        let version: String
        let storeURL: URL
    }

    // MARK: - iTunes Lookup API レスポンス

    struct ITunesLookupResponse: Decodable, Sendable {
        let resultCount: Int
        let results: [ITunesResult]
    }

    struct ITunesResult: Decodable, Sendable {
        let version: String
        let trackViewUrl: String
    }

    // MARK: - バージョンチェック

    func checkForUpdate() async throws -> AppStoreInfo? {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.tebasaki.StickerBoard"
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleID)&country=jp"
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)

        guard let result = response.results.first,
              let storeURL = URL(string: result.trackViewUrl) else {
            return nil
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        guard isNewerVersion(result.version, than: currentVersion) else {
            return nil
        }

        return AppStoreInfo(version: result.version, storeURL: storeURL)
    }

    // MARK: - バージョン比較

    func isNewerVersion(_ storeVersion: String, than currentVersion: String) -> Bool {
        let storeParts = parseVersion(storeVersion)
        let currentParts = parseVersion(currentVersion)

        guard !storeParts.isEmpty, !currentParts.isEmpty else { return false }

        for i in 0..<max(storeParts.count, currentParts.count) {
            let storePart = i < storeParts.count ? storeParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0
            if storePart > currentPart { return true }
            if storePart < currentPart { return false }
        }
        return false
    }

    func isMajorUpdate(_ storeVersion: String, from currentVersion: String) -> Bool {
        let storeParts = parseVersion(storeVersion)
        let currentParts = parseVersion(currentVersion)

        guard !storeParts.isEmpty, !currentParts.isEmpty else { return false }

        return storeParts[0] > currentParts[0]
    }

    // MARK: - チェック間隔

    func shouldCheckUpdate(lastCheckDate: Double) -> Bool {
        guard lastCheckDate > 0 else { return true }
        let elapsed = Date().timeIntervalSince1970 - lastCheckDate
        return elapsed >= Self.checkInterval
    }

    // MARK: - アラート表示判定

    func shouldShowAlert(storeVersion: String, currentVersion: String, skippedVersion: String) -> Bool {
        guard isNewerVersion(storeVersion, than: currentVersion) else { return false }

        if isMajorUpdate(storeVersion, from: currentVersion) {
            return true
        }

        return storeVersion != skippedVersion
    }

    // MARK: - Private

    private func parseVersion(_ version: String) -> [Int] {
        version.split(separator: ".").compactMap { Int($0) }
    }
}
