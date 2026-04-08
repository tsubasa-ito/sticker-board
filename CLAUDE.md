# シールボード - 開発ガイド

## プロジェクト概要
リアルシールを撮影してデジタルコレクションするiOSアプリ。

## 技術スタック
- Swift / SwiftUI / iOS 18+
- Vision Framework（背景除去: VNGenerateForegroundInstanceMaskRequest）
- SwiftData（ローカルDB）
- StoreKit 2（自動更新サブスクリプション）
- WidgetKit + AppIntentConfiguration（ボードショーケースウィジェット）
- XcodeGen（project.yml からプロジェクト生成）

## プロジェクト構成
```
StickerBoard/
├── App/          # エントリーポイント（MainTabView）、カラーテーマ、外部URL定数
├── Models/       # SwiftData モデル（Sticker, Board, StickerPlacement, BackgroundPattern, StickerFilter, StickerBorder, SubscriptionProduct）
├── Services/     # BackgroundRemover, MaskCompositor, ImageStorage, BackgroundImageStorage, ImageCacheManager, StickerFilterService, StickerBorderService, SubscriptionManager, MotionManager, AppUpdateChecker, WidgetDataSyncService, ReviewRequestManager
└── Views/        # SwiftUI画面
    ├── Home/     # MainTabView（タブナビゲーション）、HomeView（ボード一覧カルーセル）
    ├── Onboarding/ # 初回起動オンボーディング（3ページガイド）
    ├── Capture/  # シール撮影・切り抜きフロー・マスク手動編集
    ├── Library/  # シールライブラリ
    ├── Paywall/  # ペイウォール（Pro課金導線）
    ├── Settings/ # 設定画面（サブスクリプション管理）
    └── Board/    # ボード編集・一覧
Shared/             # メインアプリ・ウィジェット間の共有コード（SharedBoardMetadata, SharedWidgetConstants）
StickerBoardWidget/ # Widget Extension（ボードショーケースウィジェット）
StickerBoardTests/  # Swift Testing によるユニットテスト
```

## ブランチ運用
- **main**: 本番リリース用。直接コミットしない
- **develop**: 開発統合ブランチ。機能開発・バグ修正はここにマージする
- **feature/\*、fix/\***: develop から切って develop へマージする
- リリース時に develop → main へマージしてデプロイ
- PRのベースブランチはデフォルトで **develop** を使用する

## 開発コマンド
```bash
# プロジェクト生成（project.yml 変更時に必要）
xcodegen generate

# ビルド
xcodebuild -project StickerBoard.xcodeproj -target StickerBoard -sdk iphonesimulator26.2 -arch arm64 build

# テスト実行（Swift Testing）※シミュレータ名は環境に合わせて変更
xcodebuild -project StickerBoard.xcodeproj -scheme StickerBoard -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Xcodeで開く
open StickerBoard.xcodeproj
```

> **注意（Xcode 26 beta）:** Swift Testing の `@Test func` の関数名を数字（`0`〜`9`）で始めると `build-for-testing` がクラッシュする。関数名は必ず文字またはアンダースコアで始めること（例: `180度...` → `百八十度...` or `回転後...`）

