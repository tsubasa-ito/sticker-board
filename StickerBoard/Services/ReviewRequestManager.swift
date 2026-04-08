import Foundation

final class ReviewRequestManager: Sendable {
    static let shared = ReviewRequestManager()

    private static let cooldownDays = 90
    private static let maxRequestsPer365Days = 3
    private static let rollingWindowDays = 365
    static let stickerMilestones: Set<Int> = [5, 15, 30]
    static let launchMilestone = 5

    // MARK: - リクエスト可否判定

    /// レビューリクエストの条件を満たすか判定する（Appleの365日ローリングウィンドウ準拠）
    /// - Parameters:
    ///   - requestDates: 過去のリクエスト日時（TimeIntervalSince1970の配列）
    ///   - now: 現在日時（テスト時に任意の日時を注入可能）
    func shouldRequestReview(requestDates: [Double], now: Date = Date()) -> Bool {
        let recentDates = requestDatesWithinWindow(from: requestDates, now: now)

        // 365日以内のリクエストが3回以上なら不可
        guard recentDates.count < Self.maxRequestsPer365Days else { return false }

        // 直近のリクエストから90日未満なら不可
        if let mostRecent = recentDates.max() {
            let daysSince = Calendar.current.dateComponents([.day], from: mostRecent, to: now).day ?? 0
            guard daysSince >= Self.cooldownDays else { return false }
        }

        return true
    }

    /// リクエスト実施後の新しい日時配列を返す（状態更新ロジックをカプセル化）
    /// - Parameters:
    ///   - requestDates: 現在保存されているリクエスト日時配列
    ///   - now: 現在日時
    /// - Returns: 新しいリクエストを追加した配列（最大3件）
    func updatedRequestDates(_ requestDates: [Double], now: Date = Date()) -> [Double] {
        var updated = requestDates
        updated.append(now.timeIntervalSince1970)
        return Array(updated.suffix(Self.maxRequestsPer365Days))
    }

    // MARK: - トリガー判定

    func isStickerMilestone(_ count: Int) -> Bool {
        Self.stickerMilestones.contains(count)
    }

    func isLaunchMilestone(_ count: Int) -> Bool {
        count == Self.launchMilestone
    }

    // MARK: - Private

    private func requestDatesWithinWindow(from requestDates: [Double], now: Date) -> [Date] {
        requestDates
            .map { Date(timeIntervalSince1970: $0) }
            .filter {
                let days = Calendar.current.dateComponents([.day], from: $0, to: now).day ?? Int.max
                return days < Self.rollingWindowDays
            }
    }
}
