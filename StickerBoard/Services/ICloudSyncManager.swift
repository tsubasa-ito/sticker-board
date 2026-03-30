import Foundation
import Observation

// MARK: - Protocols

protocol SubscriptionStatusProviding: AnyObject {
    var isProUser: Bool { get }
}

extension SubscriptionManager: SubscriptionStatusProviding {}

protocol CloudContainerProviding: Sendable {
    var isICloudAvailable: Bool { get }
    var containerURL: URL? { get }
}

struct DefaultCloudContainerProvider: CloudContainerProviding {
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var containerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }
}

// MARK: - Sync Result

struct ImageSyncResult: Equatable, Sendable {
    let uploadedCount: Int
    let downloadedCount: Int
}

// MARK: - ICloudSyncManager

@MainActor
@Observable
final class ICloudSyncManager {

    // MARK: - Types

    enum SyncStatus: Equatable {
        case disabled
        case idle
        case syncing
        case synced(Date)
        case error(String)
    }

    // MARK: - State

    private(set) var syncStatus: SyncStatus = .disabled
    private(set) var lastSyncDate: Date?
    private(set) var lastSyncResult: ImageSyncResult?

    // MARK: - Constants

    static let lastSyncDateKey = "iCloudLastSyncDate"

    // MARK: - Dependencies

    private let subscriptionStatusProvider: any SubscriptionStatusProviding
    private let cloudContainerProvider: any CloudContainerProviding
    private let imageSyncService: any ImageSyncServiceProtocol
    private let dateProvider: () -> Date
    private let userDefaults: UserDefaults

    // MARK: - Singleton

    static let shared = ICloudSyncManager()

    convenience init() {
        self.init(
            subscriptionStatusProvider: SubscriptionManager.shared,
            cloudContainerProvider: DefaultCloudContainerProvider(),
            imageSyncService: ImageSyncService()
        )
    }

    init(
        subscriptionStatusProvider: any SubscriptionStatusProviding,
        cloudContainerProvider: any CloudContainerProviding,
        imageSyncService: any ImageSyncServiceProtocol,
        dateProvider: @escaping () -> Date = { Date() },
        userDefaults: UserDefaults = .standard
    ) {
        self.subscriptionStatusProvider = subscriptionStatusProvider
        self.cloudContainerProvider = cloudContainerProvider
        self.imageSyncService = imageSyncService
        self.dateProvider = dateProvider
        self.userDefaults = userDefaults
        self.lastSyncDate = userDefaults.object(forKey: Self.lastSyncDateKey) as? Date
        refreshStatus()
    }

    // MARK: - Status

    func refreshStatus() {
        guard subscriptionStatusProvider.isProUser else {
            syncStatus = .disabled
            return
        }
        guard cloudContainerProvider.isICloudAvailable else {
            syncStatus = .disabled
            return
        }
        if case .syncing = syncStatus { return }
        if let lastSync = lastSyncDate {
            syncStatus = .synced(lastSync)
        } else {
            syncStatus = .idle
        }
    }

    // MARK: - Sync

    func startSync() async {
        guard subscriptionStatusProvider.isProUser else {
            syncStatus = .disabled
            return
        }
        guard cloudContainerProvider.isICloudAvailable,
              let containerURL = cloudContainerProvider.containerURL else {
            syncStatus = .error("iCloudが利用できません。設定アプリでiCloudにサインインしてください。")
            return
        }

        syncStatus = .syncing

        do {
            let stickersURL = Self.localStickersURL
            let backgroundsURL = Self.localBackgroundsURL
            let result = try await imageSyncService.syncImages(
                localStickersURL: stickersURL,
                localBackgroundsURL: backgroundsURL,
                cloudContainerURL: containerURL
            )
            let now = dateProvider()
            lastSyncDate = now
            lastSyncResult = result
            userDefaults.set(now, forKey: Self.lastSyncDateKey)
            syncStatus = .synced(now)
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Local Paths

    private static var localStickersURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Stickers", isDirectory: true)
    }

    private static var localBackgroundsURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Backgrounds", isDirectory: true)
    }
}
