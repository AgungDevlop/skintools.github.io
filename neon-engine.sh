#!/data/data/com.termux/files/usr/bin/sh
# Neon Core Engine - Non Root BusyBox Installer
# Termux side: download static BusyBox + create Brevent / Neon Core shell setup

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

SHELL_SETUP="$PUBLIC_DIR/neon-core-setup.sh"
SD_SHORTCUT="$PUBLIC_DIR/neon"

say() {
  printf '%b\n' "$1"
}

line() {
  printf '%b\n' "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
}

fail() {
  say "${R}[!] $1${N}"
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

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

have curl || fail 'curl belum ada. Jalankan: pkg install curl -y'

mkdir -p "$LOCAL_DIR" || fail "Gagal membuat folder $LOCAL_DIR"

say "${G}[✓] curl ready${N}"

line
say "${B}[2/7] Checking storage access...${N}"

if [ ! -d "$PUBLIC_DIR" ]; then
  if have termux-setup-storage; then
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
chmod 755 "$PUBLIC_BUSYBOX" 2>/dev/null || true

say "${G}[✓] BusyBox ready: $PUBLIC_BUSYBOX${N}"

line
say "${B}[5/7] Creating Brevent / Neon Core shell setup...${N}"

cat > "$SHELL_SETUP" <<'SHELL_SETUP_EOF'
#!/system/bin/sh
# Neon Core Engine - Brevent / Neon Core Shell side installer

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
M='\033[1;35m'
W='\033[1;37m'
N='\033[0m'

SRC='/sdcard/Download/busybox'

BASE='/data/local/tmp/neon-core'
BIN="$BASE/bin"
BB="$BIN/busybox"
ENV="$BASE/env.sh"

RUNNER='/data/local/tmp/neon'
SD_RUNNER='/sdcard/Download/neon'

WORK='/data/local/tmp/neon-work'
DUMP='/data/local/tmp/neon-dump'
LOG='/data/local/tmp/neon-log'

say() {
  printf '%b\n' "$1"
}

line() {
  printf '%b\n' "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
}

fail() {
  say "${R}[!] $1${N}"
  exit 1
}

clear 2>/dev/null || true

say "${M}"
say ' _   _                  ____'
say '| \ | | ___  ___  _ __ / ___|___  _ __ ___'
say '|  \| |/ _ \/ _ \| _  \ |   / _ \| __/ _ \'
say '| |\  |  __/ (_) | | | | |__| (_) | | |  __/'
say '|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|'
say '        N E O N   C O R E   S H E L L'
say "${N}"

line
say "${B}[1/6] Preparing non-root workspace...${N}"

rm -rf "$BASE"

mkdir -p "$BIN" "$WORK" "$DUMP" "$LOG" || fail 'Gagal membuat folder kerja di /data/local/tmp.'

say "${G}[✓] Workspace ready${N}"

line
say "${B}[2/6] Moving BusyBox to executable path...${N}"

[ -f "$SRC" ] || fail 'File /sdcard/Download/busybox tidak ditemukan. Jalankan installer dari Termux dulu.'

cp "$SRC" "$BB" 2>/dev/null || cat "$SRC" > "$BB" || fail 'Gagal menyalin BusyBox.'

chmod 755 "$BB" || fail 'chmod BusyBox gagal.'

"$BB" --help >/dev/null 2>&1 || fail 'BusyBox gagal dijalankan. Kemungkinan ABI tidak cocok.'

say "${G}[✓] BusyBox executable: $BB${N}"

line
say "${B}[3/6] Installing BusyBox applets...${N}"

cd "$BIN" || fail 'Gagal masuk folder BusyBox bin.'

"$BB" --install -s "$BIN" >/dev/null 2>&1 || fail 'Gagal membuat shortcut applet BusyBox.'

say "${G}[✓] Applets ready: find grep awk sed tar unzip wget du df${N}"

line
say "${B}[4/6] Creating auto environment...${N}"

cat > "$ENV" <<'ENV_EOF'
export PATH="/data/local/tmp/neon-core/bin:$PATH"
export TMPDIR="/data/local/tmp"

export NEON_HOME="/data/local/tmp/neon-core"
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

chmod 755 "$ENV" 2>/dev/null || true

say "${G}[✓] Auto env ready${N}"

line
say "${B}[5/6] Creating simple shortcuts...${N}"

cat > "$RUNNER" <<'RUNNER_EOF'
#!/system/bin/sh

BB='/data/local/tmp/neon-core/bin/busybox'
ENV='/data/local/tmp/neon-core/env.sh'

if [ ! -x "$BB" ]; then
  echo '[!] Neon BusyBox belum terpasang.'
  echo '[!] Jalankan di Brevent/Neon Core shell:'
  echo '    sh /sdcard/Download/neon-core-setup.sh'
  exit 1
fi

[ -f "$ENV" ] && . "$ENV"

case "${1:-shell}" in
  shell|sh)
    echo '[+] Neon Core shell aktif'
    echo '[+] BusyBox env otomatis aktif'
    echo '[+] Ketik: exit untuk keluar'
    exec "$BB" sh
    ;;

  test)
    echo '[+] busybox:' "$(command -v busybox 2>/dev/null)"
    echo '[+] find   :' "$(command -v find 2>/dev/null)"
    echo '[+] grep   :' "$(command -v grep 2>/dev/null)"
    echo '[+] awk    :' "$(command -v awk 2>/dev/null)"
    echo '[+] sed    :' "$(command -v sed 2>/dev/null)"
    echo '[+] tar    :' "$(command -v tar 2>/dev/null)"
    ;;

  env)
    cat "$ENV"
    ;;

  run)
    shift
    exec "$BB" sh -c "$*"
    ;;

  *)
    exec "$@"
    ;;
