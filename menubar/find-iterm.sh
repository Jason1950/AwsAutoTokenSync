#!/bin/zsh
# 輸出 iTerm.app 路徑（支援 /Applications 與 ~/Applications）

for path in \
  "/Applications/iTerm.app" \
  "$HOME/Applications/iTerm.app" \
  "/Applications/iTerm2.app" \
  "$HOME/Applications/iTerm2.app"
do
  if [ -d "$path" ]; then
    echo "$path"
    exit 0
  fi
done

exit 1
