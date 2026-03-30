# ルール: View修正時のVoiceOverアクセシビリティチェック

## トリガー条件
SwiftUI の View ファイル（`Views/` 配下の `.swift` ファイル）を新規作成または修正したとき。

## ルール

修正されたViewファイルを確認し、以下のチェック項目に沿ってVoiceOver対応状況をチェックする。

### チェック項目

1. **画像**: 情報を持つ `Image(systemName:)` に `.accessibilityLabel()` が設定されているか。装飾目的の `Image` には `.accessibilityHidden(true)` が設定されているか
2. **インタラクティブ要素**: `Button`、タップジェスチャー（`onTapGesture`）等にアクセシブルなラベルがあるか
3. **動的コンテンツ**: 動的に変化するコンテンツに適切な通知（`.accessibilityValue` / `UIAccessibility.post`）があるか
4. **カスタムジェスチャー代替**: ドラッグ、ピンチ、回転等のカスタムジェスチャーに `.accessibilityAction` の代替操作があるか
5. **選択状態**: 選択状態を持つ要素に `.accessibilityAddTraits(.isSelected)` があるか
6. **装飾的要素の非表示**: 装飾目的のみの要素（背景画像、区切り線等）に `.accessibilityHidden(true)` があるか
7. **コントロール値**: スライダー等の値を持つコントロールに `.accessibilityValue` が設定されているか

### 対応フロー

1. 修正されたViewファイルを確認する
2. 上記チェック項目に沿ってVoiceOver対応状況を確認する
3. 未対応箇所があればユーザーに報告し、修正を提案する
4. **重大な未対応**（ラベルなしのボタン、操作不能なカスタムジェスチャー等）は修正必須として強調する

### 重大度の判定基準

| 重大度 | 内容 | 対応 |
|--------|------|------|
| **高** | ラベルなしのボタン・操作要素、代替なしのカスタムジェスチャー | 修正必須 |
| **中** | `Image(systemName:)` のラベル未設定、選択状態の未通知 | 修正推奨 |
| **低** | 装飾要素の `.accessibilityHidden` 未設定 | 改善提案 |

## 既存ルールとの連携
- `post-commit-review.md` と同様に、コミット後のレビューフローに組み込む
- `ui-design.md` のUIデザインルールと並行してチェックする

## 対象外
- `Views/` 配下以外の `.swift` ファイル（Models, Services 等）は対象外
- VoiceOver対応がそもそも不要な画面（例: 純粋なプレビュー表示のみ）は例外として許容
