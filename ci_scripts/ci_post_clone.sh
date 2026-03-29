#!/bin/sh
# ci_post_clone.sh
# Xcode Cloud: リポジトリのクローン直後に実行されるスクリプト
# XcodeGen をインストールして .xcodeproj を生成する

set -e

echo "=== ci_post_clone.sh 開始 ==="

# Homebrew のインストール確認
if ! command -v brew &> /dev/null; then
    echo "Homebrew をインストール中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# XcodeGen のインストール
echo "XcodeGen をインストール中..."
brew install xcodegen

# プロジェクト生成
echo "Xcode プロジェクトを生成中..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "=== ci_post_clone.sh 完了 ==="
