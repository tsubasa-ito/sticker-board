# ルール: UI/デザインルール

## トリガー条件
SwiftUI の View を新規作成・修正するとき。

## ルール

### カラー
- 全色 `AppTheme` に定義された定数を使用する。`Color(hex:)` の直指定は禁止
- カラーパレット: ネイビー(`#2A2D5B`) × オレンジ(`#E87A2E`) × クリーム(`#FAF0DE`)

### グラデーション
- UIデザインに `LinearGradient` は使用しない。すべてフラットカラーで統一
- ただしボード背景パターンの「グラデーション」オプション、およびホログラフィック効果（HolographicEffectModifier）のレインボースウィープは視覚エフェクト機能として提供しているため例外

### ナビゲーションバー
- 全画面で iOS 標準ナビゲーションバー（`.navigationTitle` + `.inline`）を使用する。カスタムトップバーは作らない（BoardEditorView / MaskEditorView 含む）
- `StickerBoardApp.init()` でグローバル `UINavigationBar.appearance()` を設定済み。各画面で個別に `toolbarBackground` を指定しない

### カードスタイル
- 角丸16pt + 薄い影（`.stickerCard()` / `.glassCard()` modifier を使用）
- 選択状態を持つカード（プランカード等）は `.selectableCard(isSelected:)` modifier を使用（`AppTheme.swift` に定義）

### CTAボタン
- アクセントカラーの主要ボタン（設定画面のプラン管理・アップグレード等）は `.primaryButton()` modifier を使用（`AppTheme.swift` に定義）
- Capsule形のCTAボタン（ペイウォール・オンボーディング等）は `.background(AppTheme.accent, in: Capsule())` + `.shadow(color: AppTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)` で統一
