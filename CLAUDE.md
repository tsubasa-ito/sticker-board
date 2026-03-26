# シールボード - 開発ガイド

## プロジェクト概要
リアルシールを撮影してデジタルコレクションするiOSアプリ。

## 技術スタック
- Swift / SwiftUI / iOS 18+
- Vision Framework（背景除去: VNGenerateForegroundInstanceMaskRequest）
- SwiftData（ローカルDB）
- XcodeGen（project.yml からプロジェクト生成）

## プロジェクト構成
```
StickerBoard/
├── App/          # エントリーポイント（MainTabView）、カラーテーマ
├── Models/       # SwiftData モデル（Sticker, Board, StickerPlacement, BackgroundPattern, StickerFilter, StickerBorder）
├── Services/     # BackgroundRemover, MaskCompositor, ImageStorage, ImageCacheManager, StickerFilterService, StickerBorderService
└── Views/        # SwiftUI画面
    ├── Home/     # MainTabView（タブナビゲーション）、HomeView（ボード一覧カルーセル）
    ├── Capture/  # シール撮影・切り抜きフロー・マスク手動編集
    ├── Library/  # シールライブラリ
    └── Board/    # ボード編集・一覧
```

## 開発コマンド
```bash
# プロジェクト生成（project.yml 変更時に必要）
xcodegen generate

# ビルド
xcodebuild -project StickerBoard.xcodeproj -target StickerBoard -sdk iphonesimulator26.2 -arch arm64 build

# Xcodeで開く
open StickerBoard.xcodeproj
```

## 注意事項
- Vision Frameworkの背景除去はシミュレータでは動作しない（実機のみ）
- シミュレータではフォールバックとして元画像をそのまま返す
- 画像は Documents/Stickers/ にPNG保存、メタデータはSwiftDataに保存
- StickerPlacement に imageFileName を直接保持する設計（SwiftDataのID問題回避のため）
- Board の backgroundPatternData も placements と同様に Codable struct を JSON シリアライズして Data? に格納する設計
- BackgroundRemover は入力画像の EXIF 向きを正規化し、長辺2048pxにリサイズする（cgImage とマスクの整合性確保 + メモリ最適化）
- フィルター（キラキラ・レトロ・パステル・ネオン・ぷっくり）は StickerPlacement の filterType に保存し、ボード配置単位で適用する設計（シール自体ではなく配置ごとにフィルターが異なる）
- StickerFilterService は CIFilter ベースでオンザフライ処理。BoardEditorView ではフィルター適用画像をキャッシュして body 再評価時の再計算を回避
- ImageCacheManager（NSCache ベース）がフル解像度・サムネイル・フィルター適用済みの3層キャッシュを管理。メモリ警告時に自動パージ
- ImageStorage.save() は保存時に長辺1024pxにリサイズする（BackgroundRemover の2048px出力をステッカー用途に最適化）
- サムネイル表示（StickerThumbnailView, QuickPickThumbnail, BoardStickerPreviewView）は ImageStorage.loadThumbnail() 経由で縮小画像を使用
- 枠線（ボーダー）は StickerPlacement の borderWidthType / borderColorHex に保存し、フィルターと同様に配置単位で管理する設計
- StickerBorderService は CIMorphologyMaximum でアルファマスクを膨張させて輪郭に沿った枠線を描画。フィルター適用後の画像に枠線を重ねる（描画順序: フィルター → 枠線）
- ImageCacheManager の processed() メソッドがフィルター＋枠線の統合キャッシュを管理。キーは「fileName_filterType_borderWidth_borderColorHex」形式
