#!/data/data/com.termux/files/usr/bin/sh
# Neon Core Engine - Termux to Android Shell BusyBox Installer
# Put this file at: https://neonmagisk.my.id/neon-engine.sh

set -u

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
M='\033[1;35m'
W='\033[1;37m'
N='\033[0m'

BASE_URL='https://raw.githubusercontent.com/Magisk-Modules-Repo/busybox-ndk/master'
LOCAL_DIR="$HOME/.neon-core"
LOCAL_BUSYBOX="$LOCAL_DIR/busybox"
PUBLIC_DIR='/sdcard/Download'
PUBLIC_BUSYBOX="$PUBLIC_DIR/busybox"
ADB_SETUP="$PUBLIC_DIR/neon-core-setup.sh"
ADB_SHORTCUT="$PUBLIC_DIR/neon"
TERMUX_SHORTCUT="$PREFIX/bin/neon-adb"

say() { printf '%b\n' "$1"; }
line() { printf '%b\n' "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
fail() { say "${R}[!] $1${N}"; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || return 1; }

clear 2>/dev/null || true

say "${M}"
say ' _   _                  ____'
say '| \ | | ___  ___  _ __ / ___|___  _ __ ___'
say '|  \| |/ _ \/ _ \| _  \ |   / _ \| __/ _ \'
say '| |\  |  __/ (_) | | | | |__| (_) | | |  __/'
say '|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|'
say '        N E O N   C O R E   E N G I N E'
say "${N}"

line
say "${B}[1/7] Checking Termux tools...${N}"

need_cmd curl || fail 'curl belum ada. Jalankan: pkg install curl -y'

mkdir -p "$LOCAL_DIR" || fail "Gagal membuat folder $LOCAL_DIR"

say "${G}[✓] curl ready${N}"

line
say "${B}[2/7] Checking storage access...${N}"

if [ ! -d "$PUBLIC_DIR" ]; then
  if need_cmd termux-setup-storage; then
    say "${Y}[•] Meminta akses storage Termux...${N}"
    termux-setup-storage >/dev/null 2>&1 || true
    sleep 2
  fi
fi

[ -d "$PUBLIC_DIR" ] || fail 'Storage belum aktif. Izinkan storage Termux, lalu jalankan ulang.'

say "${G}[✓] Storage ready: $PUBLIC_DIR${N}"

line
say "${B}[3/7] Detecting Android ABI...${N}"

ABI="$(getprop ro.product.cpu.abi 2>/dev/null || true)"

case "$ABI" in
  arm64-v8a)
    ENGINE_FILE='busybox-arm64'
    ;;
  armeabi-v7a|armeabi)
    ENGINE_FILE='busybox-arm'
    ;;
  x86)
    ENGINE_FILE='busybox-x86'
    ;;
  x86_64)
    ENGINE_FILE='busybox-x86_64'
    ;;
  *)
    UNAME_M="$(uname -m 2>/dev/null || true)"
    case "$UNAME_M" in
      aarch64|arm64*)
        ENGINE_FILE='busybox-arm64'
        ;;
      armv7*|arm*)
        ENGINE_FILE='busybox-arm'
        ;;
      i*86)
        ENGINE_FILE='busybox-x86'
        ;;
      x86_64)
        ENGINE_FILE='busybox-x86_64'
        ;;
      *)
        ENGINE_FILE='busybox-arm64'
        ;;
    esac
    ;;
esac

say "${G}[✓] ABI: ${ABI:-unknown}${N}"
say "${G}[✓] Package: $ENGINE_FILE${N}"

line
say "${B}[4/7] Downloading BusyBox static...${N}"

DOWNLOAD_URL="$BASE_URL/$ENGINE_FILE"

rm -f "$LOCAL_BUSYBOX" "$PUBLIC_BUSYBOX"

curl -L --fail --connect-timeout 15 --max-time 180 --retry 3 --retry-delay 2 \
  "$DOWNLOAD_URL" -o "$LOCAL_BUSYBOX" || fail 'Download BusyBox gagal. Cek internet atau URL source.'

