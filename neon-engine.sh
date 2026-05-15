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
PAGE_URL="https://neonmagisk.my.id"
LOCAL_ENGINE="$HOME/.neon-core-engine"
PUBLIC_ENGINE="/sdcard/Download/.neon-core-engine"
SETUP_FILE="/sdcard/Download/neon-core-setup.sh"
RUN_CMD="sh /sdcard/Download/neon-core-setup.sh"

line() {
  printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
}

show_banner() {
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

show_banner

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
  printf "$Y[!] Izinkan akses storage Termux, lalu jalankan ulang.$N\n"
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
  curl -L --fail --silent --show-error "$DOWNLOAD_URL" -o "$LOCAL_ENGINE"
else
  wget -q -O "$LOCAL_ENGINE" "$DOWNLOAD_URL"
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

printf "$B[6/6] Downloading Neon Core setup file...$N\n"

SETUP_URL="$PAGE_URL/neon-core-setup.sh"

if [ "$DOWNLOADER" = "curl" ]; then
  curl -L --fail --silent --show-error "$SETUP_URL?$(date +%s)" -o "$SETUP_FILE"
else
  wget -q -O "$SETUP_FILE" "$SETUP_URL?$(date +%s)"
fi

if [ ! -f "$SETUP_FILE" ]; then
  printf "$R[!] Setup file gagal diunduh.$N\n"
  printf "$Y[!] Pastikan file neon-core-setup.sh ada di root GitHub Pages.$N\n"
  exit 1
fi

if ! grep -q "NEON_CORE_SETUP_FILE" "$SETUP_FILE" 2>/dev/null; then
  printf "$R[!] Setup file tidak valid.$N\n"
  printf "$Y[!] Cek isi https://neonmagisk.my.id/neon-core-setup.sh$N\n"
  rm -f "$SETUP_FILE"
  exit 1
fi

chmod 755 "$SETUP_FILE"

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
