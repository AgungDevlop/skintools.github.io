#!/system/bin/sh

NEON_CORE_SETUP_FILE="1"

clear

R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
M="\033[1;35m"
W="\033[1;37m"
N="\033[0m"

SRC="/sdcard/Download/.neon-core-engine"
CORE="/data/local/tmp/.neon-core-engine"
HOME_DIR="/data/local/tmp/neon-core"
BIN_DIR="/data/local/tmp/neon-core/bin"
ENV_FILE="/data/local/tmp/neon-core/env.sh"

printf "$M"
printf " _   _                  ____               \n"
printf "| \\ | | ___  ___  _ __ / ___|___  _ __ ___ \n"
printf "|  \\| |/ _ \\/ _ \\| '_ \\ |   / _ \\| '__/ _ \\\n"
printf "| |\\  |  __/ (_) | | | | |__| (_) | | |  __/\n"
printf "|_| \\_|\\___|\\___/|_| |_|\\____\\___/|_|  \\___|\n"
printf "                                            \n"
printf "        N E O N   C O R E   E N G I N E\n"
printf "$N\n"

printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
printf "$B[1/5] Resetting old engine files...$N\n"

rm -rf "$HOME_DIR"
rm -f "$CORE"
rm -f /data/local/tmp/neon

printf "$G[✓] Reset complete$N\n\n"

printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
printf "$B[2/5] Installing engine core...$N\n"

if [ ! -f "$SRC" ]; then
  printf "$R[!] Engine package tidak ditemukan.$N\n"
  printf "$Y[!] Jalankan installer dari Termux terlebih dahulu.$N\n"
  exit 1
fi

cp "$SRC" "$CORE" 2>/dev/null || cat "$SRC" > "$CORE"
chmod 755 "$CORE"

if ! "$CORE" --help >/dev/null 2>&1; then
  printf "$R[!] Engine core gagal dijalankan di Android shell.$N\n"
  printf "$Y[!] File ada, tapi tidak bisa dieksekusi di sesi ini.$N\n"
  exit 1
fi

printf "$G[✓] Engine core installed$N\n\n"

printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
printf "$B[3/5] Creating Neon shortcuts...$N\n"

mkdir -p "$BIN_DIR"

cp "$CORE" "$BIN_DIR/.core"
chmod 755 "$BIN_DIR/.core"

cd "$BIN_DIR" || exit 1
./.core --install -s .

cat > "$BIN_DIR/neon" << 'NEONEOF'
#!/system/bin/sh

CORE="/data/local/tmp/neon-core/bin/.core"

if [ "$1" = "" ]; then
  echo "Neon Core Engine"
  echo ""
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
NEONEOF

chmod 755 "$BIN_DIR/neon"
ln -sf "$BIN_DIR/neon" /data/local/tmp/neon

printf "$G[✓] Shortcut created: neon$N\n\n"

printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
printf "$B[4/5] Activating Neon environment...$N\n"

cat > "$ENV_FILE" << 'ENVEOF'
export PATH="/data/local/tmp/neon-core/bin:/data/local/tmp:$PATH"
ENVEOF

chmod 755 "$ENV_FILE"

export PATH="/data/local/tmp/neon-core/bin:/data/local/tmp:$PATH"

printf "$G[✓] Environment activated$N\n\n"

printf "$C━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
printf "$B[5/5] Finalizing setup...$N\n"

printf "$G[✓] Neon Core Engine is ready$N\n\n"

printf "$WAvailable commands:$N\n"
printf "$C  neon$N\n"
printf "$C  neon shell$N\n"
printf "$C  neon find$N\n"
printf "$C  neon wget$N\n"
printf "$C  neon df$N\n"
printf "$C  neon ps$N\n"
printf "$C  find$N\n"
printf "$C  grep$N\n"
printf "$C  awk$N\n"
printf "$C  sed$N\n"
printf "$C  wget$N\n"
printf "$C  tar$N\n"
printf "$C  unzip$N\n\n"

printf "$YUntuk sesi berikutnya, jalankan:$N\n"
printf "$W. /data/local/tmp/neon-core/env.sh$N\n\n"

printf "$GOpening Neon shell...$N\n"
neon shell
