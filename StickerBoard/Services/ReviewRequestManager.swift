import Foundation

final class ReviewRequestManager: Sendable {
    static let shared = ReviewRequestManager()

    private static let cooldownDays = 90
    private static let maxRequestsPerYear = 3
    static let stickerMilestones: Set<Int> = [5, 15, 30]
    static let launchMilestone = 5

    // MARK: - リクエスト可否判定

    /// レビューリクエストの条件を満たすか判定する
    /// - Parameters:
    ///   - lastRequestDate: 最後にリクエストした日時（TimeIntervalSince1970、0なら未実施）
    ///   - requestCountThisYear: 今年のリクエスト回数
    ///   - lastRequestYear: 最後にリクエストした年（0なら未実施）
    func shouldRequestReview(
        lastRequestDate: Double,
        requestCountThisYear: Int,
        lastRequestYear: Int
    ) -> Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        let effectiveCount = currentYear == lastRequestYear ? requestCountThisYear : 0

        guard effectiveCount < Self.maxRequestsPerYear else { return false }

        guard lastRequestDate > 0 else { return true }

        let lastDate = Date(timeIntervalSince1970: lastRequestDate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= Self.cooldownDays
    }

    // MARK: - トリガー判定

    func isStickerMilestone(_ count: Int) -> Bool {
        Self.stickerMilestones.contains(count)
    }

    func isLaunchMilestone(_ count: Int) -> Bool {
        count == Self.launchMilestone
    }

    // MARK: - 現在の年

    func currentYear() -> Int {
        Calendar.current.component(.year, from: Date())
    }
}
