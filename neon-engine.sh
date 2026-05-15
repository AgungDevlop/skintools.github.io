#!/system/bin/sh

clear

R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
M="\033[1;35m"
W="\033[1;37m"
N="\033[0m"

BASE_URL="https://raw.githubusercontent.com/Magisk-Modules-Repo/busybox-ndk/master"
LOCAL_ENGINE="$HOME/neon-core-engine.bin"
PUBLIC_ENGINE="/sdcard/Download/neon-core-engine.bin"
SETUP_FILE="/sdcard/Download/neon-core-setup.sh"
RUN_SETUP="sh /sdcard/Download/neon-core-setup.sh"
RUN_NEXT=". /data/local/tmp/neon-core/env.sh; neon shell"

line() {
  printf "%b\n" "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N"
}

printf "%b" "$M"
printf "%s\n" " _   _                  ____"
printf "%s\n" "| \ | | ___  ___  _ __ / ___|___  _ __ ___"
printf "%s\n" "|  \| |/ _ \/ _ \| '_ \ |   / _ \| '__/ _ \\"
printf "%s\n" "| |\  |  __/ (_) | | | | |__| (_) | | |  __/"
printf "%s\n" "|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|"
printf "%s\n" "        N E O N   C O R E   E N G I N E"
printf "%b\n" "$N"

printf "%b\n" "$Y╔════════════════════════════════════════════╗$N"
printf "%b\n" "$Y║          NEON ENGINE INSTALLER            ║$N"
printf "%b\n" "$Y║        TERMUX TO ANDROID SHELL KIT         ║$N"
printf "%b\n" "$Y╚════════════════════════════════════════════╝$N"

printf "\n%b\n" "$W[•] Developer  : Agung Dev$N"
printf "%b\n" "$W[•] Domain     : neonmagisk.my.id$N"
printf "%b\n" "$W[•] Engine     : Neon Core Engine$N"
printf "%b\n\n" "$W[•] Output     : $SETUP_FILE$N"

line
printf "%b\n" "$B[1/6] Detecting device platform...$N"

ABI="$(getprop ro.product.cpu.abi 2>/dev/null)"

case "$ABI" in
  arm64-v8a)
    ENGINE_FILE="busybox-arm64"
    ;;
  armeabi-v7a|armeabi)
    ENGINE_FILE="busybox-arm"
    ;;
  x86)
    ENGINE_FILE="busybox-x86"
    ;;
  x86_64)
    ENGINE_FILE="busybox-x86_64"
    ;;
  *)
    ENGINE_FILE="busybox-arm64"
    ;;
esac

printf "%b\n" "$G[✓] Platform detected : ${ABI:-unknown}$N"
printf "%b\n\n" "$G[✓] Engine package    : ready$N"

line
printf "%b\n" "$B[2/6] Checking storage access...$N"

if [ ! -d "/sdcard/Download" ]; then
  termux-setup-storage
  sleep 2
fi

if [ ! -d "/sdcard/Download" ]; then
  printf "%b\n" "$R[!] Storage belum aktif.$N"
  printf "%b\n" "$Y[!] Izinkan akses storage Termux lalu jalankan ulang.$N"
  exit 1
fi

printf "%b\n\n" "$G[✓] Storage ready$N"

line
printf "%b\n" "$B[3/6] Checking downloader...$N"

if command -v curl >/dev/null 2>&1; then
  DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOADER="wget"
else
  printf "%b\n" "$R[!] Downloader tidak ditemukan.$N"
  printf "%b\n" "$Y[!] Jalankan dulu: pkg install curl -y$N"
  exit 1
fi

printf "%b\n\n" "$G[✓] Downloader ready : $DOWNLOADER$N"

line
printf "%b\n" "$B[4/6] Cleaning old files...$N"

rm -f "$LOCAL_ENGINE"
rm -f "$PUBLIC_ENGINE"
rm -f "$SETUP_FILE"
rm -f /sdcard/Download/neon-core-start.sh
rm -f /sdcard/Download/neon.sh

printf "%b\n\n" "$G[✓] Clean install ready$N"

line
printf "%b\n" "$B[5/6] Downloading Neon Core Engine package...$N"

DOWNLOAD_URL="$BASE_URL/$ENGINE_FILE"

if [ "$DOWNLOADER" = "curl" ]; then
  curl -L --fail --connect-timeout 15 --max-time 120 --retry 2 --retry-delay 2 --silent --show-error "$DOWNLOAD_URL" -o "$LOCAL_ENGINE"
else
  wget -T 120 -q -O "$LOCAL_ENGINE" "$DOWNLOAD_URL"
fi

if [ ! -f "$LOCAL_ENGINE" ]; then
  printf "%b\n" "$R[!] Download package gagal.$N"
  exit 1
fi

SIZE="$(wc -c < "$LOCAL_ENGINE" 2>/dev/null)"

if [ -z "$SIZE" ] || [ "$SIZE" -lt 100000 ]; then
  printf "%b\n" "$R[!] File package tidak valid.$N"
  rm -f "$LOCAL_ENGINE"
  exit 1
fi

chmod 755 "$LOCAL_ENGINE"
cp "$LOCAL_ENGINE" "$PUBLIC_ENGINE"
chmod 755 "$PUBLIC_ENGINE"

printf "%b\n\n" "$G[✓] Neon Core Engine package ready$N"

line
printf "%b\n" "$B[6/6] Creating Neon Core setup file...$N"

cat > "$SETUP_FILE" <<'NEON_SETUP_EOF'
#!/system/bin/sh

clear

