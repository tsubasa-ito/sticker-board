# シールボード

**リアルシールをデジタルコレクション**

現実のシールを撮影して背景を自動で切り抜き、デジタルなシールボードに自由に配置できる iOS アプリです。

子どもの頃にシール手帳に夢中になった世代が、大人になった今もシール集めの楽しさをスマホで体験できます。

## 機能

- **撮影ガイド** — シール追加画面にきれいに切り抜くための撮影のコツを表示（折りたたみ可能、状態を記憶）
- **シール切り抜き** — カメラで撮影またはカメラロールから写真を選び、Vision Framework の AI が背景を自動除去
- **被写体の長押し選択** — 写真内のシールにしたい被写体を長押しで直接選択して切り抜き（複数被写体がある写真で特定の1つだけを選びたい場合に便利）
- **マスク手動調整** — 自動切り抜き後にブラシツールで手動微調整（消しゴム/復元モード、ブラシサイズ変更、Undo、ピンチズーム対応）
- **複数シール一括検出** — 1枚の画像に複数のシールが写っている場合、個別に検出・選択して一括追加
- **シールライブラリ** — 切り抜いたシールをコレクションとして一覧管理、長押しメニューから不要部分の再除去・向きの回転（左/右90度）が可能
- **カルーセル型ボード一覧** — ホーム画面でボードをカルーセル形式で大きく表示、シール配置のプレビュー付き（初回起動時にデフォルトボードを自動作成）
- **タブナビゲーション** — フローティングタブバーでホーム・撮影・ライブラリを切り替え
- **ボードエディタ** — シールをボード上にドラッグ・ピンチ・回転で自由に配置、タップで選択してレイヤー操作・削除
- **シールフィルター加工** — ボード上のシールにキラキラ（ホログラム風）・レトロ・パステル・ネオン・ぷっくり（立体エフェクト）・ワッペン（刺繍風）の6種フィルターを適用可能、ボードごとに異なるフィルターを設定できる
- **シール枠線（ボーダー）** — シールの輪郭に沿った枠線を追加可能。太さ4段階（なし/細/中/太）× 9色のカラープリセット対応、フィルターとの併用も可能
- **背景パターン選択** — 無地・ドット・グリッド・ストライプ・グラデーションの5種類から背景を選択、カラーカスタマイズ対応。Pro限定でカスタム写真を背景に設定可能（ドラッグで表示位置を調整）
- **折りたたみ式ツールバー** — ボード編集時のフローティングツールバーは折りたたみ可能、キャンバス全域にアクセス
- **ボード画像保存** — 完成したボードを一枚の画像として写真ライブラリに保存（背景パターン込み）
- **初回オンボーディング** — 初回起動時に3ページのガイドでアプリの使い方を紹介（スキップ可能、ホーム画面の「?」ボタンから再表示可能）
- **ローカル保存** — シールとボードのデータを端末内に永続保存
- **Pro サブスクリプション** — フリーミアムモデル（無料: シール30枚・ボード1枚・基本枠線・基本背景 / Pro: 無制限・全機能・ロゴなし書き出し）。StoreKit 2 による月額¥380 / 年額¥2,900
- **アップデート通知** — アプリ起動時にApp Storeの最新バージョンをチェックし、アップデートがある場合にアラートで通知（24時間間隔、メジャー/マイナー区別、スキップ管理）
- **アプリ内レビュー訴求** — 達成感のあるタイミング（シール5/15/30枚目、ボード新規作成、起動5回目）でApple標準のレビューダイアログを表示。90日クールダウン＋365日ローリングウィンドウで年3回上限（Appleガイドライン準拠）
- **設定画面** — 現在のプラン表示・有効期限確認・月額/年額プラン選択＆直接購入・プラン管理（Pro→App Storeサブスクリプション管理）・購入復元・Proメリット一覧・よくある質問・注意事項・関連リンク
- **ボードショーケースウィジェット** — WidgetKit でお気に入りのボードをホーム画面に飾れるウィジェット機能（Medium / Large サイズ対応）。ウィジェット長押しでボード選択、タップでボード編集画面に直接遷移（完全無料）

## 技術スタック

| 項目 | 技術 |
|------|------|
| 言語 | Swift |
| UI | SwiftUI |
| 背景除去 | Vision Framework（VNGenerateForegroundInstanceMaskRequest） |
| データ保存 | SwiftData + FileManager |
| 課金 | StoreKit 2（自動更新サブスクリプション） |
| ウィジェット | WidgetKit + AppIntentConfiguration |
| クラッシュ検知 | Firebase Crashlytics |
| プロジェクト管理 | XcodeGen |
| 対応OS | iOS 18+ |

