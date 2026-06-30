#!/bin/zsh
# 執行 AWS 腳本，成功則倒數 5 秒後自動關閉 iTerm 視窗，失敗則保留

# iTerm command 模式不會載入 login shell，需手動補上 PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"

SCRIPT_PATH="$1"
SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$SCRIPT_PATH" ] || [ ! -f "$SCRIPT_PATH" ]; then
  echo "用法: $0 <script-path>"
  exit 1
fi

"$SCRIPT_DIR_SELF/find-iterm.sh" >/dev/null || {
  echo "找不到 iTerm"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"

cd "$SCRIPT_DIR"
zsh "$SCRIPT_NAME"
STATUS=$?

echo ""
if [ $STATUS -eq 0 ]; then
  echo "=== 完成 ==="
  for i in 5 4 3 2 1; do
    echo "${i}..."
    sleep 1
  done

  CLOSE_SESSION_ID="$ITERM_SESSION_ID"
  (
    sleep 0.5
    if [ -n "$CLOSE_SESSION_ID" ]; then
      osascript -e "tell application \"iTerm\" to tell session id \"${CLOSE_SESSION_ID}\" to close" 2>/dev/null
    else
      osascript -e 'tell application "iTerm" to close current window' 2>/dev/null
    fi
  ) &
  disown
  exit 0
else
  echo "=== 失敗 (exit code: ${STATUS}) ==="
  echo "請檢查上方錯誤訊息，視窗將保持開啟。"
  exec zsh -l
fi
