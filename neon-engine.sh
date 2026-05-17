#!/data/data/com.termux/files/usr/bin/sh
# Neon Engine - Termux controller for Neon/Brevent daemon
# No adb command needed. Termux talks to local daemon 127.0.0.1:45555.

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

HOME_DIR="$HOME/.neon-engine"
BIN_DIR="$HOME_DIR/bin"
TERMUX_BB="$BIN_DIR/busybox"

CLIENT="${PREFIX:-/data/data/com.termux/files/usr}/bin/neon"

PUBLIC_DIR='/sdcard/Download'
PUBLIC_BB="$PUBLIC_DIR/busybox"

DAEMON_HOST='127.0.0.1'
DAEMON_PORT='45555'

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
say '        N E O N   E N G I N E   T E R M U X'
say "${N}"

line
say "${B}[1/6] Checking Termux tools...${N}"

have curl || fail 'curl belum ada. Jalankan: pkg install curl -y'

mkdir -p "$BIN_DIR" || fail "Gagal membuat $BIN_DIR"

say "${G}[✓] curl ready${N}"

line
say "${B}[2/6] Checking storage access...${N}"

if [ ! -d "$PUBLIC_DIR" ]; then
  if have termux-setup-storage; then
    say "${Y}[•] Meminta akses storage Termux...${N}"
    termux-setup-storage >/dev/null 2>&1 || true
    sleep 2
  fi
fi

[ -d "$PUBLIC_DIR" ] || fail 'Storage belum aktif. Izinkan storage Termux lalu jalankan ulang.'

say "${G}[✓] Storage ready: $PUBLIC_DIR${N}"

line
say "${B}[3/6] Detecting ABI...${N}"

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
say "${B}[4/6] Downloading static BusyBox...${N}"

URL="$BASE_URL/$ENGINE_FILE"

rm -f "$TERMUX_BB" "$PUBLIC_BB"

curl -L --fail --connect-timeout 15 --max-time 180 --retry 3 --retry-delay 2 \
  "$URL" -o "$TERMUX_BB" || fail 'Download BusyBox gagal.'

SIZE="$(wc -c < "$TERMUX_BB" 2>/dev/null || echo 0)"

[ "$SIZE" -gt 100000 ] || fail 'File BusyBox tidak valid.'

chmod 755 "$TERMUX_BB" || fail 'chmod BusyBox gagal.'

cp "$TERMUX_BB" "$PUBLIC_BB" || fail "Gagal copy BusyBox ke $PUBLIC_BB"
chmod 755 "$PUBLIC_BB" 2>/dev/null || true

say "${G}[✓] BusyBox Termux: $TERMUX_BB${N}"
say "${G}[✓] BusyBox public: $PUBLIC_BB${N}"

line
say "${B}[5/6] Creating Termux command: neon${N}"

cat > "$CLIENT" <<'CLIENT_EOF'
#!/data/data/com.termux/files/usr/bin/sh
# Neon Termux Client - talks to Neon/Brevent daemon at 127.0.0.1:45555

set -u

HOST='127.0.0.1'
PORT='45555'
BB="$HOME/.neon-engine/bin/busybox"

send_cmd() {
  CMD="$*"

  [ -n "$CMD" ] || return 1

  if [ -x "$BB" ]; then
    printf '%s\n' "$CMD" | "$BB" nc -w 15 "$HOST" "$PORT"
    return $?
  fi

  if command -v nc >/dev/null 2>&1; then
    printf '%s\n' "$CMD" | nc -w 15 "$HOST" "$PORT"
    return $?
  fi

  if command -v toybox >/dev/null 2>&1; then
    printf '%s\n' "$CMD" | toybox nc -w 15 "$HOST" "$PORT"
    return $?
  fi

  echo '[!] Tidak ada nc. BusyBox client tidak ditemukan.'
  echo '[!] Jalankan ulang installer neon-engine.sh dari Termux.'
  return 1
}

