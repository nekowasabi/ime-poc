import Cocoa

class IMEWindowDetector {
    static func findIMEWindows() -> [CGWindowID] {
        var windowIDs: [CGWindowID] = []
        
        // 画面上のすべてのウィンドウを取得
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                // ウィンドウの所有者プロセス名を確認
                if let ownerName = window[kCGWindowOwnerName as String] as? String {
                    // ATOK、Google日本語入力、macOS標準IMEなどの候補ウィンドウを検出
                    if ownerName.contains("ATOK") || 
                       ownerName.contains("JapaneseIM") || 
                       ownerName.contains("Google Japanese Input") ||
                       ownerName.contains("日本語") {
                        
                        if let windowID = window[kCGWindowNumber as String] as? CGWindowID {
                            windowIDs.append(windowID)
                            
                            // デバッグ情報
                            if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
                                print("IMEウィンドウ検出: \(ownerName)")
                                print("  位置: x=\(bounds["X"] ?? 0), y=\(bounds["Y"] ?? 0)")
                                print("  サイズ: w=\(bounds["Width"] ?? 0), h=\(bounds["Height"] ?? 0)")
                            }
                        }
                    }
                }
            }
        }
        
        return windowIDs
    }
    
    static func getIMEWindowBounds() -> CGRect? {
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            // すべてのウィンドウをデバッグ出力
            print("=== 全ウィンドウ一覧 ===")
            var candidateWindows: [(rect: CGRect, ownerName: String, layer: Int)] = []
            
            for window in windowList {
                if let ownerName = window[kCGWindowOwnerName as String] as? String,
                   let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                   let x = bounds["X"],
                   let y = bounds["Y"],
                   let width = bounds["Width"],
                   let height = bounds["Height"] {
                    
                    let layer = window[kCGWindowLayer as String] as? Int ?? 0
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    
                    // ATOKウィンドウの詳細を出力
                    if ownerName.contains("ATOK") {
                        print("ATOKウィンドウ発見: '\(ownerName)', 位置: \(rect), レイヤー: \(layer)")
                        
                        // 変換候補ウィンドウの特徴
                        // 1. レイヤーが高い（前面に表示）
                        // 2. サイズが適度
                        // 3. 画面中央付近に表示されることが多い
                        if layer > 0 && width > 50 && width < 600 && height > 20 && height < 400 {
                            candidateWindows.append((rect: rect, ownerName: ownerName, layer: layer))
                        }
                    }
                }
            }
            
            // レイヤーが最も高い（最前面の）ウィンドウを選択
            if let topWindow = candidateWindows.max(by: { $0.layer < $1.layer }) {
                print("選択されたIMEウィンドウ: \(topWindow.ownerName), 位置: \(topWindow.rect)")
                return topWindow.rect
            }
        }
        return nil
    }
}