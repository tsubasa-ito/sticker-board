# シールボード - 開発ガイド

## プロジェクト概要
リアルシールを撮影してデジタルコレクションするiOSアプリ。

## 技術スタック
- Swift / SwiftUI / iOS 18+
- Vision Framework（背景除去: VNGenerateForegroundInstanceMaskRequest）
- SwiftData（ローカルDB + CloudKit連携によるiCloud同期）
- StoreKit 2（自動更新サブスクリプション）
- XcodeGen（project.yml からプロジェクト生成）

## プロジェクト構成
```
StickerBoard/
├── App/          # エントリーポイント（MainTabView）、カラーテーマ、外部URL定数
├── Models/       # SwiftData モデル（Sticker, Board, StickerPlacement, BackgroundPattern, StickerFilter, StickerBorder, SubscriptionProduct）
├── Services/     # BackgroundRemover, MaskCompositor, ImageStorage, BackgroundImageStorage, ImageCacheManager, StickerFilterService, StickerBorderService, SubscriptionManager, MotionManager, ICloudSyncManager, ImageSyncService
└── Views/        # SwiftUI画面
    ├── Home/     # MainTabView（タブナビゲーション）、HomeView（ボード一覧カルーセル）
    ├── Onboarding/ # 初回起動オンボーディング（3ページガイド）
    ├── Capture/  # シール撮影・切り抜きフロー・マスク手動編集
    ├── Library/  # シールライブラリ
    ├── Paywall/  # ペイウォール（Pro課金導線）
    ├── Settings/ # 設定画面（サブスクリプション管理・iCloudバックアップ）
    └── Board/    # ボード編集・一覧
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

## 注意事項
- Vision Frameworkの背景除去はシミュレータでは動作しない（実機のみ）
- シミュレータではフォールバックとして元画像をそのまま返す
- シール画像は Documents/Stickers/ にPNG保存、メタデータはSwiftDataに保存
- ボード背景画像は Documents/Backgrounds/ にJPEG保存（長辺2048px、品質0.85）。BackgroundPatternConfig の customImageFileName でファイル名を管理。customImageCropX / customImageCropY（0.0〜1.0）でトリミング位置を保持
- AppTheme.screenBounds で画面サイズを取得する（UIScreen.main は deprecated のため UIWindowScene 経由）
- StickerPlacement に imageFileName を直接保持する設計（SwiftDataのID問題回避のため）
- Board の backgroundPatternData も placements と同様に Codable struct を JSON シリアライズして Data? に格納する設計
- BackgroundRemover は入力画像の EXIF 向きを正規化し、長辺2048pxにリサイズする（cgImage とマスクの整合性確保 + メモリ最適化）
- フィルター（キラキラ・レトロ・パステル・ネオン・ぷっくり・ワッペン）は StickerPlacement の filterType に保存し、ボード配置単位で適用する設計（シール自体ではなく配置ごとにフィルターが異なる）
- StickerFilterService は CIFilter ベースでオンザフライ処理。BoardEditorView ではフィルター適用画像をキャッシュして body 再評価時の再計算を回避
- ImageCacheManager（NSCache ベース）がフル解像度・サムネイル・フィルター適用済みの3層キャッシュを管理。メモリ警告時に自動パージ
- ImageStorage.save() は保存時にアルファトリミング（透明余白の除去）→ 長辺1024pxリサイズの順で処理する（バウンディングボックスの最適化 + ステッカー用途のサイズ最適化）
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
- バンドルID: com.tebasaki.StickerBoard（project.yml で設定）
- アプリ表示名: シールボード -デジタルシール帳-（CFBundleDisplayName）
- ITSAppUsesNonExemptEncryption: NO（標準HTTPS通信のみ、App Store提出時の暗号化質問を省略）
- 画面の向き: iPhone はポートレートのみ、iPad は全方向（iPad互換モードのマルチタスク対応に必要）
- Xcode Cloud: mainブランチへのpushで自動ビルド→TestFlight配信。ci_scripts/ci_post_clone.sh で XcodeGen インストール＆プロジェクト生成を自動化
- GitHub Actions: develop→mainのRelease PR自動作成（.github/workflows/auto-release-pr.yml）、mainマージ時にバージョンタグ＆GitHub Release自動作成（.github/workflows/auto-tag-release.yml）
- iCloudバックアップ（Pro限定）: ICloudSyncManager がシングルトンで同期状態を管理。StickerBoardApp.init() で早期初期化。SubscriptionStatusProviding / CloudContainerProviding / ImageSyncServiceProtocol のプロトコル抽象化でテスタブル設計
- SwiftData モデル（Sticker, Board）は CloudKit 互換のため全属性にデフォルト値を設定。CloudKit 連携は Entitlements（iCloud.com.tebasaki.StickerBoard）で自動有効化
- 画像ファイルの同期: ImageSyncService が Documents/Stickers/ と Documents/Backgrounds/ をiCloud Drive コンテナと双方向同期（ファイル名ベースの差分検出）
- iCloud Entitlements は project.yml の entitlements.properties で管理（xcodegen generate 時に自動生成）