daemon_alive() {
  OUT="$(send_cmd 'echo NEON_DAEMON_OK' 2>/dev/null || true)"
  printf '%s' "$OUT" | grep -q 'NEON_DAEMON_OK'
}

remote_setup_cmd() {
  cat <<'EOS'
SRC=/sdcard/Download/busybox
BASE=/data/local/tmp/neon-core
BIN=$BASE/bin
BB=$BIN/busybox
ENV=$BASE/env.sh
RUN=/data/local/tmp/neon
SDRUN=/sdcard/Download/neon

mkdir -p $BIN /data/local/tmp/neon-work /data/local/tmp/neon-dump /data/local/tmp/neon-log || exit 1

[ -f $SRC ] || {
  echo '[!] /sdcard/Download/busybox tidak ada'
  exit 1
}

cp $SRC $BB 2>/dev/null || cat $SRC > $BB || exit 1
chmod 755 $BB || exit 1

$BB --help >/dev/null 2>&1 || {
  echo '[!] BusyBox tidak bisa execute'
  exit 1
}

cd $BIN || exit 1
$BB --install -s $BIN >/dev/null 2>&1 || exit 1

printf '%s\n' \
'export PATH="/data/local/tmp/neon-core/bin:$PATH"' \
'export TMPDIR="/data/local/tmp"' \
'export NEON_HOME="/data/local/tmp/neon-core"' \
'export NEON_WORK="/data/local/tmp/neon-work"' \
'export NEON_DUMP="/data/local/tmp/neon-dump"' \
'export NEON_LOG="/data/local/tmp/neon-log"' \
'alias ll="ls -lah"' \
'alias la="ls -la"' \
'alias packages="pm list packages"' \
'alias userapps="pm list packages -3"' \
'alias sysapps="pm list packages -s"' \
> $ENV

chmod 755 $ENV

printf '%s\n' \
'#!/system/bin/sh' \
'BB="/data/local/tmp/neon-core/bin/busybox"' \
'ENV="/data/local/tmp/neon-core/env.sh"' \
'[ -x "$BB" ] || { echo "[!] BusyBox belum terpasang"; exit 1; }' \
'export PATH="/data/local/tmp/neon-core/bin:$PATH"' \
'[ -f "$ENV" ] && . "$ENV"' \
'case "${1:-shell}" in' \
'  shell|sh)' \
'    echo "[+] Neon Core shell aktif"' \
'    echo "[+] BusyBox env otomatis aktif"' \
'    exec "$BB" sh' \
'    ;;' \
'  test)' \
'    echo "[+] busybox: $(command -v busybox 2>/dev/null)"' \
'    echo "[+] wget   : $(command -v wget 2>/dev/null)"' \
'    echo "[+] unzip  : $(command -v unzip 2>/dev/null)"' \
'    echo "[+] find   : $(command -v find 2>/dev/null)"' \
'    ;;' \
'  run)' \
'    shift' \
'    exec "$BB" sh -c "$*"' \
'    ;;' \
'  *)' \
'    exec "$@"' \
'    ;;' \
'esac' \
> $RUN

chmod 755 $RUN

printf '%s\n' \
'#!/system/bin/sh' \
'sh /data/local/tmp/neon "$@"' \
> $SDRUN

chmod 755 $SDRUN 2>/dev/null || true

. $ENV

command -v busybox >/dev/null 2>&1 || exit 1
command -v wget >/dev/null 2>&1 || exit 1
command -v unzip >/dev/null 2>&1 || exit 1

echo '[✓] Neon BusyBox shell installed'
echo '[✓] Shortcut shell: /data/local/tmp/neon'
echo '[✓] Shortcut sdcard: sh /sdcard/Download/neon'
EOS
}

install_engine() {
  if ! daemon_alive; then
    echo '[!] Daemon Neon/Brevent belum aktif di 127.0.0.1:45555.'
    echo '[!] Buka Neon Core/Brevent, aktifkan engine sampai status connected/ready.'
    echo '[!] Setelah itu jalankan: neon install'
    return 1
  fi

  CMD="$(remote_setup_cmd | tr '\n' ';')"
  send_cmd "$CMD"
}