SIZE="$(wc -c < "$LOCAL_BUSYBOX" 2>/dev/null || echo 0)"

[ "$SIZE" -gt 100000 ] || {
  rm -f "$LOCAL_BUSYBOX"
  fail 'File BusyBox tidak valid atau terlalu kecil.'
}

chmod 755 "$LOCAL_BUSYBOX" || fail 'chmod BusyBox gagal.'

cp "$LOCAL_BUSYBOX" "$PUBLIC_BUSYBOX" || fail "Gagal copy BusyBox ke $PUBLIC_BUSYBOX"
chmod 755 "$PUBLIC_BUSYBOX" || true

say "${G}[✓] BusyBox ready: $PUBLIC_BUSYBOX${N}"

line
say "${B}[5/7] Creating ADB installer...${N}"

cat > "$ADB_SETUP" <<'ADB_SETUP_EOF'
#!/system/bin/sh
# Neon Core Engine - Android shell side installer

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
M='\033[1;35m'
W='\033[1;37m'
N='\033[0m'

SRC='/sdcard/Download/busybox'
BASE='/data/local/tmp/bb'
BIN="$BASE/bin"
BB="$BIN/busybox"
ENV="$BASE/env.sh"
SHORTCUT_TMP='/data/local/tmp/neon'
SHORTCUT_SD='/sdcard/Download/neon'
WORK='/data/local/tmp/neon-work'
DUMP='/data/local/tmp/neon-dump'
LOG='/data/local/tmp/neon-log'

