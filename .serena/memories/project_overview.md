# StickerBoard - プロジェクト概要

## 目的
リアルなシール（ステッカー）を撮影し、背景を除去してデジタルコレクションとして管理するiOSアプリ。
ボード上にシールを自由に配置・編集できる。

## 技術スタック
- **言語**: Swift 5.9
- **UI**: SwiftUI（iOS 18+）
- **データ**: SwiftData（ローカルDB）
- **画像処理**: Vision Framework（VNGenerateForegroundInstanceMaskRequest）
- **プロジェクト管理**: XcodeGen（project.yml）
- **外部依存**: なし

## ターゲット
- iOS 18.0+
- iPhone専用（TARGETED_DEVICE_FAMILY: 1）
- Bundle ID: com.tebasaki.StickerBoard

## プロジェクト構成
```
StickerBoard/
├── App/              # エントリーポイント（StickerBoardApp）、カラーテーマ（AppTheme）
├── Models/           # SwiftDataモデル
│   ├── Sticker.swift          # @Model: id, imageFileName, createdAt
│   ├── Board.swift            # @Model: id, title, createdAt, updatedAt, placementsData
│   └── StickerPlacement.swift # Codable struct: 配置情報（座標、スケール、回転、zIndex）
├── Services/
│   ├── BackgroundRemover.swift # Vision Frameworkによる背景除去・複数シール抽出
│   └── ImageStorage.swift      # Documents/Stickers/ へのPNG保存・読込・削除
└── Views/
    ├── Home/          # ホーム画面
    ├── Capture/       # 撮影・写真選択・シール切り抜き
    ├── Board/         # ボード編集・シール配置
    └── Library/       # シールライブラリ
```

## 重要な設計判断
- StickerPlacement に imageFileName を直接保持（SwiftDataのID問題回避）
- Vision Frameworkの背景除去はシミュレータ非対応 → フォールバックで元画像を返す
- 画像はファイルシステム（Documents/Stickers/）にPNG保存、メタデータはSwiftData
- BoardのplacementsはCodable JSONとしてSwiftDataに保存
