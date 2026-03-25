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
├── Models/       # SwiftData モデル（Sticker, Board, StickerPlacement, BackgroundPattern）
├── Services/     # BackgroundRemover, MaskCompositor, ImageStorage
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
