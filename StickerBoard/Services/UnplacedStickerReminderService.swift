import Foundation
import OSLog
import UserNotifications
import SwiftData
import UIKit

final class UnplacedStickerReminderService: Sendable {

    static let shared = UnplacedStickerReminderService()

    static let notificationIdentifier = "unplaced-sticker-reminder"
    private static let isEnabledKey = "unplacedStickerReminderEnabled"
    private static let logger = Logger(subsystem: "com.tebasaki.StickerBoard", category: "ReminderService")

    // MARK: - 有効/無効管理

    var isEnabled: Bool { isEnabled(in: .standard) }

    func isEnabled(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: Self.isEnabledKey)
    }

    func setEnabled(_ enabled: Bool) {
        setEnabled(enabled, in: .standard)
    }

    func setEnabled(_ enabled: Bool, in defaults: UserDefaults) {
        defaults.set(enabled, forKey: Self.isEnabledKey)
    }

    // MARK: - 未配置シール検出（テスト可能な純粋ロジック）

    func detectUnplaced(stickers: [Sticker], boards: [Board]) -> [Sticker] {
        let placedFileNames = Set(boards.flatMap { $0.placements.map(\.imageFileName) })
        return stickers.filter { !placedFileNames.contains($0.imageFileName) }
    }

    // MARK: - 通知権限リクエスト

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - 通知スケジューリング

    func scheduleNotification(for sticker: Sticker) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "シールボード")
        content.body = String(localized: "このシール、まだボードに貼ってないよ📌")
        content.sound = .default
        content.userInfo = ["stickerId": sticker.id.uuidString]

        var temporaryAttachmentURL: URL?
        if let (attachment, url) = await makeThumbnailAttachment(fileName: sticker.imageFileName) {
            content.attachments = [attachment]
            temporaryAttachmentURL = url
        }
        defer {
            // UNNotificationAttachment はファイルをコピーするため、登録後に一時ファイルを削除
            if let url = temporaryAttachmentURL {
                try? FileManager.default.removeItem(at: url)
            }
        }

        var dateComponents = DateComponents()
        dateComponents.weekday = 7  // 土曜日
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
        do {
            try await center.add(request)
        } catch {
            Self.logger.error("通知スケジューリングに失敗: \(error)")
        }
    }

    func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.notificationIdentifier]
        )
    }

    // MARK: - 起動時リスケジュール

    @MainActor
    func rescheduleIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) async {
        guard isEnabled(in: defaults) else { return }

        let stickers: [Sticker]
        let boards: [Board]
        do {
            stickers = try context.fetch(FetchDescriptor<Sticker>())
            boards = try context.fetch(FetchDescriptor<Board>())
        } catch {
            Self.logger.error("データフェッチに失敗: \(error)")
            return
        }

        let unplaced = detectUnplaced(stickers: stickers, boards: boards)

        if let sticker = unplaced.randomElement() {
            await scheduleNotification(for: sticker)
        } else {
            cancelNotification()
        }
    }

    // MARK: - ディープリンク解析

    static func parseStickerId(from url: URL) -> UUID? {
        guard url.scheme == "stickerboard",
              url.host == "library",
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let idString = queryItems.first(where: { $0.name == "stickerId" })?.value else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    // MARK: - Private

    private func makeThumbnailAttachment(fileName: String) async -> (UNNotificationAttachment, URL)? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".png")

        return await withCheckedContinuation { continuation in
            Task.detached {
                // ImageIO ベースでフル解像度をメモリに展開せず直接サムネイル生成（通知用途のためキャッシュ不要）
                guard let thumbnail = ImageStorage.createThumbnailFromDisk(fileName: fileName, maxPixelSize: 200),
                      let data = thumbnail.pngData() else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    try data.write(to: tempURL)
                    let attachment = try UNNotificationAttachment(
                        identifier: "sticker-thumbnail",
                        url: tempURL
                    )
                    continuation.resume(returning: (attachment, tempURL))
                } catch {
                    try? FileManager.default.removeItem(at: tempURL)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