SRC="/sdcard/Download/neon-core-engine.bin"
HOME_DIR="/data/local/tmp/neon-core"
BIN_DIR="/data/local/tmp/neon-core/bin"
CORE="/data/local/tmp/neon-core/bin/busybox"
ENV_FILE="/data/local/tmp/neon-core/env.sh"
NEON_LINK="/data/local/tmp/neon"

printf '\033[1;35m'
printf '%s\n' ' _   _                  ____'
printf '%s\n' '| \ | | ___  ___  _ __ / ___|___  _ __ ___'
printf '%s\n' '|  \| |/ _ \/ _ \| _  \ |   / _ \| __/ _ \'
printf '%s\n' '| |\  |  __/ (_) | | | | |__| (_) | | |  __/'
printf '%s\n' '|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|'
printf '%s\n' '        N E O N   C O R E   E N G I N E'
printf '\033[0m\n'

printf '\033[1;36m%s\033[0m\n' '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[1;34m[1/5] Resetting old engine files...\033[0m\n'

rm -rf "$HOME_DIR"
rm -f "$NEON_LINK"
mkdir -p "$BIN_DIR"

printf '\033[1;32m[✓] Reset complete\033[0m\n\n'

printf '\033[1;36m%s\033[0m\n' '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[1;34m[2/5] Installing engine core...\033[0m\n'

if [ ! -f "$SRC" ]; then
  printf '\033[1;31m[!] Engine package tidak ditemukan.\033[0m\n'
  printf '\033[1;33m[!] Jalankan installer dari Termux terlebih dahulu.\033[0m\n'
  exit 1
fi

cp "$SRC" "$CORE" 2>/dev/null || cat "$SRC" > "$CORE"
chmod 755 "$CORE"

if ! "$CORE" --help >/dev/null 2>&1; then
  printf '\033[1;31m[!] Engine core gagal dijalankan.\033[0m\n'
  ls -l "$CORE" 2>/dev/null
  uname -m 2>/dev/null
  getprop ro.product.cpu.abi 2>/dev/null
  exit 1
fi

printf '\033[1;32m[✓] Engine core installed\033[0m\n\n'

printf '\033[1;36m%s\033[0m\n' '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[1;34m[3/5] Creating Neon shortcuts...\033[0m\n'

cd "$BIN_DIR" || exit 1
"$CORE" --install -s "$BIN_DIR"

cat > "$BIN_DIR/neon" <<'NEON_BIN_EOF'
#!/system/bin/sh

CORE="/data/local/tmp/neon-core/bin/busybox"

if [ "$1" = "" ]; then
  echo "Neon Core Engine"
  echo "Usage:"
  echo "  neon shell"
  echo "  neon find /sdcard -type f -size +100M"
  echo "  neon wget --help"
  echo "  neon df -h"
  echo "  neon ps"
  exit 0
fi

if [ "$1" = "shell" ]; then
  exec "$CORE" sh
fi

exec "$CORE" "$@"
NEON_BIN_EOF

chmod 755 "$BIN_DIR/neon"
ln -sf "$BIN_DIR/neon" "$NEON_LINK"

cat > "$ENV_FILE" <<'ENV_EOF'
export PATH="/data/local/tmp/neon-core/bin:/data/local/tmp:$PATH"
ENV_EOF

chmod 755 "$ENV_FILE"
export PATH="/data/local/tmp/neon-core/bin:/data/local/tmp:$PATH"

printf '\033[1;32m[✓] Shortcut created: neon\033[0m\n'
printf '\033[1;32m[✓] Env created: /data/local/tmp/neon-core/env.sh\033[0m\n\n'

printf '\033[1;36m%s\033[0m\n' '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[1;34m[4/5] Activating Neon environment...\033[0m\n'
printf '\033[1;32m[✓] Environment activated for this session\033[0m\n\n'

printf '\033[1;36m%s\033[0m\n' '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[1;34m[5/5] Finalizing setup...\033[0m\n'

printf '\033[1;32m[✓] Neon Core Engine is ready\033[0m\n\n'

printf '\033[1;37mGunakan untuk sesi berikutnya:\033[0m\n'
printf '\033[1;36m. /data/local/tmp/neon-core/env.sh; neon shell\033[0m\n\n'

printf '\033[1;32mOpening Neon shell...\033[0m\n'
exec "$CORE" sh
NEON_SETUP_EOF

chmod 755 "$SETUP_FILE"

if [ ! -s "$SETUP_FILE" ]; then
  printf "%b\n" "$R[!] Gagal membuat setup file.$N"
  exit 1
fi

printf "%b\n\n" "$G[✓] Setup file ready$N"

line

printf "%b\n" "$G[✓] TERMUX SETUP SUCCESS$N"
printf "%b\n" "$C[•] Neon Core Engine setup file:$N"
printf "%b\n\n" "$W    $SETUP_FILE$N"

printf "%b\n" "$Y╔════════════════════════════════════════════╗$N"
printf "%b\n" "$Y║       STEP 1: RUN IN NEON CORE ENGINE      ║$N"
printf "%b\n" "$Y╚════════════════════════════════════════════╝$N"
printf "\n%b\n\n" "$C$RUN_SETUP$N"

printf "%b\n" "$Y╔════════════════════════════════════════════╗$N"
printf "%b\n" "$Y║       STEP 2: NEXT SESSION COMMAND         ║$N"
printf "%b\n" "$Y╚════════════════════════════════════════════╝$N"
printf "\n%b\n\n" "$C$RUN_NEXT$N"

printf "%b\n" "$G[✓] Done.$N"

exit 0
