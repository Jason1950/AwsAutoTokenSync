import sys
import time
import pyotp


def main():
    if len(sys.argv) != 2:
        print("[-] 用法: python3 check_auth_key.py <SECRET_KEY>")
        sys.exit(1)

    secret = sys.argv[1]

    try:
        print(f"\n[*] 正在產生 TOTP 驗證碼")
        print(f"[*] Secret Key: {secret}")

        totp = pyotp.TOTP(secret)
        code = totp.now()
        remaining = 30 - (int(time.time()) % 30)

        print("\n=== get key success ===")
        print(f"[+] 驗證碼: {code}")
        print(f"[+] 剩餘有效時間: {remaining} 秒")
        print("-" * 50)
    except Exception as e:
        print(f"[-] 錯誤: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
