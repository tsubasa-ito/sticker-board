# シールボード

**リアルシールをデジタルコレクション**

現実のシールを撮影して背景を自動で切り抜き、デジタルなシールボードに自由に配置できる iOS アプリです。

子どもの頃にシール手帳に夢中になった世代が、大人になった今もシール集めの楽しさをスマホで体験できます。

## 機能

- **シール切り抜き** — カメラで撮影またはカメラロールから写真を選び、Vision Framework の AI が背景を自動除去
- **マスク手動調整** — 自動切り抜き後にブラシツールで手動微調整（消しゴム/復元モード、ブラシサイズ変更、Undo、ピンチズーム対応）
- **複数シール一括検出** — 1枚の画像に複数のシールが写っている場合、個別に検出・選択して一括追加
- **シールライブラリ** — 切り抜いたシールをコレクションとして一覧管理
- **カルーセル型ボード一覧** — ホーム画面でボードをカルーセル形式で表示、シール配置のプレビュー付き
- **タブナビゲーション** — フローティングタブバーでホーム・撮影・ライブラリを切り替え
- **ボードエディタ** — シールをボード上にドラッグ・ピンチ・回転で自由に配置、タップで選択してレイヤー操作・削除
- **折りたたみ式ツールバー** — ボード編集時のフローティングツールバーは折りたたみ可能、キャンバス全域にアクセス
- **ボード画像保存** — 完成したボードを一枚の画像として写真ライブラリに保存
- **ローカル保存** — シールとボードのデータを端末内に永続保存

## 技術スタック

| 項目 | 技術 |
|------|------|
| 言語 | Swift |
| UI | SwiftUI |
| 背景除去 | Vision Framework（VNGenerateForegroundInstanceMaskRequest） |
| データ保存 | SwiftData + FileManager |
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
| シール追加 | カメラ撮影または写真選択 → 背景除去 → 「手動で調整する」で微調整可能 → ライブラリに保存 |
| 複数シール検出 | 複数シールが写った画像 → 個別に検出 → 選択UI → 一括保存 |
| ライブラリ | 保存したシールがグリッドで表示される・タップでプレビュー拡大・長押しで削除できる |
| ボード作成 | 新規ボードを作成 → ボード一覧に表示される |
| シール配置 | ボード上でシールをドラッグ移動・ピンチで拡大縮小・2本指で回転 |
| シール選択・操作 | シールをタップで選択 → 下部ツールバーの「前面へ」「背面へ」「削除」で操作 |
| ボード画像保存 | ボード編集画面のダウンロードボタン → 写真ライブラリに画像として保存される |
| データ永続化 | アプリを終了→再起動してシール・ボードが残っている |

### コマンドラインでのビルド確認

```bash
# シミュレータ向けビルド（CIなどで利用）
xcodebuild -project StickerBoard.xcodeproj \
  -target StickerBoard \
  -sdk iphonesimulator \
  -arch arm64 \
  -quiet build
```

## プロジェクト構成

```
StickerBoard/
├── App/
│   ├── StickerBoardApp.swift        # エントリーポイント
│   └── AppTheme.swift               # カラーテーマ・共通スタイル
├── Models/
│   ├── Sticker.swift                # シールデータモデル
│   ├── Board.swift                  # ボードデータモデル
│   └── StickerPlacement.swift       # ボード上のシール配置情報
├── Services/
│   ├── BackgroundRemover.swift      # Vision Framework 背景除去
│   ├── MaskCompositor.swift         # マスク合成・手動編集結果の適用
│   └── ImageStorage.swift           # 画像ファイルの保存・読み込み
└── Views/
    ├── Home/
    │   ├── MainTabView.swift        # タブナビゲーション・フローティングタブバー
    │   └── HomeView.swift           # ボード一覧カルーセル
    ├── Capture/
    │   ├── StickerCaptureView.swift        # 写真選択・背景除去
    │   ├── CameraView.swift                # カメラ撮影
    │   ├── MaskEditorView.swift            # マスク手動編集画面
    │   ├── MaskDrawingCanvas.swift         # ブラシ描画キャンバス（UIKit）
    │   ├── BrushToolbar.swift              # ブラシツールバー
    │   ├── MultiStickerSelectionView.swift  # 複数シール選択
    │   └── StickerPreviewView.swift        # 切り抜きプレビュー
    ├── Library/
    │   └── StickerLibraryView.swift  # シール一覧
    └── Board/
        ├── BoardListView.swift       # ボード一覧
        ├── BoardEditorView.swift     # ボード編集キャンバス
        └── StickerItemView.swift     # ドラッグ・ピンチ・回転操作
```

## ライセンス

Private
