import Testing
import Foundation
@testable import StickerBoard

@MainActor
struct ICloudSyncManagerTests {

    // MARK: - テスト用モック

    private final class MockSubscriptionStatus: SubscriptionStatusProviding {
        var isProUser: Bool
        init(isProUser: Bool) { self.isProUser = isProUser }
    }

    private struct MockCloudContainer: CloudContainerProviding {
        var isICloudAvailable: Bool
        var containerURL: URL?
    }

    private final class MockImageSyncService: ImageSyncServiceProtocol, @unchecked Sendable {
        var syncCallCount = 0
        var shouldFail = false
        var result = ImageSyncResult(uploadedCount: 0, downloadedCount: 0)

        func syncImages(
            localStickersURL: URL,
            localBackgroundsURL: URL,
            cloudContainerURL: URL
        ) async throws -> ImageSyncResult {
            syncCallCount += 1
            if shouldFail {
                throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "同期に失敗しました"])
            }
            return result
        }
    }

    private func makeManager(
        isPro: Bool = true,
        isCloudAvailable: Bool = true,
        containerURL: URL? = URL(fileURLWithPath: "/tmp/test-cloud"),
        imageSyncService: MockImageSyncService = MockImageSyncService(),
        dateProvider: @escaping () -> Date = { Date() },
        userDefaults: UserDefaults? = nil
    ) -> (ICloudSyncManager, MockImageSyncService) {
        let defaults = userDefaults ?? UserDefaults(suiteName: UUID().uuidString)!
        let manager = ICloudSyncManager(
            subscriptionStatusProvider: MockSubscriptionStatus(isProUser: isPro),
            cloudContainerProvider: MockCloudContainer(
                isICloudAvailable: isCloudAvailable,
                containerURL: containerURL
            ),
            imageSyncService: imageSyncService,
            dateProvider: dateProvider,
            userDefaults: defaults
        )
        return (manager, imageSyncService)
    }

    // MARK: - ステータス初期化

    @Test func Proユーザーでない場合はdisabledステータス() {
        let (manager, _) = makeManager(isPro: false)
        #expect(manager.syncStatus == .disabled)
    }

    @Test func iCloudが利用不可の場合はdisabledステータス() {
        let (manager, _) = makeManager(isCloudAvailable: false)
        #expect(manager.syncStatus == .disabled)
    }

    @Test func Proかつ利用可能ならidleステータス() {
        let (manager, _) = makeManager(isPro: true, isCloudAvailable: true)
        #expect(manager.syncStatus == .idle)
    }

    // MARK: - refreshStatus

    @Test func refreshStatusでPro解約後にdisabledになる() {
        let sub = MockSubscriptionStatus(isProUser: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let manager = ICloudSyncManager(
            subscriptionStatusProvider: sub,
            cloudContainerProvider: MockCloudContainer(isICloudAvailable: true, containerURL: URL(fileURLWithPath: "/tmp")),
            imageSyncService: MockImageSyncService(),
            userDefaults: defaults
        )
        #expect(manager.syncStatus == .idle)

        sub.isProUser = false
        manager.refreshStatus()
        #expect(manager.syncStatus == .disabled)
    }

    // MARK: - 同期実行

    @Test func startSyncでsyncing状態を経てsyncedになる() async {
        let fixedDate = Date(timeIntervalSince1970: 1000000)
        let (manager, syncService) = makeManager(dateProvider: { fixedDate })

        await manager.startSync()

        #expect(syncService.syncCallCount == 1)
        #expect(manager.syncStatus == .synced(fixedDate))
    }

    @Test func 同期成功でlastSyncDateが更新される() async {
        let fixedDate = Date(timeIntervalSince1970: 2000000)
        let (manager, _) = makeManager(dateProvider: { fixedDate })

        await manager.startSync()

        #expect(manager.lastSyncDate == fixedDate)
    }

    @Test func 同期成功でUserDefaultsにlastSyncDateが保存される() async {
        let fixedDate = Date(timeIntervalSince1970: 3000000)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let (manager, _) = makeManager(dateProvider: { fixedDate }, userDefaults: defaults)

        await manager.startSync()

        let savedDate = defaults.object(forKey: ICloudSyncManager.lastSyncDateKey) as? Date
        #expect(savedDate == fixedDate)
    }

    @Test func 同期失敗でerrorステータスになる() async {
        let syncService = MockImageSyncService()
        syncService.shouldFail = true
        let (manager, _) = makeManager(imageSyncService: syncService)

        await manager.startSync()

        if case .error(let message) = manager.syncStatus {
            #expect(message == "バックアップに失敗しました。しばらく待ってから再度お試しください。")
        } else {
            Issue.record("error ステータスが期待されます")
        }
    }

    @Test func 非Proユーザーのsync試行はdisabledのまま() async {
        let syncService = MockImageSyncService()
        let (manager, _) = makeManager(isPro: false, imageSyncService: syncService)

        await manager.startSync()

        #expect(manager.syncStatus == .disabled)
        #expect(syncService.syncCallCount == 0)
    }

    @Test func iCloud不可時のsync試行はerrorになる() async {
        let (manager, _) = makeManager(isPro: true, isCloudAvailable: false, containerURL: nil)

        await manager.startSync()

        if case .error = manager.syncStatus {
            // OK
        } else {
            Issue.record("error ステータスが期待されます")
        }
    }

    // MARK: - 前回同期日の復元

    @Test func 初期化時にUserDefaultsからlastSyncDateを復元する() {
        let savedDate = Date(timeIntervalSince1970: 5000000)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(savedDate, forKey: ICloudSyncManager.lastSyncDateKey)

        let manager = ICloudSyncManager(
            subscriptionStatusProvider: MockSubscriptionStatus(isProUser: true),
            cloudContainerProvider: MockCloudContainer(isICloudAvailable: true, containerURL: URL(fileURLWithPath: "/tmp")),
            imageSyncService: MockImageSyncService(),
            userDefaults: defaults
        )

        #expect(manager.lastSyncDate == savedDate)
        #expect(manager.syncStatus == .synced(savedDate))
    }

    // MARK: - 同期結果

    @Test func 同期結果のuploadとdownloadカウントが反映される() async {
        let syncService = MockImageSyncService()
        syncService.result = ImageSyncResult(uploadedCount: 5, downloadedCount: 3)
        let (manager, _) = makeManager(imageSyncService: syncService)

        await manager.startSync()

        #expect(manager.lastSyncResult?.uploadedCount == 5)
        #expect(manager.lastSyncResult?.downloadedCount == 3)
    }
}
