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

    // MARK: - ファイル読み込みヘルパー

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

    // MARK: - binding(for:) の安全性テスト

    @Test func bindingForメソッドにfatalErrorが含まれていない() throws {
        let content = try editorContent

        // binding(for:) メソッドの範囲を抽出
        let bindingMethodPattern = #"func binding\(for placement:.*?\{[\s\S]*?^\s{4}\}"#
        let regex = try Regex(bindingMethodPattern).anchorsMatchLineEndings()
        let match = content.firstMatch(of: regex)

        #expect(match != nil, "binding(for:) メソッドが見つかりません")

        if let methodBody = match {
            let methodText = String(content[methodBody.range])
            #expect(
                !methodText.contains("fatalError"),
                "binding(for:) に fatalError が含まれています。クラッシュの原因となるため安全な処理に置換してください"
            )
        }
    }

    @Test func bindingForメソッドがconstantフォールバックを使用している() throws {
        let content = try editorContent

        // binding(for:) メソッドの範囲を抽出
        let bindingMethodPattern = #"func binding\(for placement:.*?\{[\s\S]*?^\s{4}\}"#
        let regex = try Regex(bindingMethodPattern).anchorsMatchLineEndings()
        let match = content.firstMatch(of: regex)

        #expect(match != nil, "binding(for:) メソッドが見つかりません")

        if let methodBody = match {
            let methodText = String(content[methodBody.range])
            #expect(
                methodText.contains(".constant(placement)"),
                "binding(for:) に .constant(placement) フォールバックが含まれていません。Placement未検出時の安全なハンドリングが必要です"
            )
        }
    }

    @Test func bindingForメソッドがguardLetを使用している() throws {
        let content = try editorContent

        // binding(for:) メソッドの範囲を抽出
        let bindingMethodPattern = #"func binding\(for placement:.*?\{[\s\S]*?^\s{4}\}"#
        let regex = try Regex(bindingMethodPattern).anchorsMatchLineEndings()
        let match = content.firstMatch(of: regex)

        #expect(match != nil, "binding(for:) メソッドが見つかりません")

        if let methodBody = match {
            let methodText = String(content[methodBody.range])
            #expect(
                methodText.contains("guard let") || methodText.contains("guard let index"),
                "binding(for:) に guard let パターンが含まれていません"
            )
        }
    }
}
