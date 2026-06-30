#!/bin/zsh

# =============================================================================
# aws-auto-gen.sh — test AWS 憑證自動更新
#
# 用途：
#   AWS Session Token 每 2～3 天過期，連線 K8s 前需手動更新憑證。
#   本腳本自動完成以下流程：
#     1. 用 TOTP Secret 產生 MFA 6 位驗證碼
#     2. 以長期 AK/SK profile 向 STS 換取臨時 Session Token（有效期 36 小時）
#     3. 將臨時憑證寫入登入用 AWS profile
#
# 前置需求：
#   - 已安裝 AWS CLI、Python 3、pyotp
#   - ~/.aws/credentials 中已設定 AWS_USER_PROFILE（含長期 AK/SK）
# =============================================================================

# --- 設定區（依帳號修改此處即可） ---

TOTP_SECRET="T1234567890"
AWS_USER_PROFILE="123456789-no-mfa"   # 長期 AK/SK，用來向 STS 換取臨時 token
AWS_AUTH_PROFILE="123456789-sg"            # 實際登入 / kubectl 使用的 profile
ARN_OF_MFA="arn:aws:iam::123456789:mfa/jason-2fa-test"
SESSION_DURATION=129600                   # 臨時憑證有效期（秒），129600 = 36 小時

# --- 主流程 ---

AWS_CLI=$(which aws)
if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
fi
echo "Using AWS CLI found at $AWS_CLI"

MFA_TOKEN_CODE=$(python3 -c "import pyotp; print(pyotp.TOTP('${TOTP_SECRET}').now())")
if [ -z "$MFA_TOKEN_CODE" ]; then
  echo "Failed to generate OTP; exiting"
  exit 2
fi

echo ""
echo "================================================"
echo ""
echo "AWS-CLI Profile: $AWS_USER_PROFILE ***(用來讀取aws 長久型 token AK-xxxxxx 的帳號)"
echo "AWS Auth Profile: $AWS_AUTH_PROFILE ***(可登入的 aws login 帳號)"
echo "MFA ARN: $ARN_OF_MFA"
echo "MFA Token Code: $MFA_TOKEN_CODE (auto-generated)"
echo ""
echo "================================================"
echo ""
set -x

read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< \
$( aws --profile $AWS_USER_PROFILE sts get-session-token \
  --duration $SESSION_DURATION \
  --serial-number $ARN_OF_MFA \
  --token-code $MFA_TOKEN_CODE \
  --output text  | awk '{ print $2, $4, $5 }')

echo "AWS_ACCESS_KEY_ID: " $AWS_ACCESS_KEY_ID
echo "AWS_SECRET_ACCESS_KEY: " $AWS_SECRET_ACCESS_KEY
echo "AWS_SESSION_TOKEN: " $AWS_SESSION_TOKEN

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  exit 1
fi

aws --profile $AWS_AUTH_PROFILE configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws --profile $AWS_AUTH_PROFILE configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws --profile $AWS_AUTH_PROFILE configure set aws_session_token "$AWS_SESSION_TOKEN"
