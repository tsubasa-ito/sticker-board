# コードスタイル・規約

## 命名規約
- **型名**: PascalCase（例: `StickerPlacement`, `BackgroundRemover`）
- **変数・メソッド**: camelCase（例: `imageFileName`, `removeBackground(from:)`）
- **定数**: camelCase（staticプロパティとして定義）

## 構造パターン
- **SwiftDataモデル**: `@Model final class` + `var` プロパティ + `init`
- **値型サービス**: `struct` + `static` メソッド（インスタンス不要）
- **SwiftUIビュー**: `struct` conforming to `View`、computed properties で画面セクション分割
- **エラー型**: `enum XxxError: LocalizedError` + `errorDescription`

## コメント・整理
- `// MARK: -` でセクション区切り（日本語ラベル使用）
- `///` でドキュメントコメント（日本語）
- UIラベル・エラーメッセージは日本語

## SwiftUI パターン
- `@Query` でSwiftDataからデータ取得
- `@Environment(\.modelContext)` でコンテキスト注入
- `@State` でローカル状態管理
- ViewModifier拡張（`.stickerCard()`, `.glassCard()`）でスタイル共有
- `AppTheme` enum で色・グラデーション一元管理

## デザインテーマ
- 90年代シール手帳のノスタルジー × モダンUI
- パステルカラー基調（コーラルピンク、ラベンダー、ミント）
- Color hex拡張でカラー定義