say() { printf '%b\n' "$1"; }
line() { printf '%b\n' "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
fail() { say "${R}[!] $1${N}"; exit 1; }

clear 2>/dev/null || true

say "${M}"
say ' _   _                  ____'
say '| \ | | ___  ___  _ __ / ___|___  _ __ ___'
say '|  \| |/ _ \/ _ \| _  \ |   / _ \| __/ _ \'
say '| |\  |  __/ (_) | | | | |__| (_) | | |  __/'
say '|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|'
say '        N E O N   C O R E   E N G I N E'
say "${N}"

line
say "${B}[1/5] Resetting old install...${N}"

rm -rf "$BASE"

mkdir -p "$BIN" "$WORK" "$DUMP" "$LOG" || fail 'Gagal membuat folder di /data/local/tmp.'

say "${G}[✓] Folder ready${N}"

line
say "${B}[2/5] Installing BusyBox...${N}"

[ -f "$SRC" ] || fail 'File /sdcard/Download/busybox tidak ditemukan. Jalankan neon-engine.sh dari Termux dulu.'

cp "$SRC" "$BB" 2>/dev/null || cat "$SRC" > "$BB" || fail 'Gagal copy BusyBox.'

chmod 755 "$BB" || fail 'chmod BusyBox gagal.'

"$BB" --help >/dev/null 2>&1 || fail 'BusyBox gagal dijalankan. Kemungkinan ABI tidak cocok.'

say "${G}[✓] BusyBox installed: $BB${N}"

line
say "${B}[3/5] Installing BusyBox applets...${N}"

cd "$BIN" || fail 'Gagal masuk folder bin.'

"$BB" --install -s "$BIN" >/dev/null 2>&1 || fail 'Gagal membuat shortcut command BusyBox.'

say "${G}[✓] Applets installed${N}"

line
say "${B}[4/5] Creating auto environment and shortcuts...${N}"

cat > "$ENV" <<'ENV_EOF'
export PATH="/data/local/tmp/bb/bin:$PATH"
export TMPDIR="/data/local/tmp"
export NEON_HOME="/data/local/tmp"
export NEON_WORK="/data/local/tmp/neon-work"
export NEON_DUMP="/data/local/tmp/neon-dump"
export NEON_LOG="/data/local/tmp/neon-log"

alias ll='ls -lah'
alias la='ls -la'
alias grep='busybox grep'
alias awk='busybox awk'
alias sed='busybox sed'
alias find='busybox find'
alias tar='busybox tar'
alias du='busybox du -h'
alias df='busybox df -h'
alias psx='ps -A'
alias props='getprop'
alias packages='pm list packages'
alias userapps='pm list packages -3'
alias sysapps='pm list packages -s'
ENV_EOF

chmod 755 "$ENV" || true

cat > "$SHORTCUT_TMP" <<'RUN_EOF'
#!/system/bin/sh

BB='/data/local/tmp/bb/bin/busybox'
ENV='/data/local/tmp/bb/env.sh'

[ -x "$BB" ] || {
  echo '[!] BusyBox belum terpasang. Jalankan: sh /sdcard/Download/neon-core-setup.sh'
  exit 1
}

[ -f "$ENV" ] && . "$ENV"

echo '[+] Neon Core shell aktif'
echo '[+] Work : /data/local/tmp/neon-work'
echo '[+] Dump : /data/local/tmp/neon-dump'
echo '[+] Log  : /data/local/tmp/neon-log'

exec "$BB" sh
RUN_EOF

chmod 755 "$SHORTCUT_TMP" || true

cat > "$SHORTCUT_SD" <<'RUN_EOF'
#!/system/bin/sh
sh /data/local/tmp/neon
RUN_EOF

chmod 755 "$SHORTCUT_SD" || true

say "${G}[✓] Shortcut ready:${N}"
say "${W}    /data/local/tmp/neon${N}"
say "${W}    /sdcard/Download/neon${N}"

line
say "${B}[5/5] Testing commands...${N}"

. "$ENV"

command -v find >/dev/null 2>&1 || fail 'find belum aktif.'
command -v grep >/dev/null 2>&1 || fail 'grep belum aktif.'
command -v awk >/dev/null 2>&1 || fail 'awk belum aktif.'
command -v sed >/dev/null 2>&1 || fail 'sed belum aktif.'
command -v tar >/dev/null 2>&1 || fail 'tar belum aktif.'

say "${G}[✓] Test OK: find grep awk sed tar${N}"

line
say "${G}[✓] NEON CORE ENGINE READY${N}"

say "${C}Masuk kapan saja dari adb shell:${N}"
say "${W}    sh /sdcard/Download/neon${N}"
say "${W}    atau: /data/local/tmp/neon${N}"

say ""
say "${Y}Catatan:${N} PATH tidak bisa dipasang permanen global tanpa root, jadi shortcut ini yang membuka shell dengan env otomatis. Tidak perlu load env manual."
say ""

exec "$BB" sh
ADB_SETUP_EOF

chmod 755 "$ADB_SETUP" || fail "chmod gagal: $ADB_SETUP"

line
say "${B}[6/7] Creating Termux shortcut...${N}"

if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX/bin" ]; then
  cat > "$TERMUX_SHORTCUT" <<'TERMUX_EOF'
#!/data/data/com.termux/files/usr/bin/sh
adb shell sh /sdcard/Download/neon
TERMUX_EOF

  chmod 755 "$TERMUX_SHORTCUT" || true

  say "${G}[✓] Termux shortcut ready: neon-adb${N}"
else
  say "${Y}[!] PREFIX tidak ditemukan, shortcut Termux dilewati.${N}"
fi

line
say "${B}[7/7] Final check...${N}"

[ -s "$ADB_SETUP" ] || fail 'ADB setup kosong.'
[ -s "$ADB_SHORTCUT" ] || fail 'ADB shortcut kosong.'

say "${G}[✓] TERMUX SIDE READY${N}"
say ""
say "${C}Sekarang jalankan:${N}"
say "${W}    adb shell sh /sdcard/Download/neon-core-setup.sh${N}"
say ""
say "${C}Setelah selesai, masuk cepat dari Termux:${N}"
say "${W}    neon-adb${N}"
say ""
say "${C}Atau dari adb shell:${N}"
say "${W}    sh /sdcard/Download/neon${N}"
say "${W}    /data/local/tmp/neon${N}"
