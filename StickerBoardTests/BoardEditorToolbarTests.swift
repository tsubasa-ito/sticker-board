import Testing
import Foundation

/// ボード編集画面のフローティングツールバー改善テスト
/// Issue #127: ツールバーボタンが小さすぎる問題の改善
///
/// 注意: このテストはソースコードを文字列として読み込み、正規表現で解析する構造検証テストです。
/// BoardEditorView.swift のメソッド名・シグネチャ・コード構造が変更された場合、
/// テストが予期せず失敗する可能性があります。失敗時はまず対象コードの構造変更を確認し、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorToolbarTests {

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

    // MARK: - スクロール可能ツールバー

    @Test func floatingToolbar_ScrollViewで横スクロール可能() throws {
        let content = try editorContent
        // ツールバーがScrollView(.horizontal)でラップされている
        #expect(content.contains("ScrollView(.horizontal"))
    }

    // MARK: - ボタンサイズ

    @Test func toolbarButton_アイコンサイズが22pt以上() throws {
        let content = try editorContent
        // toolbarButton メソッド定義を抽出
        let toolbarButtonRange = try #require(content.range(of: "private func toolbarButton"))
        let methodEnd = try #require(content[toolbarButtonRange.lowerBound...].range(of: ".accessibilityLabel"))
        let methodBody = String(content[toolbarButtonRange.lowerBound..<methodEnd.upperBound])

        let iconSizePattern = #/\.font\(\.system\(size:\s*(\d+)\)\)/#
        let match = methodBody.firstMatch(of: iconSizePattern)
        #expect(match != nil, "アイコンサイズの指定が見つかりません")
        if let match = match {
            let size = try #require(Int(match.1))
            #expect(size >= 22, "アイコンサイズが22pt未満です: \(size)pt")
        }
    }

    @Test func toolbarButton_ラベルフォントが10pt以上() throws {
        let content = try editorContent
        // toolbarButton メソッド定義を抽出
        let toolbarButtonRange = try #require(content.range(of: "private func toolbarButton"))
        let methodEnd = try #require(content[toolbarButtonRange.lowerBound...].range(of: ".accessibilityLabel"))
        let methodBody = String(content[toolbarButtonRange.lowerBound..<methodEnd.upperBound])

        let labelSizePattern = #/\.font\(\.system\(size:\s*(\d+),\s*weight:/#
        let match = methodBody.firstMatch(of: labelSizePattern)
        #expect(match != nil, "ラベルフォントサイズの指定が見つかりません")
        if let match = match {
            let size = try #require(Int(match.1))
            #expect(size >= 10, "ラベルフォントサイズが10pt未満です: \(size)pt")
        }
    }

    // MARK: - タップターゲット

    @Test func toolbarButton_最小タップターゲット44pt確保() throws {
        let content = try editorContent
        // toolbarButton メソッド定義を抽出
        let toolbarButtonRange = try #require(content.range(of: "private func toolbarButton"))
        let methodEnd = try #require(content[toolbarButtonRange.lowerBound...].range(of: ".accessibilityLabel"))
        let methodBody = String(content[toolbarButtonRange.lowerBound..<methodEnd.upperBound])

        // minWidth: 44 または frame(minWidth: 44) でタップターゲット確保
        #expect(methodBody.contains("minWidth: 44") || methodBody.contains("minHeight: 44"),
                "44ptの最小タップターゲットが設定されていません")
    }

    // MARK: - グループ化の廃止

    @Test func floatingToolbar_toolbarGroupが使用されていない() throws {
        let content = try editorContent
        // floatingToolbar 内で toolbarGroup を使用していないこと
        // （スクロール化に伴いグループ化は不要）
        let toolbarRange = try #require(content.range(of: "private var floatingToolbar"))
        // floatingToolbar の終端（次の private まで）
        let afterToolbar = content[toolbarRange.lowerBound...]
        let nextPrivateRange = try #require(afterToolbar.range(of: "\n    private func toolbarButton"))
        let toolbarBody = String(afterToolbar[..<nextPrivateRange.lowerBound])

        #expect(!toolbarBody.contains("toolbarGroup"),
                "スクロールツールバーではtoolbarGroupは不要です")
    }

    // MARK: - minimumScaleFactorの廃止

    @Test func toolbarButton_minimumScaleFactorが使用されていない() throws {
        let content = try editorContent
        // toolbarButton メソッド内で minimumScaleFactor が使われていないこと
        let toolbarButtonRange = try #require(content.range(of: "private func toolbarButton"))
        let methodEnd = try #require(content[toolbarButtonRange.lowerBound...].range(of: ".accessibilityLabel"))
        let methodBody = String(content[toolbarButtonRange.lowerBound..<methodEnd.upperBound])

        #expect(!methodBody.contains("minimumScaleFactor"),
                "スクロールツールバーではminimumScaleFactorは不要です")
    }

    // MARK: - アクセシビリティ

    @Test func toolbarButton_accessibilityLabelが設定されている() throws {
        let content = try editorContent
        let toolbarButtonRange = try #require(content.range(of: "private func toolbarButton"))
        let methodEnd = try #require(content[toolbarButtonRange.lowerBound...].range(of: ".accessibilityLabel"))
        let methodBody = String(content[toolbarButtonRange.lowerBound...methodEnd.upperBound])

        #expect(methodBody.contains("accessibilityLabel"),
                "ツールバーボタンにaccessibilityLabelが設定されていません")
    }
}
