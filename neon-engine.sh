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
LOCAL_ENGINE="$HOME/.neon-core-engine"
PUBLIC_ENGINE="/sdcard/Download/.neon-core-engine"
SETUP_FILE="/sdcard/Download/neon-core-setup.sh"
RUN_CMD="sh /sdcard/Download/neon-core-setup.sh"

line() {
  printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
}

banner() {
  printf "$M"
  printf " _   _                  ____               \n"
  printf "| \\ | | ___  ___  _ __ / ___|___  _ __ ___ \n"
  printf "|  \\| |/ _ \\/ _ \\| '_ \\ |   / _ \\| '__/ _ \\\n"
  printf "| |\\  |  __/ (_) | | | | |__| (_) | | |  __/\n"
  printf "|_| \\_|\\___|\\___/|_| |_|\\____\\___/|_|  \\___|\n"
  printf "                                            \n"
  printf "        N E O N   C O R E   E N G I N E\n"
  printf "$N\n"
}

banner

printf "$Y"
printf "╔════════════════════════════════════════════╗\n"
printf "║          NEON ENGINE INSTALLER            ║\n"
printf "║        TERMUX TO ANDROID SHELL KIT         ║\n"
printf "╚════════════════════════════════════════════╝\n"
printf "$N\n"

printf "$W[•] Developer  : Agung Dev$N\n"
printf "$W[•] Domain     : neonmagisk.my.id$N\n"
printf "$W[•] Engine     : Neon Core Engine$N\n"
printf "$W[•] Output     : $SETUP_FILE$N\n\n"

sleep 1
line

printf "$B[1/6] Detecting device platform...$N\n"

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

printf "$G[✓] Platform detected : ${ABI:-unknown}$N\n"
printf "$G[✓] Engine package    : ready$N\n\n"

sleep 1
line

printf "$B[2/6] Checking storage access...$N\n"

if [ ! -d "/sdcard/Download" ]; then
  termux-setup-storage
  sleep 2
fi

if [ ! -d "/sdcard/Download" ]; then
  printf "$R[!] Storage belum aktif.$N\n"
  printf "$Y[!] Izinkan akses storage Termux lalu jalankan ulang.$N\n"
  exit 1
fi

printf "$G[✓] Storage ready$N\n\n"

sleep 1
line

printf "$B[3/6] Checking downloader...$N\n"

if command -v curl >/dev/null 2>&1; then
  DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOADER="wget"
else
  printf "$R[!] Downloader tidak ditemukan.$N\n"
  printf "$Y[!] Jalankan dulu:$N\n"
  printf "$W    pkg install curl -y$N\n"
  exit 1
fi

printf "$G[✓] Downloader ready : $DOWNLOADER$N\n\n"

sleep 1
line

printf "$B[4/6] Cleaning old files...$N\n"

cd "$HOME" || exit 1

rm -f "$LOCAL_ENGINE"
rm -f "$PUBLIC_ENGINE"
rm -f "$SETUP_FILE"
rm -f /sdcard/Download/neon-core-start.sh

printf "$G[✓] Clean install ready$N\n\n"

sleep 1
line

printf "$B[5/6] Downloading Neon Core Engine package...$N\n"

DOWNLOAD_URL="$BASE_URL/$ENGINE_FILE"

if [ "$DOWNLOADER" = "curl" ]; then
  curl -L --fail --connect-timeout 15 --max-time 120 --retry 2 --retry-delay 2 --silent --show-error "$DOWNLOAD_URL" -o "$LOCAL_ENGINE"
else
  wget -T 120 -q -O "$LOCAL_ENGINE" "$DOWNLOAD_URL"
fi

if [ ! -f "$LOCAL_ENGINE" ]; then
  printf "$R[!] Download package gagal.$N\n"
  printf "$Y[!] Cek koneksi internet lalu jalankan ulang.$N\n"
  exit 1
fi

SIZE="$(wc -c < "$LOCAL_ENGINE" 2>/dev/null)"

if [ -z "$SIZE" ] || [ "$SIZE" -lt 100000 ]; then
  printf "$R[!] File package tidak valid.$N\n"
  rm -f "$LOCAL_ENGINE"
  exit 1
fi

chmod 755 "$LOCAL_ENGINE"
cp "$LOCAL_ENGINE" "$PUBLIC_ENGINE"
chmod 755 "$PUBLIC_ENGINE"

printf "$G[✓] Neon Core Engine package ready$N\n\n"

sleep 1
line

printf "$B[6/6] Creating Neon Core setup file...$N\n"