## 注意事項
- Vision Frameworkの背景除去はシミュレータでは動作しない（実機のみ）
- シミュレータではフォールバックとして元画像をそのまま返す
- シール画像は Documents/Stickers/ にPNG保存、メタデータはSwiftDataに保存
- ボード背景画像は Documents/Backgrounds/ にJPEG保存（長辺2048px、品質0.85）。BackgroundPatternConfig の customImageFileName でファイル名を管理。customImageCropX / customImageCropY（0.0〜1.0）でトリミング位置を保持
- AppTheme.screenBounds で画面サイズを取得する（UIScreen.main は deprecated のため UIWindowScene 経由）
- StickerPlacement に imageFileName を直接保持する設計（SwiftDataのID問題回避のため）
- Board の backgroundPatternData も placements と同様に Codable struct を JSON シリアライズして Data? に格納する設計
- BackgroundRemover は入力画像の EXIF 向きを正規化し、長辺2048pxにリサイズする（cgImage とマスクの整合性確保 + メモリ最適化）
- BackgroundRemover.removeBackgroundAtPoint(from:normalizedPoint:) は、VNInstanceMaskObservation の instanceMask ピクセルバッファからタップ位置のインスタンスIDを特定し、その被写体のみを切り抜く。StickerCaptureView で写真プレビューの長押しジェスチャーから呼び出される
- フィルター（キラキラ・レトロ・パステル・ネオン・ぷっくり・ワッペン）は StickerPlacement の filterType に保存し、ボード配置単位で適用する設計（シール自体ではなく配置ごとにフィルターが異なる）
- StickerFilterService は CIFilter ベースでオンザフライ処理。BoardEditorView ではフィルター適用画像をキャッシュして body 再評価時の再計算を回避
- ImageCacheManager（NSCache ベース）がフル解像度・サムネイル・フィルター適用済みの3層キャッシュを管理。メモリ警告時に自動パージ
- ImageStorage.save() は保存時にアルファトリミング（透明余白の除去）→ 長辺1024pxリサイズの順で処理する（バウンディングボックスの最適化 + ステッカー用途のサイズ最適化）
- ImageStorage.rotateAndOverwrite(fileName:clockwise:) はディスクからの読み込み → UIImage.rotatedBy90Degrees(clockwise:) で90度回転 → overwrite() の順で処理する。回転メソッドは ImageCacheManager.swift の UIImage 拡張に定義。UIGraphicsImageRendererFormat.scale に元画像のスケールを引き継がないとピクセル寸法が変わるため注意
- ImageStorageError には encodingFailed / deletionFailed / loadFailed の3ケースあり。loadFailed は rotateAndOverwrite で対象ファイルが見つからない場合に投げる
- StickerLibraryView は @Query ではなく FetchDescriptor + fetchLimit/fetchOffset によるページネーション（30枚ずつ無限スクロール）でシールを取得する設計（大量シール時のメモリ最適化）
- サムネイル表示（StickerThumbnailView, QuickPickThumbnail, BoardStickerPreviewView）は ImageStorage.loadThumbnail() 経由で縮小画像を使用
- 枠線（ボーダー）は StickerPlacement の borderWidthType / borderColorHex に保存し、フィルターと同様に配置単位で管理する設計
- StickerBorderService は CIMorphologyMaximum でアルファマスクを膨張させて輪郭に沿った枠線を描画。フィルター適用後の画像に枠線を重ねる（描画順序: フィルター → 枠線）
- ImageCacheManager の processed() メソッドがフィルター＋枠線の統合キャッシュを管理。キーは「fileName_filterType_borderWidth_borderColorHex」形式
- ホログラフィック効果（HolographicEffectModifier）はリアルタイムのビューレベル効果であり、フィルター/ボーダーのような画像処理とは独立。CoreMotion のジャイロスコープ（MotionManager シングルトン）でデバイスの傾きに連動した3D回転・レインボーグラデーション・スペキュラハイライトを表示。シミュレータではフォールバックとして自動アニメーションを使用。`@Environment(\.accessibilityReduceMotion)` で「視差効果を減らす」設定時は3D回転・自動アニメーションを無効化し静的表示にフォールバック（WCAG 2.3.3準拠）
- StickerBoardApp.init() で初回起動時（ボード0件）にデフォルトボード「はじめてのボード」を自動作成する
- @AppStorage("hasCompletedOnboarding") で初回起動オンボーディングの表示制御。初回は .fullScreenCover で OnboardingView を表示し、完了後は非表示。HomeView のナビバー「?」ボタンから再表示可能
- UIデザインルールは `.claude/rules/ui-design.md` を参照
- サブスクリプション（StoreKit 2）: SubscriptionManager がシングルトンで購入状態を管理。StickerBoardApp.init() で早期初期化。UserDefaults に isProUser をキャッシュしてオフライン対応
- フリーミアムモデル: 無料（シール30枚/ボード1枚/枠線なし・細/背景3種/ロゴ入り書き出し）、Pro（全制限解除）。「期待値駆動型ペイウォール」でプレミアム機能をプレビュー可能にし、適用・確定時にペイウォール表示
- Products.storekit は Xcode の StoreKit Configuration Editor で編集すること（手動JSONは非推奨）。project.yml の schemes で StoreKit Configuration を自動設定済み
- バージョン管理: MARKETING_VERSION / CURRENT_PROJECT_VERSION は project.yml の settings.base で管理。Info.plist では `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` で参照する（project.yml の info.properties で指定済み）。Info.plist にバージョンを直接ハードコードしない
- バンドルID: com.tebasaki.StickerBoard（project.yml で設定）
- アプリ表示名: シールボード -デジタルシール帳-（CFBundleDisplayName）
- ITSAppUsesNonExemptEncryption: NO（標準HTTPS通信のみ、App Store提出時の暗号化質問を省略）
- 画面の向き: iPhone はポートレートのみ、iPad は全方向（iPad互換モードのマルチタスク対応に必要）
- Xcode Cloud: mainブランチへのpushで自動ビルド→TestFlight配信。ci_scripts/ci_post_clone.sh で XcodeGen インストール＆プロジェクト生成を自動化
- GitHub Actions: develop→mainのRelease PR自動作成（.github/workflows/auto-release-pr.yml）、mainマージ時にバージョンタグ＆GitHub Release自動作成（.github/workflows/auto-tag-release.yml）
- WidgetKit: App Group（`group.com.tebasaki.StickerBoard`）でメインアプリ⇔ウィジェット間のデータ共有。スナップショット画像（JPEG）とメタデータJSON（`boards_meta.json`）を `AppGroup/WidgetData/` に保存。ボード保存時に `WidgetDataSyncService.syncBoard()` → `WidgetCenter.reloadTimelines()` で自動更新
- ディープリンク: `stickerboard://board/{boardId}` でウィジェットタップ → ボード編集画面に直接遷移。StickerBoardApp の `.onOpenURL` でハンドリング
- `Shared/` ディレクトリのファイルはメインアプリ・ウィジェット両ターゲットに含まれる（project.yml の sources で指定）。共有型や定数はここに配置する
- Widget Extension（`StickerBoardWidgetExtension`）は `AppIntentConfiguration` でボード選択。`BoardEntity` が `AppEntity` として機能する
- AppUpdateChecker（Sendable シングルトン）がアプリ起動時に iTunes Lookup API でバージョンチェック。MainTabView の .task で呼び出し、24時間間隔で実行（@AppStorage("lastUpdateCheckDate")）。メジャーアップデートはスキップ不可（毎回表示）、マイナー/パッチは「あとで」でスキップ可能（@AppStorage("skippedVersion")）。ネットワークエラー時はサイレントにスキップし次回起動でリトライ
- ReviewRequestManager（Sendable シングルトン）がアプリ内レビュー訴求を管理。`@Environment(\.requestReview)` による iOS 標準ダイアログのみ使用（カスタムUIなし・Appleガイドライン準拠）。トリガー条件: シール5/15/30枚目（`StickerCaptureView` sheet の onDismiss で呼び出し）、ボード新規作成時（alert dismiss 後 Task.sleep 600ms）、起動5回目（StickerBoardApp.init() で UserDefaults の "appLaunchCount" をインクリメント）。表示制御は 90日クールダウン＋365日ローリングウィンドウで年3回上限（@AppStorage("reviewRequestDatesJSON") に JSON 配列で最大3件の日時を保存）
