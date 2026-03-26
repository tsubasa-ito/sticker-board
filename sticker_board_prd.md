# シールボード PRD & MVP 開発資料

**アプリ名:** シールボード  
**サブタイトル:** リアルシールをデジタルコレクション  
**作成日:** 2026年3月  
**プラットフォーム:** iOS（Swift / SwiftUI）  
**ステータス:** MVP 実装完了

---

## 1. プロダクト概要

### 1.1 プロダクトビジョン

> 「現実のシールを撮影して、スマホの中に自分だけのシールボードを作れるアプリ」
>
> **アプリ名：シールボード** ／ サブタイトル：リアルシールをデジタルコレクション

子どもの頃にシール手帳に夢中になった世代が、大人になった今もシール集めの楽しさを手軽にデジタルで体験できるプロダクト。

### 1.2 解決する課題

| 課題 | 現状 | このアプリでの解決 |
|------|------|------------------|
| リアルなシールを保管・整理するのが大変 | 手帳がかさばる・劣化する | 撮影してデジタル保管 |
| シール手帳アプリは既製スタンプが中心 | 自分だけのシールが使えない | 現実のシールを切り抜いて使える |
| SNSで見せたいが撮影が映えない | シールバラバラに並べた写真は映えない | 綺麗にレイアウトして1枚の画像に |

---

## 2. ターゲットユーザー

### 2.1 メインターゲット

**20代後半〜30代中盤の男女**

- 子どもの頃（90〜00年代）にシール手帳・シール交換文化を経験した世代
- スマホネイティブ世代であり、アプリへの馴染みが高い
- 推し活・コレクション趣味を持つ層と親和性が高い

### 2.2 ペルソナ

**ペルソナA: 田中さくら（28歳・会社員）**
- 好きなキャラクターグッズのシールを集めている
- SNSに「推しコレ」を投稿するのが趣味
- 手帳やノートにシールを貼ることもあるが、劣化が気になる

**ペルソナB: 鈴木けんた（33歳・フリーランサー）**
- アニメ・ゲームのイベントでステッカーを入手する
- コレクションを整理したいが場所を取りたくない
- デジタルアーカイブとして記録に残したい

---

## 3. MVP スコープ

### 3.1 MVP に含める機能（In Scope）

#### 機能1: 写真からシール切り抜き

- カメラ撮影またはカメラロールから写真を選択
- Vision Framework による自動背景除去（被写体切り抜き）
- 切り抜き結果のプレビュー表示
- 切り抜いたシールをライブラリに保存
- **複数シール一括検出** — 1枚の画像から複数オブジェクトを個別に検出・選択・一括保存
- **マスク手動調整** — ブラシツール（消しゴム/復元モード、サイズ変更、Undo対応）で切り抜き結果を微調整
- **撮影ガイド** — きれいに切り抜くための撮影のコツを表示（折りたたみ可能）
- **画像最適化** — アルファトリミング（透明余白除去）＋ 長辺1024pxリサイズで保存

#### 機能2: シールのレイアウト・配置

- ボード（キャンバス）を新規作成（初回起動時にデフォルトボード自動作成）
- ライブラリからシールをボードに配置（クイックピック対応）
- ドラッグ移動・ピンチズーム・回転のジェスチャー操作
- 複数シールの重なり順（Z軸）変更
- ボードの保存（ローカル・自動保存）
- **フィルター加工** — キラキラ・レトロ・パステル・ネオン・ぷっくり・ワッペンの6種（＋オリジナル）をボード配置単位で適用
- **枠線（ボーダー）** — 太さ4段階 × 9色プリセット、輪郭に沿った自然な枠線描画
- **背景パターン** — 無地・ドット・グリッド・ストライプ・グラデーションの5種、カラーカスタマイズ対応
- **ボード画像書き出し** — 完成ボードを1枚の画像として写真ライブラリに保存

### 3.2 MVP に含めない機能（Out of Scope）

以下はv2以降で検討する。

- ~~完成ボードの画像書き出し~~ → 写真ライブラリへの保存は実装済み。SNSシェア機能は未実装
- ~~背景テクスチャ・装飾素材~~ → 背景パターン5種（無地・ドット・グリッド・ストライプ・グラデーション）は実装済み。装飾素材は未実装
- ~~シールのフィルター加工~~ → ボード配置単位でフィルター7種（オリジナル・キラキラ・レトロ・パステル・ネオン・ぷっくり・ワッペン）を実装済み
- ~~シールへの枠線（ボーダー）追加~~ → ボード配置単位で枠線（太さ4段階×9色）を実装済み。CIMorphologyMaximumによるアルファマスク膨張で輪郭に沿った自然な枠線を描画
- シールへのテキスト・スタンプ追加
- クラウド同期・バックアップ
- シールライブラリの整理・タグ付け

---

## 4. ユーザーストーリー

### MVP スコープのユーザーストーリー

```
As a ユーザー
I want to 持っているシールを撮影して切り抜き、
So that デジタルシールとして手元に保存したい

As a ユーザー
I want to 切り抜いたシールをボード上に自由に配置して
So that 自分好みのシールレイアウトを作りたい
```

