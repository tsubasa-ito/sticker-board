import Testing
import Foundation
@testable import StickerBoard

struct ReviewRequestManagerTests {

    // MARK: - shouldRequestReview: 初回・クールダウン

    @Test func 初回は常にリクエスト可能() {
        let manager = ReviewRequestManager.shared

        #expect(manager.shouldRequestReview(requestDates: []) == true)
    }

    @Test func 前回リクエストから90日以上経過でリクエスト可能() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let ninetyOneDaysAgo = now.addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970

        #expect(manager.shouldRequestReview(requestDates: [ninetyOneDaysAgo], now: now) == true)
    }

    @Test func 前回リクエストから90日未満ではリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let eightyNineDaysAgo = now.addingTimeInterval(-89 * 24 * 60 * 60).timeIntervalSince1970

        #expect(manager.shouldRequestReview(requestDates: [eightyNineDaysAgo], now: now) == false)
    }

    @Test func 直前にリクエストした場合はリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let justNow = now.timeIntervalSince1970

        #expect(manager.shouldRequestReview(requestDates: [justNow], now: now) == false)
    }

    // MARK: - shouldRequestReview: 365日ローリングウィンドウ

    @Test func ローリングウィンドウ内のリクエストが2件ならリクエスト可能() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let ninetyOneDaysAgo = now.addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970
        let twoHundredDaysAgo = now.addingTimeInterval(-200 * 24 * 60 * 60).timeIntervalSince1970

        #expect(manager.shouldRequestReview(requestDates: [twoHundredDaysAgo, ninetyOneDaysAgo], now: now) == true)
    }

    @Test func ローリングウィンドウ内のリクエストが3件ならリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let ninetyOneDaysAgo = now.addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970
        let twoHundredDaysAgo = now.addingTimeInterval(-200 * 24 * 60 * 60).timeIntervalSince1970
        let threeHundredDaysAgo = now.addingTimeInterval(-300 * 24 * 60 * 60).timeIntervalSince1970

        #expect(manager.shouldRequestReview(
            requestDates: [threeHundredDaysAgo, twoHundredDaysAgo, ninetyOneDaysAgo],
            now: now
        ) == false)
    }

    @Test func ウィンドウより古いリクエストはカウントされない() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let ninetyOneDaysAgo = now.addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970
        let twoHundredDaysAgo = now.addingTimeInterval(-200 * 24 * 60 * 60).timeIntervalSince1970
        // 366日前はウィンドウ外
        let threeSixtySixDaysAgo = now.addingTimeInterval(-366 * 24 * 60 * 60).timeIntervalSince1970

        // 365日以内は2件のみ → リクエスト可能
        #expect(manager.shouldRequestReview(
            requestDates: [threeSixtySixDaysAgo, twoHundredDaysAgo, ninetyOneDaysAgo],
            now: now
        ) == true)
    }

    @Test func ローリングウィンドウで年またぎも正しく動作する() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        // 約1年と1日前（ウィンドウ外）に3回リクエスト済みでも今はリクエスト可能
        let longAgo = now.addingTimeInterval(-370 * 24 * 60 * 60).timeIntervalSince1970

        #expect(manager.shouldRequestReview(
            requestDates: [longAgo, longAgo, longAgo],
            now: now
        ) == true)
    }

    // MARK: - isStickerMilestone

    @Test func シール5枚目はマイルストーン() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(5) == true)
    }

    @Test func シール15枚目はマイルストーン() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(15) == true)
    }

    @Test func シール30枚目はマイルストーン() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(30) == true)
    }

    @Test func シール1枚目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(1) == false)
    }

    @Test func シール10枚目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(10) == false)
    }

    @Test func シール31枚目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isStickerMilestone(31) == false)
    }

    // MARK: - isLaunchMilestone

    @Test func 起動5回目はマイルストーン() {
        #expect(ReviewRequestManager.shared.isLaunchMilestone(5) == true)
    }

    @Test func 起動1回目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isLaunchMilestone(1) == false)
    }

    @Test func 起動4回目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isLaunchMilestone(4) == false)
    }

    @Test func 起動6回目はマイルストーンではない() {
        #expect(ReviewRequestManager.shared.isLaunchMilestone(6) == false)
    }

    // MARK: - updatedRequestDates

    @Test func リクエスト後に日時が追加される() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let result = manager.updatedRequestDates([], now: now)

        #expect(result.count == 1)
        #expect(result[0] == now.timeIntervalSince1970)
    }

    @Test func 既存の日時に新しい日時が追加される() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let past = now.addingTimeInterval(-100 * 24 * 60 * 60).timeIntervalSince1970
        let result = manager.updatedRequestDates([past], now: now)

        #expect(result.count == 2)
        #expect(result[1] == now.timeIntervalSince1970)
    }

    @Test func 最大3件を超えると古い日時が削除される() {
        let manager = ReviewRequestManager.shared
        let now = Date()
        let dates = [
            now.addingTimeInterval(-300 * 24 * 60 * 60).timeIntervalSince1970,
            now.addingTimeInterval(-200 * 24 * 60 * 60).timeIntervalSince1970,
            now.addingTimeInterval(-100 * 24 * 60 * 60).timeIntervalSince1970,
        ]
        let result = manager.updatedRequestDates(dates, now: now)

        #expect(result.count == 3)
        // 最も古い日時が削除され、新しい日時が末尾に追加される
        #expect(result.last == now.timeIntervalSince1970)
        #expect(!result.contains(dates[0]))
    }
}
