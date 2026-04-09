import Testing
import Foundation

/// 本番コードにデバッグ用 print() 文が残っていないことを検証する構造テスト
/// Issue #136: App Store Review Guidelines Section 2.1 準拠
///
/// 注意: このテストはソースコードを文字列として読み込み、正規表現で解析する構造検証テストです。
/// 対象ファイルのパスが変更された場合、テストのパスを実態に合わせて更新してください。
struct DebugPrintRemovalTests {

    // MARK: - ヘルパー

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// ソースコード内の print( 呼び出し行を抽出する（コメント行は除外）
    ///
    /// - Note: 文字列マッチングによる検出のため、文字列リテラル内の "print(" にも反応する可能性がある。
    ///   誤検知で失敗した場合は、正規表現パターンを調整して対処すること。
    private func findPrintCalls(in content: String) -> [String] {
        content.components(separatedBy: .newlines)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("//"), !trimmed.hasPrefix("*") else { return false }
                return line.range(of: #"\bprint\s*\("#, options: .regularExpression) != nil
            }
    }

    // MARK: - SubscriptionManager

    @Test func subscriptionManagerにprint文が含まれていない() throws {
        let content = try readFile("StickerBoard/Services/SubscriptionManager.swift")
        let printLines = findPrintCalls(in: content)
        #expect(
            printLines.isEmpty,
            "SubscriptionManager.swift にデバッグ用 print() が残っています: \(printLines)"
        )
    }

    // MARK: - MotionManager

    @Test func motionManagerにprint文が含まれていない() throws {
        let content = try readFile("StickerBoard/Services/MotionManager.swift")
        let printLines = findPrintCalls(in: content)
        #expect(
            printLines.isEmpty,
            "MotionManager.swift にデバッグ用 print() が残っています: \(printLines)"
        )
    }

    // MARK: - StickerLibraryView

    @Test func stickerLibraryViewにprint文が含まれていない() throws {
        let content = try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
        let printLines = findPrintCalls(in: content)
        #expect(
            printLines.isEmpty,
            "StickerLibraryView.swift にデバッグ用 print() が残っています: \(printLines)"
        )
    }

    // MARK: - os.Logger 使用の確認

    @Test func subscriptionManagerがLoggerを使用している() throws {
        let content = try readFile("StickerBoard/Services/SubscriptionManager.swift")
        #expect(
            content.contains("import os") || content.contains("import OSLog"),
            "SubscriptionManager.swift に os/OSLog の import が必要です"
        )
    }

    @Test func motionManagerがLoggerを使用している() throws {
        let content = try readFile("StickerBoard/Services/MotionManager.swift")
        #expect(
            content.contains("import os") || content.contains("import OSLog"),
            "MotionManager.swift に os/OSLog の import が必要です"
        )
    }

    @Test func stickerLibraryViewがLoggerを使用している() throws {
        let content = try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
        #expect(
            content.contains("import os") || content.contains("import OSLog"),
            "StickerLibraryView.swift に os/OSLog の import が必要です"
        )
    }
}