esac
RUNNER_EOF

chmod 755 "$RUNNER" || fail 'Gagal chmod /data/local/tmp/neon.'

cat > "$SD_RUNNER" <<'SD_RUNNER_EOF'
#!/system/bin/sh
sh /data/local/tmp/neon "$@"
SD_RUNNER_EOF

chmod 755 "$SD_RUNNER" 2>/dev/null || true

say "${G}[✓] Shortcut ready:${N}"
say "${W}    /data/local/tmp/neon${N}"
say "${W}    sh /sdcard/Download/neon${N}"

line
say "${B}[6/6] Testing installed commands...${N}"

. "$ENV"

command -v busybox >/dev/null 2>&1 || fail 'busybox belum aktif.'
command -v find >/dev/null 2>&1 || fail 'find belum aktif.'
command -v grep >/dev/null 2>&1 || fail 'grep belum aktif.'
command -v awk >/dev/null 2>&1 || fail 'awk belum aktif.'
command -v sed >/dev/null 2>&1 || fail 'sed belum aktif.'
command -v tar >/dev/null 2>&1 || fail 'tar belum aktif.'

say "${G}[✓] Test OK${N}"

line
say "${G}[✓] NEON CORE SHELL READY${N}"

say "${C}Masuk kapan saja dari Brevent / Neon Core shell:${N}"
say "${W}    /data/local/tmp/neon${N}"
say "${W}    sh /sdcard/Download/neon${N}"

say "${C}Cek install:${N}"
say "${W}    /data/local/tmp/neon test${N}"

say ""
say "${Y}Non-root note:${N} PATH global Android tidak bisa dibuat permanen tanpa root. Shortcut ini sudah auto-load env, jadi tidak perlu load env manual."
say ""

exec "$BB" sh
SHELL_SETUP_EOF

chmod 755 "$SHELL_SETUP" || fail "chmod gagal: $SHELL_SETUP"

say "${G}[✓] Shell setup ready: $SHELL_SETUP${N}"

line
say "${B}[6/7] Creating pre-shortcut...${N}"

cat > "$SD_SHORTCUT" <<'SD_PRE_EOF'
#!/system/bin/sh
sh /data/local/tmp/neon "$@"
SD_PRE_EOF

chmod 755 "$SD_SHORTCUT" 2>/dev/null || true

say "${G}[✓] Pre-shortcut ready: $SD_SHORTCUT${N}"

line
say "${B}[7/7] Final check...${N}"

[ -s "$PUBLIC_BUSYBOX" ] || fail 'BusyBox di /sdcard/Download kosong.'
[ -s "$SHELL_SETUP" ] || fail 'neon-core-setup.sh kosong.'
[ -s "$SD_SHORTCUT" ] || fail 'Shortcut /sdcard/Download/neon kosong.'

say "${G}[✓] TERMUX SETUP COMPLETE${N}"

say ""
say "${Y}╔════════════════════════════════════════════╗${N}"
say "${Y}║        NEXT STEP IN BREVENT / NEON CORE    ║${N}"
say "${Y}╚════════════════════════════════════════════╝${N}"
say ""

say "${C}Salin dan jalankan command ini di Brevent / Neon Core shell:${N}"
say "${W}    sh /sdcard/Download/neon-core-setup.sh${N}"

say ""
say "${C}Setelah sukses, masuk lagi kapan saja dengan:${N}"
say "${W}    /data/local/tmp/neon${N}"
say "${W}    sh /sdcard/Download/neon${N}"

say ""
say "${G}[✓] Done. Tidak perlu command adb di tahap ini.${N}"
