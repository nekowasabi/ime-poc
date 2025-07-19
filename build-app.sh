#!/bin/bash

# ビルド
swift build -c release

# アプリケーションバンドルのディレクトリ構造を作成
APP_NAME="IME POC"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 既存のバンドルを削除
rm -rf "$APP_BUNDLE"

# ディレクトリ構造を作成
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 実行ファイルをコピー
cp .build/x86_64-apple-macosx/release/ime-poc "$MACOS_DIR/ime-poc"

# Info.plistをコピー
cp Info.plist "$CONTENTS_DIR/"

# 実行権限を設定
chmod +x "$MACOS_DIR/ime-poc"

echo "アプリケーションバンドルを作成しました: $APP_BUNDLE"
echo "実行するには: open '$APP_BUNDLE'"