repl() {
  if ! daemon_alive; then
    echo '[!] Daemon belum aktif. Jalankan: neon test'
    return 1
  fi

  RPWD='/'

  echo '[+] Neon daemon shell dari Termux'
  echo '[+] Ketik exit untuk keluar'

  while true; do
    printf 'neon:%s $ ' "$RPWD"
    IFS= read -r LINE || break

    case "$LINE" in
      exit|quit)
        break
        ;;
      pwd)
        echo "$RPWD"
        continue
        ;;
      cd|'cd ')
        RPWD='/'
        continue
        ;;
      cd\ *)
        TARGET="${LINE#cd }"
        OUT="$(send_cmd "cd '$RPWD' 2>/dev/null; cd '$TARGET' 2>/dev/null && pwd || echo __CD_FAIL__")"

        if printf '%s' "$OUT" | grep -q '__CD_FAIL__'; then
          echo '[!] cd gagal'
        else
          RPWD="$(printf '%s\n' "$OUT" | tail -n 1)"
        fi
        continue
        ;;
    esac

    send_cmd "cd '$RPWD' 2>/dev/null; export PATH=/data/local/tmp/neon-core/bin:\$PATH; $LINE"
  done
}

case "${1:-help}" in
  test)
    if daemon_alive; then
      echo '[✓] Daemon aktif: 127.0.0.1:45555'
      send_cmd 'id; echo SHELL=$(whoami 2>/dev/null); echo PATH=$PATH'
    else
      echo '[!] Daemon belum aktif: 127.0.0.1:45555'
      echo '[!] Aktifkan Neon Core/Brevent engine dulu, lalu ulangi: neon test'
      exit 1
    fi
    ;;

  install|setup|engine-install)
    install_engine
    ;;

  sh|shell)
    repl
    ;;

  run)
    shift
    send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*"
    ;;

  busybox-test)
    send_cmd '/data/local/tmp/neon test'
    ;;

  help|-h|--help)
    echo 'Neon Termux Client'
    echo ''
    echo 'Command:'
    echo '  neon test              cek daemon Neon/Brevent aktif'
    echo '  neon install           pasang BusyBox ke shell daemon Android'
    echo '  neon sh                buka pseudo-shell dari Termux'
    echo '  neon run "id"          jalankan command sekali via daemon'
    echo '  neon busybox-test      cek BusyBox shell side'
    echo ''
    echo 'Contoh:'
    echo '  neon run "pm list packages | head"'
    echo '  neon run "mkdir -p /storage/emulated/0/zipestrak"'
    ;;

  *)
    send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*"
    ;;
esac
CLIENT_EOF

chmod 755 "$CLIENT" || fail "Gagal chmod $CLIENT"

say "${G}[✓] Command ready: neon${N}"

line
say "${B}[6/6] Checking daemon...${N}"

if "$CLIENT" test >/dev/null 2>&1; then
  say "${G}[✓] Daemon aktif. Installing BusyBox into daemon shell...${N}"
  "$CLIENT" install || fail 'Install BusyBox ke daemon shell gagal.'
else
  say "${Y}[!] Daemon belum aktif di 127.0.0.1:45555.${N}"
  say "${Y}[!] Buka Neon Core/Brevent lalu aktifkan engine sampai ready.${N}"
fi

line
say "${G}[✓] TERMUX SETUP COMPLETE${N}"

say ""
say "${C}Command utama di Termux:${N}"
say "${W}    neon test${N}"
say "${W}    neon install${N}"
say "${W}    neon sh${N}"
say "${W}    neon run 'pm list packages'${N}"

say ""
say "${C}Kalau daemon sudah aktif, semua bisa dari Termux. Tidak perlu bolak-balik shell.${N}"
say "${Y}Catatan: daemon Neon/Brevent tetap harus hidup dulu. Termux tidak bisa menciptakan akses shell sendiri tanpa daemon awal.${N}"
