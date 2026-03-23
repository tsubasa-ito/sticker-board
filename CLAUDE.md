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
├── App/          # エントリーポイント、カラーテーマ
├── Models/       # SwiftData モデル（Sticker, Board, StickerPlacement）
├── Services/     # BackgroundRemover, ImageStorage
└── Views/        # SwiftUI画面（Home, Capture, Library, Board）
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
