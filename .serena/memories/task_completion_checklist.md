# タスク完了時のチェックリスト

## コード変更後
1. `xcodegen generate` の実行が必要か確認（新規ファイル追加時は必須）
2. ビルドが通ることを確認: `xcodebuild -project StickerBoard.xcodeproj -target StickerBoard -sdk iphonesimulator26.2 -arch arm64 build`
3. コミット後に `/review-official-docs` を実行（.swiftファイル変更時）

## push前
- README.md / CLAUDE.md / PRD の更新が必要か確認
- メモリの更新が必要か確認

## ファイル追加時
- project.yml の更新は不要（sourcesディレクトリ指定のため自動検出）
- ただし `xcodegen generate` の再実行が必要
