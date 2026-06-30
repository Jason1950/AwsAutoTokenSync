#!/bin/zsh

set -e

# 使用相對路徑取得當前腳本所在的目錄
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MENUBAR_DIR="$SCRIPT_DIR/menubar"
APP_NAME="AWSDemoMenuBar"
APP_PATH="$HOME/Applications/${APP_NAME}.app"
PLIST_LABEL="com.henry.aws-demo-menubar"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "=== AWS 原生選單列 App 安裝 (Demo 版) ==="
echo ""

# 0. 確認 iTerm 已安裝（支援 /Applications 與 ~/Applications）
ITERM_APP="$("$MENUBAR_DIR/find-iterm.sh")" || {
  echo "[-] 找不到 iTerm，請先安裝: https://iterm2.com"
  exit 1
}
echo "[+] iTerm 已安裝: $ITERM_APP"

# 1. 停止舊版
pkill -f "$APP_NAME" 2>/dev/null || true
pkill -f "aws-demo-menubar" 2>/dev/null || true
chmod +x "$MENUBAR_DIR/run-in-terminal.sh"
chmod +x "$MENUBAR_DIR/run-with-close.sh"
chmod +x "$MENUBAR_DIR/find-iterm.sh"
launchctl bootout "gui/$(id -u)/${PLIST_LABEL}" 2>/dev/null || true
sleep 1

# 2. 編譯並打包成 .app
echo "[*] 正在編譯..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources/menubar"

swiftc "$MENUBAR_DIR/aws_menubar.swift" \
  -o "$APP_PATH/Contents/MacOS/$APP_NAME" \
  -framework Cocoa

# 將相對應的腳本都複製進 App 的 Resources 內部，達成相對路徑的效果
cp "$SCRIPT_DIR/aws-auto-gen.sh" "$APP_PATH/Contents/Resources/"
cp "$MENUBAR_DIR/find-iterm.sh" "$APP_PATH/Contents/Resources/menubar/"
cp "$MENUBAR_DIR/run-in-terminal.sh" "$APP_PATH/Contents/Resources/menubar/"
cp "$MENUBAR_DIR/run-with-close.sh" "$APP_PATH/Contents/Resources/menubar/"

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${PLIST_LABEL}</string>
    <key>CFBundleName</key>
    <string>AWS Demo MenuBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"
echo "[+] App 已建立: $APP_PATH"

# 3. LaunchAgent
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Applications"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>${APP_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# 4. 啟動
open "$APP_PATH"
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true

sleep 2
if pgrep -f "$APP_NAME" &>/dev/null; then
  echo "[+] 執行中 (pid $(pgrep -f "$APP_NAME"))"
else
  echo "[-] 啟動失敗，請手動執行: open \"$APP_PATH\""
fi

echo ""
echo "=== 完成 ==="
echo "請在選單列找 ☁️ 雲朵圖示（在時鐘左邊）。"
echo ""
