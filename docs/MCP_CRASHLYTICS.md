# Firebase Crashlytics × Claude Code MCP 設定ガイド

## 概要

Firebase Crashlytics のクラッシュデータを Claude Code（AI ツール）から MCP（Model Context Protocol）経由で直接分析・対応できるようにするための設定手順です。

## 前提条件

- Firebase プロジェクトのセットアップ完了
- Node.js / npm がインストールされていること
- Firebase CLI へのログイン済みであること（`firebase login`）

## Claude Code への MCP 設定

### 1. `~/.claude.json` または `settings.json` に追加

```json
{
  "mcpServers": {
    "firebase": {
      "command": "npx",
      "args": ["-y", "firebase-tools@latest", "mcp"],
      "env": {
        "FIREBASE_PROJECT_ID": "YOUR_FIREBASE_PROJECT_ID"
      }
    }
  }
}
```

> `YOUR_FIREBASE_PROJECT_ID` を実際の Firebase プロジェクト ID（Firebase コンソール → プロジェクトの設定 → 全般タブで確認）に置き換えてください。

### 2. Claude Code の再起動

設定後、Claude Code を再起動して MCP サーバーを有効化します。

## 使用例

MCP が有効化されると、Claude Code から以下のような自然言語でクラッシュ分析が可能になります：

```
「直近1週間のクラッシュ一覧を見せて」
「クラッシュ率が高い上位3件の原因を分析して」
「iOS 18.x でのみ発生しているクラッシュを調べて」
```

## Firebase プロジェクトのセットアップ手順

> **注意**: `GoogleService-Info.plist` はプロジェクト固有の設定ファイルです。
> Firebase コンソールからダウンロードして `StickerBoard/` 直下に配置してください。
> このファイルは `.gitignore` で除外することを推奨します。

### 手順

1. [Firebase コンソール](https://console.firebase.google.com/) にアクセス
2. 新規プロジェクトを作成（または既存のプロジェクトを使用）
3. iOS アプリを追加
   - Bundle ID: `com.tebasaki.StickerBoard`
4. `GoogleService-Info.plist` をダウンロード
5. `StickerBoard/GoogleService-Info.plist` として配置
6. `xcodegen generate` でプロジェクトを再生成
7. Crashlytics をダッシュボードで有効化

### `.gitignore` への追加推奨

```
# Firebase
StickerBoard/GoogleService-Info.plist
```

## dSYM 自動アップロードについて

`project.yml` に設定済みの Build Phase（`[Firebase] Upload dSYMs to Crashlytics`）により、
Release ビルド時に dSYM が自動的に Crashlytics にアップロードされます。

Xcode Cloud を使用している場合は `ci_scripts/ci_post_clone.sh` での設定は不要です（Build Phase が自動実行されます）。

## 参考リンク

- [Firebase Crashlytics for iOS 公式ドキュメント](https://firebase.google.com/docs/crashlytics/get-started?platform=ios)
- [firebase-tools MCP](https://firebase.google.com/docs/cli)
