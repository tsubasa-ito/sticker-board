# 開発コマンド一覧

## プロジェクト生成
```bash
# project.yml変更後に必ず実行
xcodegen generate
```

## ビルド
```bash
# シミュレータ向けビルド
xcodebuild -project StickerBoard.xcodeproj -target StickerBoard -sdk iphonesimulator26.2 -arch arm64 build
```

## Xcodeで開く
```bash
open StickerBoard.xcodeproj
```

## Git操作
```bash
git status
git diff
git log --oneline -10
```

## 注意
- テストターゲットは未設定（テストコマンドなし）
- リンター・フォーマッターは未導入
- Vision Frameworkの動作確認は実機が必要
- シミュレータでは背景除去がフォールバック動作（元画像をそのまま返す）