### ユーザーフロー（実装済み）

```
アプリ起動（初回: デフォルトボード自動作成）
  └─ ホーム画面（カルーセル型ボード一覧）
       │
       ├─ [＋ タブ] シールを追加する
       │    ├─ 撮影ガイド表示（折りたたみ可能）
       │    ├─ カメラ撮影 or カメラロール選択
       │    │    └─ 背景除去処理（Vision Framework）
       │    │         ├─ 単体検出 → プレビュー確認
       │    │         │    ├─ [手動で調整する] → マスクエディタ（ブラシ編集）
       │    │         │    └─ ライブラリに保存
       │    │         └─ 複数検出 → 個別選択UI → 一括保存
       │    └─ ライブラリに保存
       │
       ├─ [ボードカードをタップ] ボード編集
       │    ├─ シール追加（ライブラリ / クイックピック）
       │    ├─ シール操作（ドラッグ・ピンチ・回転・Z軸変更・削除）
       │    ├─ フィルター加工（7種）
       │    ├─ 枠線追加（4段階×9色）
       │    ├─ 背景パターン選択（5種＋カラーカスタマイズ）
       │    └─ ボード画像保存（写真ライブラリ）
       │
       └─ [ライブラリ タブ] シール一覧
            ├─ グリッド表示（タップでプレビュー拡大）
            ├─ 長押しで削除（使用中ボード警告あり）
            └─ シール追加ボタン
```

---

## 5. 技術仕様

### 5.1 技術スタック

| 項目 | 採用技術 | 理由 |
|------|---------|------|
| 言語 | Swift 5.9+ | ネイティブ・最高品質の画像処理 |
| UI フレームワーク | SwiftUI | 宣言的UI・最新Apple推奨 |
| 背景除去 | Vision Framework（VNGenerateForegroundInstanceMaskRequest） | オンデバイス・高精度・無料 |
| 画像合成 | Core Image / UIGraphicsImageRenderer | ネイティブGPU活用 |
| フィルター処理 | CIFilter（CISepiaTone, CIColorControls 等） | リアルタイムGPU処理 |
| 枠線描画 | CIMorphologyMaximum | アルファマスク膨張で輪郭追従 |
| データ保存 | SwiftData | シンプルなローカルDB |
| 画像ファイル保存 | FileManager + PNG | ローカルストレージ |
| プロジェクト管理 | XcodeGen（project.yml） | プロジェクトファイルの自動生成 |
| 最低OS要件 | iOS 18以上 | Vision Framework + SwiftData の安定版 |

### 5.2 主要コンポーネント構成

```
StickerBoard/
├── App/                              # エントリーポイント・テーマ
│   ├── StickerBoardApp.swift         # ModelContainer初期化・デフォルトボード作成・NavBar設定
│   └── AppTheme.swift                # カラーパレット・共通スタイル（ネイビー×オレンジ×クリーム）
│
├── Models/                           # SwiftData モデル・Codable構造体
│   ├── Sticker.swift                 # シールデータモデル
│   ├── Board.swift                   # ボードデータモデル（JSONシリアライズ設計）
│   ├── StickerPlacement.swift        # ボード上のシール配置情報
│   ├── StickerFilter.swift           # フィルター種別（7種）
│   ├── StickerBorder.swift           # 枠線の太さ・カラープリセット
│   └── BackgroundPattern.swift       # 背景パターン種別・設定
│
├── Services/                         # ビジネスロジック
│   ├── BackgroundRemover.swift       # Vision Framework 背景除去・複数オブジェクト検出
│   ├── MaskCompositor.swift          # マスク合成（手動編集結果の適用）
│   ├── StickerFilterService.swift    # CIFilterベースのフィルター処理（7種）
│   ├── StickerBorderService.swift    # CIMorphologyMaximumベースの枠線描画
│   ├── ImageCacheManager.swift       # 3層NSCacheキャッシュ管理
│   └── ImageStorage.swift            # 画像ファイルの保存・読み込み・サムネイル生成
│
└── Views/
    ├── Home/                         # ホーム・ナビゲーション
    │   ├── MainTabView.swift         # フローティングタブバー
    │   └── HomeView.swift            # ボード一覧カルーセル
    ├── Capture/                      # シール撮影・切り抜きフロー
    │   ├── StickerCaptureView.swift  # 写真選択・背景除去・保存
    │   ├── CameraView.swift          # カメラ撮影（UIImagePickerController）
    │   ├── CaptureGuideTipsView.swift # 撮影ガイド・コツ
    │   ├── MaskEditorView.swift      # マスク手動編集画面
    │   ├── MaskDrawingCanvas.swift   # ブラシ描画キャンバス
    │   ├── BrushToolbar.swift        # ブラシツールバー
    │   ├── MultiStickerSelectionView.swift # 複数シール選択
    │   ├── StickerPreviewView.swift  # 切り抜きプレビュー
    │   └── StickerFilterPickerView.swift # フィルター選択UI
    ├── Library/
    │   └── StickerLibraryView.swift  # シール一覧・プレビュー・削除
    └── Board/
        ├── BoardListView.swift       # ボード一覧
        ├── BoardEditorView.swift     # ボード編集キャンバス
        ├── StickerItemView.swift     # ドラッグ・ピンチ・回転操作
        ├── BoardBackgroundView.swift # 背景パターン描画
        ├── BackgroundPatternPickerView.swift # 背景パターン選択UI
        └── StickerBorderPickerView.swift # 枠線設定UI
```

