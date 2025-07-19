# IME POC 実装記録

## 実装完了項目

### ✅ Day 1: プロジェクトセットアップ
- **実装方式**: Xcodeプロジェクトではなく、Swift Package Managerを採用
- **Package.swift**: macOS 12.0以降対応、必要なフレームワークをリンク
- **Info.plist**: 
  - アクセシビリティ権限の説明文を追加
  - LSUIElement設定でメニューバーアプリとして動作
  - CFBundleIdentifier: com.example.ime-poc

### ✅ Day 2-3: 基本機能実装
- **InputMonitor.swift**: 
  - CGEventTapを使用したグローバルキーイベント監視
  - TISCopyCurrentKeyboardInputSourceで日本語入力状態を検出
  - 日本語入力中のキーコードマッピング実装（英語キーボード配列対応）
- **AppDelegate.swift**:
  - メニューバーアイテムの設定
  - アクセシビリティ権限チェックと要求
  - アプリケーションライフサイクル管理

### ✅ Day 4-5: 候補表示機能
- **CandidateListView.swift**:
  - NSTableViewベースの候補リスト
  - キーボードナビゲーション実装（上下矢印、Enter、Escape）
  - 半透明背景とATOK風のスタイリング
- **OverlayWindowController.swift**:
  - フローティングウィンドウで候補を表示
  - IMEウィンドウ検出機能（IMEWindowDetector.swift）
  - カーソル位置追従機能

### ✅ Day 6: テキスト挿入機能
- **テキスト挿入**: CGEventでキーボードイベントを生成
- **候補トリガー**: test/tesuto/てすと/テストで候補表示
- **自動非表示**: 候補選択後に自動的にウィンドウを非表示

### ✅ Day 7: テストと調整
- **ユニットテスト**: Tests/ime-pocTestsディレクトリに実装
- **ビルドスクリプト**: build-app.shでアプリケーションバンドル作成
- **デバッグ機能**: 詳細なログ出力

## 技術的な実装詳細

### 日本語入力の処理
```swift
// キーコードマッピング（InputMonitor.swift）
let keyMap: [Int: String] = [
    0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g",
    // ... 省略
    17: "t", 14: "e", 1: "s", 17: "t"  // "test"の入力
]
```

### 候補表示のトリガー条件
```swift
let lowerInput = currentInputText.lowercased()
if lowerInput.contains("test") || 
   lowerInput.contains("tesuto") ||
   currentInputText.contains("てすと") || 
   currentInputText.contains("テスト") {
    // 候補を表示
}
```

### ウィンドウ位置の計算
1. カーソル位置を取得（Accessibility API）
2. IMEウィンドウを検出（CGWindowListCopyWindowInfo）
3. 適切な位置に候補ウィンドウを配置

## 現在の制限事項

1. **オーバーレイ方式**: 既存IMEと完全に統合されていない
2. **ATOK検出**: 変換候補ウィンドウの正確な検出が困難
3. **キーコードマッピング**: 英語キーボード配列のみ対応

## ビルドと実行

```bash
# ビルド
./build-app.sh

# 実行
open 'IME POC.app'

# デバッグ実行（ログ表示）
'/Users/takets/repos/ime-poc/IME POC.app/Contents/MacOS/ime-poc'
```

## ファイル構成

```
ime-poc/
├── Package.swift              # Swift Package Manager設定
├── Info.plist                # アプリケーション設定
├── build-app.sh              # ビルドスクリプト
├── Sources/ime-poc/
│   ├── main.swift            # エントリーポイント
│   ├── AppDelegate.swift     # アプリケーション管理
│   ├── InputMonitor.swift    # キー入力監視
│   ├── OverlayWindowController.swift  # 候補ウィンドウ管理
│   ├── CandidateListView.swift        # 候補リストUI
│   └── IMEWindowDetector.swift        # IMEウィンドウ検出
├── Tests/ime-pocTests/       # ユニットテスト
└── IME POC.app/             # ビルド成果物
```

## 動作確認済み環境

- macOS 12.0以降
- 日本語入力環境（ATOK、macOS標準IME）
- テキストエディタ（TextEdit、VSCode等）

## 今後の改善案

1. **IMKフレームワーク**: 完全なIMEとして実装
2. **辞書機能**: カスタム候補の管理機能
3. **設定UI**: 候補のカスタマイズ機能
4. **他言語対応**: 中国語、韓国語などのサポート