{
printf '%s\n' '#!/system/bin/sh'
printf '%s\n' ''
printf '%s\n' 'clear'
printf '%s\n' ''
printf '%s\n' 'R="\033[1;31m"'
printf '%s\n' 'G="\033[1;32m"'
printf '%s\n' 'Y="\033[1;33m"'
printf '%s\n' 'B="\033[1;34m"'
printf '%s\n' 'C="\033[1;36m"'
printf '%s\n' 'M="\033[1;35m"'
printf '%s\n' 'W="\033[1;37m"'
printf '%s\n' 'N="\033[0m"'
printf '%s\n' ''
printf '%s\n' 'SRC="/sdcard/Download/.neon-core-engine"'
printf '%s\n' 'CORE="/data/local/tmp/.neon-core-engine"'
printf '%s\n' 'HOME_DIR="/data/local/tmp/neon-core"'
printf '%s\n' 'BIN_DIR="/data/local/tmp/neon-core/bin"'
printf '%s\n' 'ENV_FILE="/data/local/tmp/neon-core/env.sh"'
printf '%s\n' ''
printf '%s\n' 'printf "$M"'
printf '%s\n' 'printf " _   _                  ____               \n"'
printf '%s\n' 'printf "| \\ | | ___  ___  _ __ / ___|___  _ __ ___ \n"'
printf '%s\n' 'printf "|  \\| |/ _ \\/ _ \\| '"'"'_ \\ |   / _ \\| '"'"'__/ _ \\\n"'
printf '%s\n' 'printf "| |\\  |  __/ (_) | | | | |__| (_) | | |  __/\n"'
printf '%s\n' 'printf "|_| \\_|\\___|\\___/|_| |_|\\____\\___/|_|  \\___|\n"'
printf '%s\n' 'printf "                                            \n"'
printf '%s\n' 'printf "        N E O N   C O R E   E N G I N E\n"'
printf '%s\n' 'printf "$N\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"'
printf '%s\n' 'printf "$B[1/5] Resetting old engine files...$N\n"'
printf '%s\n' ''
printf '%s\n' 'rm -rf "$HOME_DIR"'
printf '%s\n' 'rm -f "$CORE"'
printf '%s\n' 'rm -f /data/local/tmp/neon'
printf '%s\n' ''
printf '%s\n' 'printf "$G[✓] Reset complete$N\n\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"'
printf '%s\n' 'printf "$B[2/5] Installing engine core...$N\n"'
printf '%s\n' ''
printf '%s\n' 'if [ ! -f "$SRC" ]; then'
printf '%s\n' '  printf "$R[!] Engine package tidak ditemukan.$N\n"'
printf '%s\n' '  printf "$Y[!] Jalankan installer dari Termux terlebih dahulu.$N\n"'
printf '%s\n' '  exit 1'
printf '%s\n' 'fi'
printf '%s\n' ''
printf '%s\n' 'cp "$SRC" "$CORE" 2>/dev/null || cat "$SRC" > "$CORE"'
printf '%s\n' 'chmod 755 "$CORE"'
printf '%s\n' ''
printf '%s\n' 'if ! "$CORE" --help >/dev/null 2>&1; then'
printf '%s\n' '  printf "$R[!] Engine core gagal dijalankan di Android shell.$N\n"'
printf '%s\n' '  printf "$Y[!] File ada, tapi tidak bisa dieksekusi di sesi ini.$N\n"'
printf '%s\n' '  exit 1'
printf '%s\n' 'fi'
printf '%s\n' ''
printf '%s\n' 'printf "$G[✓] Engine core installed$N\n\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"'
printf '%s\n' 'printf "$B[3/5] Creating Neon shortcuts...$N\n"'
printf '%s\n' ''
printf '%s\n' 'mkdir -p "$BIN_DIR"'
printf '%s\n' 'cp "$CORE" "$BIN_DIR/.core"'
printf '%s\n' 'chmod 755 "$BIN_DIR/.core"'
printf '%s\n' ''
printf '%s\n' 'cd "$BIN_DIR" || exit 1'
printf '%s\n' './.core --install -s .'
printf '%s\n' ''
printf '%s\n' 'printf "%s\n" "#!/system/bin/sh" > "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "CORE=\"/data/local/tmp/neon-core/bin/.core\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "if [ \"\$1\" = \"\" ]; then" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"Neon Core Engine\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"Usage:\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"  neon shell\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"  neon find /sdcard -type f -size +100M\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"  neon wget --help\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"  neon df -h\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  echo \"  neon ps\"" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  exit 0" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "fi" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "if [ \"\$1\" = \"shell\" ]; then" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "  exec \"\$CORE\" sh" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "fi" >> "$BIN_DIR/neon"'
printf '%s\n' 'printf "%s\n" "exec \"\$CORE\" \"\$@\"" >> "$BIN_DIR/neon"'
printf '%s\n' ''
printf '%s\n' 'chmod 755 "$BIN_DIR/neon"'
printf '%s\n' 'ln -sf "$BIN_DIR/neon" /data/local/tmp/neon'
printf '%s\n' ''
printf '%s\n' 'printf "$G[✓] Shortcut created: neon$N\n\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"'
printf '%s\n' 'printf "$B[4/5] Activating Neon environment...$N\n"'
printf '%s\n' ''
printf '%s\n' 'printf "%s\n" "export PATH=\"/data/local/tmp/neon-core/bin:/data/local/tmp:\$PATH\"" > "$ENV_FILE"'
printf '%s\n' 'chmod 755 "$ENV_FILE"'
printf '%s\n' 'export PATH="/data/local/tmp/neon-core/bin:/data/local/tmp:$PATH"'
printf '%s\n' ''
printf '%s\n' 'printf "$G[✓] Environment activated$N\n\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"'
printf '%s\n' 'printf "$B[5/5] Finalizing setup...$N\n"'
printf '%s\n' ''
printf '%s\n' 'printf "$G[✓] Neon Core Engine is ready$N\n\n"'
printf '%s\n' 'printf "$WAvailable commands:$N\n"'
printf '%s\n' 'printf "$C  neon$N\n"'
printf '%s\n' 'printf "$C  neon shell$N\n"'
printf '%s\n' 'printf "$C  neon find$N\n"'
printf '%s\n' 'printf "$C  neon wget$N\n"'
printf '%s\n' 'printf "$C  neon df$N\n"'
printf '%s\n' 'printf "$C  neon ps$N\n"'
printf '%s\n' 'printf "$C  find$N\n"'
printf '%s\n' 'printf "$C  grep$N\n"'
printf '%s\n' 'printf "$C  awk$N\n"'
printf '%s\n' 'printf "$C  sed$N\n"'
printf '%s\n' 'printf "$C  wget$N\n"'
printf '%s\n' 'printf "$C  tar$N\n"'
printf '%s\n' 'printf "$C  unzip$N\n\n"'
printf '%s\n' 'printf "$YUntuk sesi berikutnya, jalankan:$N\n"'
printf '%s\n' 'printf "$W. /data/local/tmp/neon-core/env.sh$N\n\n"'
printf '%s\n' 'printf "$GOpening Neon shell...$N\n"'
printf '%s\n' 'neon shell'
} > "$SETUP_FILE"