## セットアップ

### 必要な環境

- macOS + Xcode（iOS SDK 含む）
- [Homebrew](https://brew.sh)

### 手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/tsubasa-ito/sticker-board.git
cd sticker-board

# 2. XcodeGen をインストール（未インストールの場合）
brew install xcodegen

# 3. Xcode プロジェクトを生成
xcodegen generate

# 4. Xcode で開く
open StickerBoard.xcodeproj
```

Xcode が開いたら、Signing & Capabilities で自分の Apple ID（Team）を設定してください。

> **Firebase Crashlytics の設定:** クラッシュ検知を有効にするには、[Firebase コンソール](https://console.firebase.google.com/) でプロジェクトを作成し、`GoogleService-Info.plist` を `StickerBoard/` 直下に配置してください（このファイルは `.gitignore` で除外されています）。詳細は [`docs/MCP_CRASHLYTICS.md`](docs/MCP_CRASHLYTICS.md) を参照。

## 動作確認の方法

### シミュレータで確認する場合

1. Xcode 上部の実行先から **iPhone シミュレータ** を選択
2. `Cmd + R` で実行
3. テスト用の画像を Mac からシミュレータの画面に **ドラッグ＆ドロップ** すると写真アプリに追加される

> **注意:** シミュレータでは背景除去（Vision Framework）が動作しません。元画像がそのまま保存されます。シール切り抜きの品質確認には実機を使ってください。

### 実機（iPhone）で確認する場合（推奨）

1. iPhone を USB ケーブルで Mac に接続
2. iPhone 上で「このコンピュータを信頼しますか？」→ **信頼** をタップ
3. Xcode 上部の実行先から **接続した iPhone** を選択
4. `Cmd + R` で実行
5. 初回のみ、iPhone の **設定 → 一般 → VPN とデバイス管理** から開発者を信頼する設定が必要

> 背景除去の精度は実機でのみ確認できます。特にシール切り抜き周りの動作確認は実機で行ってください。

### 確認すべきポイント

| 機能 | 確認内容 |
|------|---------|
| オンボーディング | 初回起動でオンボーディングが表示される → スワイプ or「次へ」で3ページ閲覧 →「はじめる」or「スキップ」でホーム画面へ → 2回目以降は非表示 → ホーム画面「?」ボタンで再表示可能 |
| シール追加 | 撮影ガイドが表示される（折りたたみ可能）→ カメラ撮影または写真選択 → 背景除去 → 「手動で調整する」で微調整可能 → ライブラリに保存 |
| 複数シール検出 | 複数シールが写った画像 → 個別に検出 → 選択UI → 一括保存 |
| ライブラリ | 保存したシールが最新順のグリッドで表示される・先頭の「さらに追加」カードからシール追加可能・タップでプレビュー拡大・長押しで「不要部分を除去」（マスク再編集）・左/右に90度回転・削除ができる |
| ボード作成 | 新規ボードを作成 → ボード一覧に表示される |
| フィルター加工 | ボード編集画面でシール選択 → 「効果」ボタン → オリジナル含む7種から選択 → シールに適用 |
| 枠線（ボーダー） | ボード編集画面でシール選択 → 「枠線」ボタン → 太さ4段階・9色から選択 → シールの輪郭に枠線を追加 |
| 背景パターン | ボード編集画面で背景ボタン → 5種類のパターンから選択 → カラーカスタマイズ可能 → Pro限定で写真を背景に設定可能 |
| シール配置 | ボード上でシールをドラッグ移動・ピンチで拡大縮小・2本指で回転 |
| シール選択・操作 | シールをタップで選択 → 下部ツールバーの「前面へ」「背面へ」「削除」で操作 |
| ボード画像保存 | ボード編集画面のダウンロードボタン → 写真ライブラリに画像として保存される |
| データ永続化 | アプリを終了→再起動してシール・ボードが残っている |
| ウィジェット | ホーム画面にウィジェットを追加 → ボードを選択 → スナップショット表示 → タップでボード編集画面に遷移 |

### コマンドラインでのビルド確認

```bash
# シミュレータ向けビルド（CIなどで利用）
xcodebuild -project StickerBoard.xcodeproj \
  -target StickerBoard \
  -sdk iphonesimulator \
  -arch arm64 \
  -quiet build

# ユニットテスト実行（Swift Testing）※シミュレータ名は環境に合わせて変更
xcodebuild -project StickerBoard.xcodeproj \
  -scheme StickerBoard \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

## プロジェクト構成

```
StickerBoard/
├── App/
│   ├── StickerBoardApp.swift        # エントリーポイント
│   ├── AppTheme.swift               # カラーテーマ・共通スタイル
│   └── AppURLs.swift                # 外部URL定数（利用規約・プライバシー・問い合わせ）
├── Models/
│   ├── Sticker.swift                # シールデータモデル
│   ├── Board.swift                  # ボードデータモデル
│   ├── StickerPlacement.swift       # ボード上のシール配置情報
│   ├── StickerFilter.swift          # フィルター種別（オリジナル・キラキラ・レトロ・パステル・ネオン・ぷっくり・ワッペン）
│   ├── StickerBorder.swift          # 枠線の太さ・カラープリセット定義
│   ├── BackgroundPattern.swift      # 背景パターン種別・設定
│   └── SubscriptionProduct.swift    # サブスクリプション商品ID定義
├── Services/
│   ├── BackgroundRemover.swift      # Vision Framework 背景除去
│   ├── MaskCompositor.swift         # マスク合成・手動編集結果の適用
│   ├── StickerFilterService.swift   # CIFilterベースのフィルター処理
│   ├── StickerBorderService.swift   # CIMorphologyMaximumベースの枠線描画
│   ├── ImageCacheManager.swift      # 3層キャッシュ管理（フル解像度・サムネイル・フィルター+枠線）
│   ├── ImageStorage.swift           # 画像ファイルの保存・読み込み
│   ├── BackgroundImageStorage.swift # ボード背景画像の保存・読み込み
│   ├── SubscriptionManager.swift    # StoreKit 2 サブスクリプション管理
│   ├── AppUpdateChecker.swift       # App Storeバージョンチェック・アップデート通知
│   └── WidgetDataSyncService.swift  # ウィジェットへのスナップショット・メタデータ同期
└── Views/
    ├── Home/
    │   ├── MainTabView.swift        # タブナビゲーション・フローティングタブバー
    │   └── HomeView.swift           # ボード一覧カルーセル
    ├── Onboarding/
    │   ├── OnboardingView.swift           # オンボーディング全体コンテナ
    │   ├── OnboardingPageView.swift       # 各ページ共通レイアウト
    │   └── OnboardingPageIndicator.swift  # カスタムドットインジケータ
    ├── Capture/
    │   ├── StickerCaptureView.swift        # 写真選択・背景除去
    │   ├── CaptureGuideTipsView.swift     # 撮影ガイド・推奨事項（折りたたみ可能）
    │   ├── CameraView.swift                # カメラ撮影
    │   ├── MaskEditorView.swift            # マスク手動編集画面
    │   ├── MaskDrawingCanvas.swift         # ブラシ描画キャンバス（UIKit）
    │   ├── BrushToolbar.swift              # ブラシツールバー
    │   ├── MultiStickerSelectionView.swift  # 複数シール選択
    │   ├── StickerPreviewView.swift        # 切り抜きプレビュー
    │   └── StickerFilterPickerView.swift   # フィルター選択UI（2カラムグリッド）
    ├── Paywall/
    │   └── PaywallView.swift         # ペイウォール・ProBadge
    ├── Library/
    │   └── StickerLibraryView.swift  # シール一覧
    └── Board/
        ├── BoardListView.swift              # ボード一覧
        ├── BoardEditorView.swift            # ボード編集キャンバス
        ├── StickerItemView.swift            # ドラッグ・ピンチ・回転操作
        ├── BoardBackgroundView.swift        # 背景パターン描画
        ├── BackgroundPatternPickerView.swift # 背景パターン選択UI
        └── StickerBorderPickerView.swift    # 枠線設定UI（太さ・カラー選択）
Shared/                                      # メインアプリ・ウィジェット間の共有コード
├── SharedBoardMetadata.swift                # ウィジェット共有用ボードメタデータ
└── SharedWidgetConstants.swift              # App Group ID・ディレクトリ名等の共有定数
StickerBoardWidget/                          # Widget Extension（ボードショーケースウィジェット）
├── StickerBoardWidgetBundle.swift           # ウィジェットバンドル
├── BoardShowcase/
│   ├── BoardShowcaseWidget.swift            # Widget定義 + TimelineProvider
│   ├── BoardShowcaseView.swift              # ウィジェットUI（Medium / Large）
│   └── BoardShowcaseIntent.swift            # ボード選択用 AppIntent
└── Shared/
    └── WidgetDataManager.swift              # App Groupからのデータ読み込み
StickerBoardTests/                           # Swift Testing ユニットテスト
    ├── BoardTests.swift                     # Board のJSON デコードキャッシュ・placements・backgroundPattern
    ├── StickerPlacementTests.swift          # StickerPlacement のCodable・computed properties
    ├── BackgroundPatternTests.swift         # 背景パターン種別・設定・Color hex変換
    ├── StickerFilterTests.swift             # フィルター種別のプロパティ・Codable
    ├── StickerBorderTests.swift             # 枠線太さ・カラープリセット
    ├── SubscriptionProductTests.swift       # サブスクリプション商品ID・表示名
    ├── StickerFilterServiceTests.swift      # フィルター適用の動作・サイズ維持
    ├── StickerBorderServiceTests.swift      # 枠線適用・カラーhex対応
    ├── ImageStorageTests.swift              # PNG保存・読み込み・削除・回転サイクル
    ├── BackgroundImageStorageTests.swift    # JPEG保存・読み込み・削除サイクル
    ├── ImageCacheManagerTests.swift         # 3層キャッシュの読み書き・メモリ警告パージ・並行アクセス安全性
    ├── UIImageExtensionTests.swift          # リサイズ・アルファトリミング・90度回転
    ├── MaskCompositorTests.swift            # マスク合成
    ├── BackgroundRemoverTests.swift         # 背景除去（removeBackgroundAtPoint・エラー・リサイズ）
    ├── AccessibilityRuleTests.swift         # アクセシビリティルールファイルの構造検証
    ├── CaptureAccessibilityTests.swift      # 撮影・マスク編集のVoiceOverアクセシビリティ
    ├── BoardEditorToolbarTests.swift            # ボード編集ツールバーのScrollView・ボタンサイズ・タップターゲット
    ├── BoardEditorBindingTests.swift            # BoardEditorViewのbinding(for:)の安全なフォールバック
    ├── BoardDeleteConfirmationTests.swift       # ボード削除前確認ダイアログの状態変数・アラート内容・即時削除なし検証
    ├── BoardAccessibilityTests.swift          # ボード一覧・背景パターンのVoiceOverアクセシビリティ
    ├── FilterBorderAccessibilityTests.swift   # フィルター・ボーダー選択のVoiceOverアクセシビリティ
    ├── SettingsAccessibilityTests.swift             # 設定画面のVoiceOverアクセシビリティ
    ├── PaywallAccessibilityTests.swift              # ペイウォール画面のVoiceOverアクセシビリティ
    ├── MultiStickerSelectionAccessibilityTests.swift # 複数シール選択画面のVoiceOverアクセシビリティ
    ├── OnboardingAccessibilityTests.swift           # オンボーディング・プレビュー画面のVoiceOverアクセシビリティ
    ├── HolographicAccessibilityTests.swift          # ホログラフィック効果のReduce Motion対応
    ├── StickerLibraryAccessibilityTests.swift       # シールライブラリのVoiceOverアクセシビリティ
    ├── AppUpdateCheckerTests.swift                  # バージョン比較・スキップ管理・チェック間隔
    ├── ReviewRequestManagerTests.swift              # レビュー訴求の表示判定・ローリングウィンドウ・マイルストーン
    ├── WidgetModelsTests.swift                      # SharedBoardMetadataのCodable・JSON往復
    └── WidgetDataSyncServiceTests.swift             # メタデータ生成・JSON読み書き・スナップショット・ディープリンク
```

## ブランチ戦略

| ブランチ | 用途 |
|---------|------|
| `main` | 本番リリース用（直接コミット禁止） |
| `develop` | 開発統合ブランチ |
| `feature/*` | 新機能開発（develop から切る） |
| `fix/*` | バグ修正（develop から切る） |

- 機能開発・バグ修正は `develop` ブランチへPRを出す
- リリース時に `develop` → `main` へマージしてデプロイ
- **CI**: develop へのマージ時に Release PR（develop → main）が自動作成される（GitHub Actions）

## ライセンス

Private
