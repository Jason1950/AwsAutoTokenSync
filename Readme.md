# AwsAutoTokenSync

## 說明

AWS 憑證每 2～3 天就會過期，連線雲端 K8s 時需要反覆手動更新，相當麻煩。

本專案將整套更新流程整合至 Mac 選單列，一鍵即可自動更新憑證，減少重複操作、加快上工速度——做一隻懶惰的好牛馬。

---

## 環境

| 項目 | 需求 |
|------|------|
| 作業系統 | macOS（Apple Silicon M2 測試通過） |
| Python | Python 3 |
| 選單列工具 | [Ice](https://github.com/jordanbaird/Ice) + native-menubar |

安裝 Python 依賴：

```bash
pip3 install opencv-python pyotp
```

| 套件 | 用途 |
|------|------|
| `opencv-python` | 讀取 QR Code 圖片（`get_auth_key.py`） |
| `pyotp` | 產生 TOTP 6 位驗證碼（`check_auth_key.py`） |

---

## 流程一 — 取得 AWS 登入 OTP Secret Key

從 Google Authenticator 匯出的 QR Code 中，解析出 AWS MFA 用的 Secret Key。

### 操作步驟

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

   範例：

   ```bash
   python3 check_auth_key.py JBSWY3DPEHPK3PXP
   ```

### 預期輸出

**`get_auth_key.py`** — 解析 QR Code，列出所有帳號與 Secret Key：

```
[*] 正在讀取照片: .../OtpAuthKey/demo.png
[+] 成功讀取 QR Code 內容！

=== 🎉 解析成功 ===
[+] 帳號名稱: Amazon Web Services - jason@demo
    Secret Key: JBSWY3DPEHPK3PXP
--------------------------------------------------
```

**`check_auth_key.py`** — 用 Secret Key 產生當前 TOTP 驗證碼：

```
[*] 正在產生 TOTP 驗證碼
[*] Secret Key: JBSWY3DPEHPK3PXP

=== get key success ===
[+] 驗證碼: 123456
[+] 剩餘有效時間: 23 秒
--------------------------------------------------
```

驗證碼能正常產生，即代表 Secret Key 可用，可進入後續自動化流程。

> **注意**：若 QR Code 是鏡像照片（例如 Photo Booth 拍攝），`get_auth_key.py` 會自動嘗試水平翻轉後再讀取。

---

## 流程二 — 選單列一鍵更新憑證

> 待完成