chmod 755 "$SETUP_FILE"

if [ ! -s "$SETUP_FILE" ]; then
  printf "$R[!] Gagal membuat setup file.$N\n"
  exit 1
fi

if command -v termux-clipboard-set >/dev/null 2>&1; then
  printf "%s" "$RUN_CMD" | termux-clipboard-set
  CLIP_STATUS="copied"
else
  CLIP_STATUS="manual"
fi

printf "$G[✓] Setup file ready$N\n\n"

sleep 1
line

printf "$G"
printf " ____                 _       \n"
printf "|  _ \\ ___  __ _  __| |_   _ \n"
printf "| |_) / _ \\/ _\` |/ _\` | | | |\n"
printf "|  _ <  __/ (_| | (_| | |_| |\n"
printf "|_| \\_\\___|\\__,_|\\__,_|\\__, |\n"
printf "                        |___/ \n"
printf "$N"

printf "\n$G[✓] TERMUX SETUP SUCCESS$N\n\n"

printf "$C[•] Neon Core Engine setup file:$N\n"
printf "$W    $SETUP_FILE$N\n\n"

printf "$Y"
printf "╔════════════════════════════════════════════╗\n"
printf "║       COPY COMMAND BELOW                   ║\n"
printf "║       RUN IN NEON CORE ENGINE              ║\n"
printf "╚════════════════════════════════════════════╝\n"
printf "$N\n"

printf "$W"
printf "┌────────────────────────────────────────────┐\n"
printf "│ sh /sdcard/Download/neon-core-setup.sh     │\n"
printf "└────────────────────────────────────────────┘\n"
printf "$N\n"

printf "$C%s$N\n\n" "$RUN_CMD"

if [ "$CLIP_STATUS" = "copied" ]; then
  printf "$G[✓] Command sudah dicopy ke clipboard.$N\n"
else
  printf "$Y[!] Copy satu baris command di atas.$N\n"
fi

printf "$G[✓] Done.$N\n"
