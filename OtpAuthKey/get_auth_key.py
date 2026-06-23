import cv2
import base64
import urllib.parse
import os

def decode_migration_uri(uri):
    try:
        # 1. 解析 URL 取得 data 參數
        parsed = urllib.parse.urlparse(uri)
        qs = urllib.parse.parse_qs(parsed.query)
        if 'data' not in qs:
            print("[-] 錯誤: 找不到 data 參數")
            return
            
        data = qs['data'][0]
        
        # 2. Base64 解碼
        decoded_data = base64.b64decode(data)
        
        print("\n=== 🎉 解析成功 ===")
        # 3. 尋找所有的 Secret Key 和 名稱
        # Protobuf 結構解析:
        # 每個 OTP 參數是一個 message，它的 field number 是 1，wire type 是 2 (length-delimited)
        # 所以整個 OTP 參數的 tag 是 (1 << 3) | 2 = 0x0A
        
        idx = 0
        found = False
        while idx < len(decoded_data):
            # 尋找 OTP 參數區塊 (0x0A)
            if decoded_data[idx] == 0x0A:
                idx += 1
                otp_length = decoded_data[idx]
                idx += 1
                
                # 進入 OTP 參數內部解析
                end_idx = idx + otp_length
                secret_b32 = "未找到"
                name = "未知名稱"
                issuer = ""
                
                while idx < end_idx:
                    field_tag = decoded_data[idx]
                    idx += 1
                    
                    if field_tag == 0x0A: # Field 1: Secret (內部)
                        length = decoded_data[idx]
                        idx += 1
                        secret_bytes = decoded_data[idx:idx+length]
                        secret_b32 = base64.b32encode(secret_bytes).decode('utf-8').replace('=', '')
                        idx += length
                    elif field_tag == 0x12: # Field 2: Name
                        length = decoded_data[idx]
                        idx += 1
                        name_bytes = decoded_data[idx:idx+length]
                        name = name_bytes.decode('utf-8', errors='ignore')
                        idx += length
                    elif field_tag == 0x1A: # Field 3: Issuer
                        length = decoded_data[idx]
                        idx += 1
                        issuer_bytes = decoded_data[idx:idx+length]
                        issuer = issuer_bytes.decode('utf-8', errors='ignore')
                        idx += length
                    else:
                        # 跳過其他未知的 field (簡單處理：假設都是 length-delimited 或 varint)
                        # 這裡為了簡化，如果遇到未知的，我們直接跳到 end_idx，因為我們只要 name 和 secret
                        # 這是比較粗略的解析，但對 Google Auth 匯出通常夠用
                        if decoded_data[idx-1] & 0x07 == 2: # length-delimited
                            length = decoded_data[idx]
                            idx += 1 + length
                        elif decoded_data[idx-1] & 0x07 == 0: # varint
                            while decoded_data[idx] & 0x80:
                                idx += 1
                            idx += 1
                        else:
                            idx = end_idx # 無法解析，跳出內部迴圈
                
                display_name = f"{issuer} - {name}" if issuer else name
                
                print(f"[+] 帳號名稱: {display_name}")
                print(f"    Secret Key: {secret_b32}")
                print("-" * 50)
                found = True
                
                # 確保 idx 指向正確的下一個區塊
                idx = end_idx
                
            else:
                idx += 1
                
        if not found:
            print("[-] 未在資料中找到 Secret Key。")
            
    except Exception as e:
        print(f"[-] 解析失敗: {e}")

def main():
    image_path = os.path.join(os.path.dirname(__file__), "demo.png")
    
    print(f"\n[*] 正在讀取照片: {image_path}")
    
    try:
        # 使用 OpenCV 內建的 QR Code 讀取器
        image = cv2.imread(image_path)
        if image is None:
            print(f"[-] 錯誤：無法讀取圖片檔案，請確認路徑是否正確：{image_path}")
            return

        detector = cv2.QRCodeDetector()
        
        # 偵測並解碼
        data, vertices_array, _ = detector.detectAndDecode(image)
        
        if not data:
            print("[-] OpenCV 無法從照片中讀取 QR Code。")
            print("    建議：請確保照片清晰、沒有嚴重反光，且 QR Code 佔據畫面大部分。")
            
            # 嘗試一個小技巧：有時候 Photo Booth 拍的照片是左右相反的 (鏡像)
            # 我們嘗試把它翻轉過來再讀一次
            print("[*] 嘗試將照片水平翻轉後再次讀取...")
            flipped_image = cv2.flip(image, 1)
            data, _, _ = detector.detectAndDecode(flipped_image)
            
            if not data:
                print("[-] 翻轉後依然無法讀取。請重新拍一張更清晰、正面的照片。")
                return
            else:
                print("[+] 翻轉照片後成功讀取！(Photo Booth 預設會產生鏡像照片)")
            
        print(f"[+] 成功讀取 QR Code 內容！")
        
        if data.startswith("otpauth-migration://"):
            decode_migration_uri(data)
        else:
            print(f"[-] 讀取到的內容不是 Google Authenticator 匯出格式: {data}")
            
    except Exception as e:
        print(f"[-] 發生錯誤: {e}")

if __name__ == "__main__":
    main()