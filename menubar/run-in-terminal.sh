#!/bin/zsh
# 從選單列 App 呼叫，在 iTerm 執行 AWS 腳本（只開一個視窗）

SCRIPT_PATH="$1"
SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$SCRIPT_PATH" ] || [ ! -f "$SCRIPT_PATH" ]; then
  echo "用法: $0 <script-path>"
  exit 1
fi

ITERM_APP="$("$SCRIPT_DIR_SELF/find-iterm.sh")" || {
  osascript -e 'display notification "請先安裝 iTerm" with title "AWS MenuBar" subtitle "https://iterm2.com"'
  echo "找不到 iTerm，請安裝: https://iterm2.com"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WRAPPER="${SCRIPT_DIR}/menubar/run-with-close.sh"

if [ ! -f "$WRAPPER" ]; then
  echo "找不到: $WRAPPER"
  exit 1
fi

RUN_CMD="zsh '${WRAPPER}' '${SCRIPT_PATH}'"

osascript <<EOF
tell application "iTerm"
    tell (create window with default profile command "${RUN_CMD}")
        activate
    end tell
end tell
EOF