### 5.3 データモデル（SwiftData）

```swift
@Model
class Sticker {
    var id: UUID
    var imageFileName: String   // Documents/Stickers/ 内のPNGファイル名
    var createdAt: Date
}

@Model
class Board {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var placementsData: Data?           // [StickerPlacement] の JSON シリアライズ
    var backgroundPatternData: Data?    // BackgroundPatternConfig の JSON シリアライズ
    // computed: placements, backgroundPattern（getter/setter でJSON変換）
}

struct StickerPlacement: Codable, Identifiable {
    var id: UUID
    var stickerId: UUID
    var imageFileName: String   // シール画像ファイル名（SwiftData ID問題回避のため直接保持）
    var positionX: Double       // X 座標
    var positionY: Double       // Y 座標
    var scale: Double           // 拡大縮小（デフォルト 1.0）
    var rotation: Double        // 回転角度（ラジアン）
    var zIndex: Int             // 重なり順
    var filterType: String      // フィルター種別（配置単位で管理）
    var borderWidthType: String // 枠線の太さ（none/thin/medium/thick）
    var borderColorHex: String  // 枠線の色（hex値）
    // computed: filter, borderWidth, hasBorder
}

enum StickerFilter: String, CaseIterable {
    case original, sparkle, retro, pastel, neon, puffy, wappen
}

enum StickerBorderWidth: String, CaseIterable {
    case none, thin, medium, thick
    // radiusRatio: 画像短辺に対する比率（0.015, 0.03, 0.05）
}

struct BackgroundPatternConfig: Codable {
    var patternType: BackgroundPatternType  // solid, dot, grid, stripe, gradient
    var primaryColorHex: String
    var secondaryColorHex: String
}
```

---

## 6. 懸念点・リスク管理

### 6.1 技術リスク

| リスク | 影響度 | 対応状況 |
|--------|--------|----------|
| 背景除去の精度が低い場合（複雑な背景・白シール） | 高 | **対応済み**: MaskEditorView でブラシによる手動マスク調整を実装 |
| ジェスチャーの競合（ドラッグ vs ピンチ） | 中 | **対応済み**: `simultaneousGesture` で制御 |
| 大量シール配置時のパフォーマンス劣化 | 中 | **対応済み**: 3層キャッシュ（ImageCacheManager）+ サムネイル最適化 |
| iOS 18未満のデバイス非対応 | 低 | 要件として iOS 18+ を明記 |

### 6.2 著作権リスク

- ユーザーが撮影した版権キャラクターのシールを利用する場合、**個人利用の範囲内**に限定
- MVP では SNS シェア機能を含めないことでリスクを最小化
- 利用規約に「個人利用目的のみ」を明記する

---

## 7. 開発ロードマップ

### MVP フェーズ — **完了**

以下の機能がすべて実装済み:

- シール撮影・切り抜き（Vision Framework 背景除去）
- マスク手動調整（ブラシツール）
- 複数シール一括検出・選択
- 撮影ガイド表示
- シールライブラリ（一覧・プレビュー・削除）
- ボード作成・編集・保存（カルーセルUI）
- シール配置（ドラッグ・ピンチ・回転・Z軸変更）
- フィルター加工（7種、配置単位）
- 枠線（4段階×9色、配置単位）
- 背景パターン（5種、カラーカスタマイズ）
- ボード画像書き出し（写真ライブラリ保存）
- デザインシステム統一（ネイビー×オレンジ×クリーム）

### v2 以降（MVP 後の拡張）

- SNS シェア機能
- デコレーション素材（装飾スタンプ等）
- シールライブラリのタグ・検索
- クラウドバックアップ（iCloud）

---

## 8. 成功指標（KPI）

MVP 検証期間（リリース後 4 週間）での目標値：

| 指標 | 目標 |
|------|------|
| シール切り抜き成功率 | 80%以上（ユーザー主観） |
| 1セッションあたりの配置シール数 | 3枚以上 |
| リテンション（1週間後） | 30%以上 |
| クラッシュ率 | 1%未満 |

---

## 9. 未解決事項・今後の検討

- [x] アプリ名の決定 → **シールボード**（サブタイトル：リアルシールをデジタルコレクション）
- [x] 最低OS要件の決定 → **iOS 18以上**
- [ ] App Store カテゴリ（写真＆ビデオ or ライフスタイル）
- [ ] 無料 or 有料モデルの検討（広告なし前提）
- [ ] TestFlight での初期テスター募集方法
