import Testing
import Foundation
@testable import StickerBoard

struct ReviewRequestManagerTests {

    // MARK: - shouldRequestReview: クールダウン

    @Test func 初回は常にリクエスト可能() {
        let manager = ReviewRequestManager.shared

        #expect(manager.shouldRequestReview(
            lastRequestDate: 0,
            requestCountThisYear: 0,
            lastRequestYear: 0
        ) == true)
    }

    @Test func 前回リクエストから90日以上経過でリクエスト可能() {
        let manager = ReviewRequestManager.shared
        let ninetyOneDaysAgo = Date().addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: ninetyOneDaysAgo,
            requestCountThisYear: 1,
            lastRequestYear: currentYear
        ) == true)
    }

    @Test func 前回リクエストから90日未満ではリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let eightNineDaysAgo = Date().addingTimeInterval(-89 * 24 * 60 * 60).timeIntervalSince1970
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: eightNineDaysAgo,
            requestCountThisYear: 1,
            lastRequestYear: currentYear
        ) == false)
    }

    @Test func 直前にリクエストした場合はリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let justNow = Date().timeIntervalSince1970
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: justNow,
            requestCountThisYear: 1,
            lastRequestYear: currentYear
        ) == false)
    }

    // MARK: - shouldRequestReview: 年間上限

    @Test func 年間3回未満ならリクエスト可能() {
        let manager = ReviewRequestManager.shared
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: 0,
            requestCountThisYear: 2,
            lastRequestYear: currentYear
        ) == true)
    }

    @Test func 年間3回に達したらリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: 0,
            requestCountThisYear: 3,
            lastRequestYear: currentYear
        ) == false)
    }

    @Test func 年間3回超過でもリクエスト不可() {
        let manager = ReviewRequestManager.shared
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(manager.shouldRequestReview(
            lastRequestDate: 0,
            requestCountThisYear: 5,
            lastRequestYear: currentYear
        ) == false)
    }

    // MARK: - shouldRequestReview: 年またぎリセット

    @Test func 年が変わればカウントがリセットされリクエスト可能() {
        let manager = ReviewRequestManager.shared
        let lastYear = Calendar.current.component(.year, from: Date()) - 1
        let ninetyOneDaysAgo = Date().addingTimeInterval(-91 * 24 * 60 * 60).timeIntervalSince1970

        // 昨年3回リクエスト済みでも今年はリセットされてリクエスト可能
        #expect(manager.shouldRequestReview(
            lastRequestDate: ninetyOneDaysAgo,
            requestCountThisYear: 3,
            lastRequestYear: lastYear
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
}
