# App Store 提出ガイド - シールボード v1.3.0

**作成日:** 2026-04-09
**対象バージョン:** 1.3.0

---

## 提出前のビルド準備

### 1. バージョン番号の確認

```bash
# project.yml のバージョンを確認
grep "MARKETING_VERSION" project.yml
grep "CURRENT_PROJECT_VERSION" project.yml
```

- MARKETING_VERSION: 1.3.0 であること
- CURRENT_PROJECT_VERSION: 前回のビルド番号より大きいこと

### 2. Release ビルドの作成

**方法A: Xcode Cloud（推奨）**
- main ブランチにマージすることで自動ビルド & TestFlight 配信
- Xcode Cloud の設定は ci_scripts/ci_post_clone.sh で XcodeGen を自動実行

**方法B: 手動**
```bash
# プロジェクト生成
xcodegen generate

# Xcode で開く
open StickerBoard.xcodeproj
```
1. Xcode > Product > Archive
2. Archive 完了後、Organizer で「Distribute App」を選択
3. 「App Store Connect」を選択してアップロード

### 3. TestFlight テスト

- [ ] TestFlight でインストール・動作確認
- [ ] 主要機能（AI切り抜き、ボード編集、フィルター、ウィジェット）を実機で確認
- [ ] サブスクリプション購入フローを Sandbox 環境で確認

---

## App Store Connect での提出手順

### Step 1: 新しいバージョンを作成

1. App Store Connect にログインする
2. 「マイApp」からシールボードを選択する
3. 左メニュー「App Store」タブを選択する
4. 「+バージョンまたはプラットフォーム」から「iOS」を選択する
5. バージョン番号「1.3.0」を入力する

### Step 2: ビルドを選択

1. 「ビルド」セクションで「+」をクリックする
2. アップロード済みのビルドを選択する
3. 処理中のビルドは選択できないので、処理完了まで待つ（通常15-30分）

### Step 3: メタデータを入力

#### スクリーンショット
1. 「App のプレビューとスクリーンショット」セクションを開く
2. iPhone 6.9インチ のタブを選択する
3. 作成したスクリーンショットをドラッグ&ドロップでアップロードする
4. 表示順をドラッグで調整する（1枚目がヒーローショット）
5. 必要に応じて iPad タブにもアップロードする

#### テキストメタデータ
以下を apple-metadata.md からコピー&ペーストする:

1. **プロモーションテキスト**（170文字以内）:
   ```
   現実のシールを撮るだけでAIが自動切り抜き! キラキラ・レトロなど6種フィルター&9色の枠線でデコって、あなただけの推し活ボードを完成させよう。ウィジェットでホーム画面にも飾れる!
   ```

2. **説明文**（4000文字以内）: apple-metadata.md の「最適化案」をそのままペースト

3. **キーワード**（100文字以内）:
   ```
   シール帳,ステッカー,推し活,切り抜き,写真加工,コレクション,デコ,コラージュ,グッズ管理,シール交換,手帳,ウィジェット,背景除去,フィルター,レトロ,推しグッズ,シール整理
   ```

4. **サブタイトル**（30文字以内）:
   ```
   AIで切り抜き!推し活シールコレクション
   ```

5. **What's New**（4000文字以内）: apple-metadata.md の What's New をペースト

#### 審査情報
1. **審査メモ**:
   ```
   This app captures real stickers/decals using the camera, removes the background
   using Vision Framework (on-device AI), and lets users arrange them on digital boards.

   - Camera and Photo Library access is needed to capture and select sticker photos.
   - The app works fully offline; all data is stored locally on-device.
   - No user accounts or login required.
   - Subscription (Pro plan) unlocks unlimited stickers/boards and additional customization features.

   Note: Background removal uses VNGenerateForegroundInstanceMaskRequest and requires
   a real device to function properly. On simulator, the original image is returned as-is.
   ```

2. **連絡先情報**: 最新であることを確認

### Step 4: App情報の確認

1. 左メニュー「App情報」を開く
2. **ローカライゼーション**: 日本語が追加されていることを確認
3. **カテゴリ**: 写真/ビデオ（プライマリ）確認
4. **年齢制限**: 4+ 確認
5. **App Privacy**: 「データは収集していません」確認

### Step 5: 提出

1. 右上の「審査に提出」ボタンをクリックする
2. 「このAppの輸出に関するコンプライアンス」: 「いいえ」を選択（ITSAppUsesNonExemptEncryption: NO）
3. 「広告識別子（IDFA）」: 使用していない場合は「いいえ」を選択
4. 確認画面で「提出」をクリックする

### Step 6: 審査待ち

- 通常24-48時間で審査完了
- ステータスが「審査中」→「審査準備完了」→「販売準備完了」と変化
- 「リジェクト」の場合は理由を確認し対応する

---

## 提出後の確認

### 審査通過後（即日）

- [ ] App Store でアプリページを確認する
- [ ] スクリーンショットが正しく表示されることを確認する
- [ ] サブタイトル「AIで切り抜き!推し活シールコレクション」が表示されることを確認する
- [ ] 説明文が更新されていることを確認する
- [ ] バージョンが1.3.0と表示されることを確認する

### 審査通過後（1日後）

- [ ] iTunes Search API で確認:
  ```
  https://itunes.apple.com/lookup?bundleId=com.tebasaki.StickerBoard&country=jp
  ```
- [ ] screenshotUrls が空でないことを確認する
- [ ] description が更新されていることを確認する
- [ ] languageCodesISO2A に "JA" が含まれることを確認する（日本語追加後）

### 審査通過後（3日後）

- [ ] 「シール帳」で検索してアプリが表示されるか確認する
- [ ] 「デジタルシール帳」で検索してアプリが表示されるか確認する
- [ ] 「推し活 シール」で検索してアプリが表示されるか確認する
- [ ] 検索順位を記録する

---

## トラブルシューティング

### 審査リジェクトの一般的な理由と対策

| 理由 | 対策 |
|------|------|
| スクリーンショットが不適切 | 実際のアプリ画面のスクリーンショットを使用する |
| メタデータにガイドライン違反 | 「無料」「最高の」等の誇大表現を避ける |
| サブスクリプション情報の不足 | 説明文にプラン詳細と価格を明記する |
| プライバシーポリシーリンク切れ | URL が有効であることを事前確認する |
