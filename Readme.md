# AwsAutoTokenSync

## 📝 說明

AWS 憑證每 2～3 天就會過期，連線雲端 K8s 時需要反覆手動更新，相當麻煩。

本專案將整套更新流程整合至 Mac 選單列，一鍵即可自動更新憑證，減少重複操作、加快上工速度——做一隻懶惰的好牛馬。

---

## ✨ 功能特色

- **自動化 MFA 驗證**：內建 Python 腳本自動解析 QR Code 並產生 TOTP 驗證碼，免去手動開手機查看的麻煩。
- **一鍵更新 STS 憑證**：透過 Mac 原生選單列（Menu Bar）一鍵執行，自動換取並寫入臨時憑證（Session Token）。
- **原生 macOS 體驗**：使用 Swift 開發輕量級背景 App，無 Dock 圖示干擾，並支援開機自動啟動。
- **智慧終端機整合**：自動喚起 iTerm 執行更新腳本，成功後倒數自動關閉視窗，失敗則保留錯誤訊息方便除錯。

---

## 💻 環境需求

| 項目 | 需求 |
|------|------|
| 作業系統 | macOS（Apple Silicon M2 測試通過） |
| 終端機 | [iTerm2](https://iterm2.com/) |
| Python | Python 3 |
| 選單列工具 | 原生 Swift 編譯打包 |

安裝 Python 依賴：

```bash
pip3 install opencv-python pyotp
```

| 套件 | 用途 |
|------|------|
| `opencv-python` | 讀取 QR Code 圖片（`get_auth_key.py`） |
| `pyotp` | 產生 TOTP 6 位驗證碼（`check_auth_key.py`） |

---

## 🚀 使用流程

### 流程一 — 取得 AWS 登入 OTP Secret Key

從 Google Authenticator 匯出的 QR Code 中，解析出 AWS MFA 用的 Secret Key。

**操作步驟：**

1. 進入 `OtpAuthKey` 資料夾
   ```bash
   cd OtpAuthKey
   ```
2. 在手機上開啟 **Google Authenticator**，匯出 AWS 相關的 QR Code，並截圖
3. 將截圖傳到電腦，重新命名為 `demo.png`，放在 `OtpAuthKey` 資料夾內（與 `get_auth_key.py` 同層）
4. 執行解析腳本
   ```bash
   python3 get_auth_key.py
   ```
5. 從輸出中複製 `Secret Key`，帶入驗證腳本確認可用
   ```bash
   python3 check_auth_key.py <SECRET_KEY>
   ```
   *(驗證碼能正常產生，即代表 Secret Key 可用，請將此 Key 記下備用)*

> **注意**：若 QR Code 是鏡像照片（例如 Photo Booth 拍攝），`get_auth_key.py` 會自動嘗試水平翻轉後再讀取。

---

### 流程二 — 設定並安裝選單列 App

將取得的 Secret Key 與 AWS 帳號資訊寫入腳本，並安裝 Mac 選單列工具。

**操作步驟：**

1. **設定 AWS 參數**
   打開專案根目錄的 `aws-auto-gen.sh`，修改以下變數為你的真實資訊：
   ```bash
   TOTP_SECRET="你的_SECRET_KEY"                 # 流程一取得的 Secret Key
   AWS_USER_PROFILE="你的_長期憑證_profile"        # ~/.aws/credentials 中的長期 AK/SK profile
   AWS_AUTH_PROFILE="你的_登入用_profile"          # 實際登入 / kubectl 使用的 profile
   ARN_OF_MFA="arn:aws:iam::123456789:mfa/xxx" # 你的 AWS MFA ARN
   ```

2. **執行安裝腳本**
   在終端機執行以下指令，將 Swift 程式碼編譯為 macOS `.app` 應用程式並設定開機自啟：
   ```bash
   chmod +x install-native-menubar.sh
   ./install-native-menubar.sh
   ```

3. **一鍵更新憑證**
   - 安裝完成後，Mac 右上角選單列會出現一個 **☁️ 雲朵圖示**。
   - 點擊圖示並選擇 **「Demo Gen」**。
   - 系統會自動開啟 iTerm 視窗執行更新腳本，成功取得 Token 後視窗會於 5 秒後自動關閉。
   - 憑證更新完成！你可以開始使用 kubectl 或 AWS CLI 了。

---

## 🛠️ 系統架構與實作細節

- **macOS 原生選單列 App (`AWSMenuBar`)**：
  - 透過 `install-native-menubar.sh` 將 Swift 程式碼自動編譯並打包為 macOS `.app` 應用程式。
  - 設定 `LSUIElement` 讓 App 於背景執行（僅顯示於選單列，不顯示於 Dock）。
- **自動化安裝與啟動機制**：
  - 透過 Shell Script 自動檢查 iTerm 環境並關閉舊版程序。
  - 建立 `LaunchAgent` (`.plist`) 實現開機自動啟動與背景常駐。
