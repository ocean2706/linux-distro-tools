#!/usr/bin/env bash
#@version: 0.0.1 20261023
#@changelog:
#@todo:
#@description:
#@help:
##### created with gemini  
######### how to use it
###
### chmod +x setup-totp-mfa.sh
### sudo ./setup-totp-mfa.sh yourusername
##########
# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: This script must be run as root." >&2
  exit 1
fi

# Check if username argument is provided
if [ -z "$1" ]; then
  echo "[-] Usage: $0 <username>" >&2
  exit 1
fi

USERNAME="$1"
OATH_FILE="/etc/users.oath"

# 1. Verify user exists (works for both local files and LDAP via getent)
if ! getent passwd "$USERNAME" >/dev/null 2>&1; then
  echo "[-] Error: User '$USERNAME' does not exist on this system (checked local & LDAP)." >&2
  exit 1
fi
echo "[+] Success: User '$USERNAME' found."

# 2. Ensure prerequisites (oathtool, pam_oath) are installed
echo "[*] Checking/Installing required packages..."
if command -v dnf &>/dev/null; then
  dnf install -y oathtool pam_oath qrencode
elif command -v apt-get &>/dev/null; then
  apt-get update && apt-get install -y oathtool libpam-oath qrencode
else
  echo "[-] Error: Unsupported package manager. Please ensure 'oathtool' and 'pam_oath' are installed." >&2
  exit 1
fi

# 3. Generate a secure 32-character Base32 secret key
SECRET_HEX=$(openssl rand -hex 20)
# Convert hex secret to base32 compatible format for apps/oathtool
SECRET_BASE32=$(python3 -c "import base64, sys; print(base64.b32encode(bytes.fromhex('$SECRET_HEX')).decode('utf-8').strip('='))")

# 4. Configure /etc/users.oath
touch "$OATH_FILE"
chmod 600 "$OATH_FILE"
chown root:root "$OATH_FILE"

# Remove existing entry for this user if re-running script, then add new one
if grep -qE "^[[:space:]]*HOTP/T30[[:space:]]+$USERNAME[[:space:]]" "$OATH_FILE"; then
  sed -i "/^[[:space:]]*HOTP\/T30[[:space:]]\+$USERNAME[[:space:]]/d" "$OATH_FILE"
fi

# Format for pam_oath: HOTP/T30    username    pin    secret
echo "HOTP/T30    $USERNAME    -    $SECRET_BASE32" >> "$OATH_FILE"
echo "[+] Updated $OATH_FILE for user '$USERNAME'."

# 5. Save the secret securely inside the user's home directory (if home exists and is accessible)
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
if [ -d "$USER_HOME" ]; then
  SECRET_PATH="$USER_HOME/.totp_secret"
  echo "$SECRET_BASE32" > "$SECRET_PATH"
  chown "$(getent passwd "$USERNAME" | cut -d: -f3):$(getent passwd "$USERNAME" | cut -d: -f4)" "$SECRET_PATH"
  chmod 600 "$SECRET_PATH"
  
  # Inject terminal generator alias into .bashrc if not already present
  BASHRC="$USER_HOME/.bashrc"
  if [ -f "$BASHRC" ] || touch "$BASHRC" 2>/dev/null; then
    if ! grep -q "alias totp=" "$BASHRC"; then
      echo "alias totp='oathtool --totp -b \$(cat ~/.totp_secret)'" >> "$BASHRC"
      echo "[+] Added 'totp' terminal alias to $BASHRC"
    fi
  fi
fi

# 6. Configure PAM stack (system-auth / common-auth) to enforce TOTP for this user
PAM_FILE=""
if [ -f /etc/pam.d/system-auth ]; then
  PAM_FILE="/etc/pam.d/system-auth"
elif [ -f /etc/pam.d/common-auth ]; then
  PAM_FILE="/etc/pam.d/common-auth"
fi

if [ -n "$PAM_FILE" ]; then
  # Check if rule for this user already exists to avoid duplication
  if ! grep -q "pam_succeed_if.so user = $USERNAME" "$PAM_FILE"; then
    # Insert rule at the very top of the auth stack
    # This evaluates: If user matches, require pam_oath. Otherwise skip.
    TEMP_PAM=$(mktemp)
    echo "auth [success=1 default=ignore] pam_succeed_if.so user = $USERNAME" > "$TEMP_PAM"
    echo "auth required pam_oath.so usersfile=$OATH_FILE window=3 digits=6" >> "$TEMP_PAM"
    cat "$PAM_FILE" >> "$TEMP_PAM"
    cat "$TEMP_PAM" > "$PAM_FILE"
    rm -f "$TEMP_PAM"
    echo "[+] Configured PAM rule in $PAM_FILE"
  fi
fi

# 7. Output connection details for the central/totp server distribution
HOSTNAME_STR=$(hostname)
OTP_URL="otpauth://totp/${USERNAME}@${HOSTNAME_STR}?secret=${SECRET_BASE32}&issuer=LinuxMFA"

echo ""
echo "=================================================================="
echo "          MFA SETUP COMPLETE FOR: $USERNAME                       "
echo "=================================================================="
echo "1. Terminal Generation Command (on destination or local server):"
echo "   oathtool --totp -b $SECRET_BASE32"
echo ""
echo "2. Mobile App URI (Import into Google Authenticator / Aegis):"
echo "   $OTP_URL"
echo ""
echo "3. ASCII QR Code for terminal scanning:"
qrencode -t UTF8 "$OTP_URL"
echo "=================================================================="
