import Testing
import Foundation

/// BoardEditorView の binding(for:) メソッドの安全性テスト
/// Issue #135: fatalError をクラッシュしない安全な処理に置換
///
/// 注意: このテストはソースコードを文字列として読み込み、正規表現で解析する構造検証テストです。
/// BoardEditorView.swift のメソッド名・シグネチャ・コード構造が変更された場合、
/// テストが予期せず失敗する可能性があります。失敗時はまず対象コードの構造変更を確認し、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorBindingTests {

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

    private var editorContent: String {
        get throws {
            try readFile("StickerBoard/Views/Board/BoardEditorView.swift")
        }
    }

    private func extractBindingMethodBody() throws -> String {
        let content = try editorContent
        let pattern = #"func binding\(for placement:.*?\{[\s\S]*?^\s{4}\}"#
        let regex = try Regex(pattern).anchorsMatchLineEndings()
        let match = try #require(
            content.firstMatch(of: regex),
            "binding(for:) メソッドが見つかりません"
        )
        return String(content[match.range])
    }

    // MARK: - binding(for:) の安全性テスト

    @Test func bindingForにfatalErrorが含まれていない() throws {
        let methodText = try extractBindingMethodBody()
        #expect(
            !methodText.contains("fatalError"),
            "binding(for:) に fatalError が含まれています。安全な処理に置換してください"
        )
    }

    @Test func bindingForがconstantフォールバックを使用している() throws {
        let methodText = try extractBindingMethodBody()
        #expect(
            methodText.contains(".constant(placement)"),
            "binding(for:) に .constant(placement) フォールバックが必要です"
        )
    }

    @Test func bindingForがguardLetを使用している() throws {
        let methodText = try extractBindingMethodBody()
        #expect(
            methodText.contains("guard let"),
            "binding(for:) に guard let パターンが含まれていません"
        )
    }
}
