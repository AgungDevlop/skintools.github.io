#!/data/data/com.termux/files/usr/bin/sh
# Neon Engine - Termux Controller for Neon Core / Brevent Daemon
# Non-root Android shell enhancer via daemon 127.0.0.1:45555

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

PUBLIC_DIR='/sdcard/Download'
PUBLIC_BB="$PUBLIC_DIR/busybox"

CLIENT="${PREFIX:-/data/data/com.termux/files/usr}/bin/neon"

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

mkdir -p "$BIN_DIR" || fail "Gagal membuat folder $BIN_DIR"

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
# Neon Termux Client
# Talks to Neon Core / Brevent daemon on 127.0.0.1:45555

set -u

HOST='127.0.0.1'
PORT='45555'
BB="$HOME/.neon-engine/bin/busybox"

REMOTE_BASE='/data/local/tmp/neon-core'
REMOTE_BIN='/data/local/tmp/neon-core/bin'
REMOTE_BB='/data/local/tmp/neon-core/bin/busybox'
REMOTE_ENV='/data/local/tmp/neon-core/env.sh'
REMOTE_RUN='/data/local/tmp/neon'
REMOTE_SD_RUN='/sdcard/Download/neon'

send_cmd() {
  CMD="$*"

  [ -n "$CMD" ] || return 1

  if [ -x "$BB" ]; then
    printf '%s\n' "$CMD" | "$BB" nc -w 20 "$HOST" "$PORT"
    return $?
  fi

  if command -v nc >/dev/null 2>&1; then
    printf '%s\n' "$CMD" | nc -w 20 "$HOST" "$PORT"
    return $?
  fi

  if command -v toybox >/dev/null 2>&1; then
    printf '%s\n' "$CMD" | toybox nc -w 20 "$HOST" "$PORT"
    return $?
  fi

  echo '[!] nc tidak ditemukan. Jalankan ulang neon-engine.sh.'
  return 1
}

daemon_alive() {
  OUT="$(send_cmd 'echo NEON_DAEMON_OK' 2>/dev/null || true)"
  printf '%s' "$OUT" | grep -q 'NEON_DAEMON_OK'
}

need_daemon() {
  if ! daemon_alive; then
    echo '[!] Daemon Neon/Brevent belum aktif di 127.0.0.1:45555.'
    echo '[!] Buka Neon Core/Brevent lalu aktifkan engine sampai ready.'
    echo '[!] Setelah itu jalankan: neon test'
    exit 1
  fi
}

remote_install() {
  need_daemon

  echo '[1/8] Preparing workspace...'
  send_cmd 'rm -rf /data/local/tmp/neon-core; mkdir -p /data/local/tmp/neon-core/bin /data/local/tmp/neon-work /data/local/tmp/neon-dump /data/local/tmp/neon-log' || return 1

  echo '[2/8] Installing BusyBox to executable path...'
  send_cmd '[ -f /sdcard/Download/busybox ] || { echo "[!] /sdcard/Download/busybox tidak ditemukan"; exit 1; }; cp /sdcard/Download/busybox /data/local/tmp/neon-core/bin/busybox 2>/dev/null || cat /sdcard/Download/busybox > /data/local/tmp/neon-core/bin/busybox; chmod 755 /data/local/tmp/neon-core/bin/busybox; /data/local/tmp/neon-core/bin/busybox --help >/dev/null 2>&1 || { echo "[!] BusyBox gagal execute"; exit 1; }; echo "[✓] BusyBox executable OK"' || return 1

  echo '[3/8] Creating BusyBox applets...'
  send_cmd 'cd /data/local/tmp/neon-core/bin && /data/local/tmp/neon-core/bin/busybox --install -s /data/local/tmp/neon-core/bin && echo "[✓] Applets installed"' || return 1

  echo '[4/8] Creating environment...'
  send_cmd 'printf "%s\n" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "export TMPDIR=\"/data/local/tmp\"" "export NEON_HOME=\"/data/local/tmp/neon-core\"" "export NEON_WORK=\"/data/local/tmp/neon-work\"" "export NEON_DUMP=\"/data/local/tmp/neon-dump\"" "export NEON_LOG=\"/data/local/tmp/neon-log\"" "alias ll=\"ls -lah\"" "alias la=\"ls -la\"" "alias packages=\"pm list packages\"" "alias userapps=\"pm list packages -3\"" "alias sysapps=\"pm list packages -s\"" > /data/local/tmp/neon-core/env.sh; chmod 755 /data/local/tmp/neon-core/env.sh; echo "[✓] Env ready"' || return 1

  echo '[5/8] Creating Android shell shortcut...'
  send_cmd 'printf "%s\n" "#!/system/bin/sh" "BB=\"/data/local/tmp/neon-core/bin/busybox\"" "ENV=\"/data/local/tmp/neon-core/env.sh\"" "[ -x \"\$BB\" ] || { echo \"[!] BusyBox belum terpasang\"; exit 1; }" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "[ -f \"\$ENV\" ] && . \"\$ENV\"" "CMD=\"\${1:-shell}\"" "if [ \"\$CMD\" = \"test\" ]; then" "  echo \"[+] busybox: \$(command -v busybox 2>/dev/null)\"" "  echo \"[+] wget   : \$(command -v wget 2>/dev/null)\"" "  echo \"[+] unzip  : \$(command -v unzip 2>/dev/null)\"" "  echo \"[+] find   : \$(command -v find 2>/dev/null)\"" "  echo \"[+] grep   : \$(command -v grep 2>/dev/null)\"" "  exit 0" "fi" "if [ \"\$CMD\" = \"run\" ]; then" "  shift" "  exec \"\$BB\" sh -c \"\$*\"" "fi" "if [ \"\$CMD\" = \"shell\" ] || [ \"\$CMD\" = \"sh\" ]; then" "  echo \"[+] Neon Core shell aktif\"" "  echo \"[+] BusyBox env otomatis aktif\"" "  exec \"\$BB\" sh" "fi" "exec \"\$@\"" > /data/local/tmp/neon; chmod 755 /data/local/tmp/neon; echo "[✓] Runner ready"' || return 1

  echo '[6/8] Creating sdcard shortcut...'
  send_cmd 'printf "%s\n" "#!/system/bin/sh" "sh /data/local/tmp/neon \"\$@\"" > /sdcard/Download/neon; chmod 755 /sdcard/Download/neon 2>/dev/null || true; echo "[✓] SD shortcut ready"' || return 1

  echo '[7/8] Creating useful folders...'
  send_cmd 'mkdir -p /storage/emulated/0/NeonEngine /storage/emulated/0/NeonEngine/dump /storage/emulated/0/NeonEngine/apk /storage/emulated/0/NeonEngine/log /storage/emulated/0/zipestrak; echo "[✓] Public folders ready"' || return 1

  echo '[8/8] Final test...'
  send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; command -v busybox; command -v wget; command -v unzip; command -v find; echo "[✓] Neon shell tools ready"' || return 1

  echo '[✓] Install complete'
}

remote_shell() {
  need_daemon

  RPWD='/'

  echo '[+] Neon daemon pseudo-shell dari Termux'
  echo '[+] Ketik exit untuk keluar'
  echo '[+] Ini bukan TTY asli, tapi cukup buat command shell harian.'

  while true; do
    printf 'neon:%s $ ' "$RPWD"
    IFS= read -r LINE || break

    case "$LINE" in
      exit|quit)
        break
        ;;
      '')
        continue
        ;;
      pwd)
        echo "$RPWD"
        continue
        ;;
      cd)
        RPWD='/'
        continue
        ;;
      cd\ *)
        TARGET="${LINE#cd }"
        OUT="$(send_cmd "cd '$RPWD' 2>/dev/null; cd '$TARGET' 2>/dev/null && pwd || echo __CD_FAIL__" 2>/dev/null || true)"
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
      echo '[!] Aktifkan Neon Core/Brevent engine dulu.'
      exit 1
    fi
    ;;

  install|setup)
    remote_install
    ;;

  sh|shell)
    remote_shell
    ;;

  run)
    shift
    need_daemon
    send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*"
    ;;

  doctor)
    need_daemon
    echo '[+] Daemon:'
    send_cmd 'id; getprop ro.product.model; getprop ro.build.version.release; getprop ro.product.cpu.abi'
    echo '[+] BusyBox shell side:'
    send_cmd '/data/local/tmp/neon test 2>/dev/null || echo "[!] BusyBox belum diinstall. Jalankan: neon install"'
    ;;

  device)
    need_daemon
    send_cmd 'echo "Brand   : $(getprop ro.product.brand)"; echo "Model   : $(getprop ro.product.model)"; echo "Device  : $(getprop ro.product.device)"; echo "Android : $(getprop ro.build.version.release)"; echo "SDK     : $(getprop ro.build.version.sdk)"; echo "ABI     : $(getprop ro.product.cpu.abi)"'
    ;;

  props)
    need_daemon
    send_cmd 'getprop > /storage/emulated/0/NeonEngine/dump/props.txt; echo "[✓] Saved: /storage/emulated/0/NeonEngine/dump/props.txt"'
    ;;

  battery)
    need_daemon
    send_cmd 'dumpsys battery'
    ;;

  battery-save)
    need_daemon
    send_cmd 'dumpsys battery > /storage/emulated/0/NeonEngine/dump/battery.txt; echo "[✓] Saved: /storage/emulated/0/NeonEngine/dump/battery.txt"'
    ;;

  storage)
    need_daemon
    send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; df -h; echo ""; du -h /storage/emulated/0/Download 2>/dev/null | tail -n 20'
    ;;

  apps)
    need_daemon
    send_cmd 'pm list packages'
    ;;

  userapps)
    need_daemon
    send_cmd 'pm list packages -3'
    ;;

  sysapps)
    need_daemon
    send_cmd 'pm list packages -s'
    ;;

  appinfo)
    need_daemon
    PKG="${2:-}"
    [ -n "$PKG" ] || { echo 'Usage: neon appinfo nama.package'; exit 1; }
    send_cmd "dumpsys package $PKG | head -n 120"
    ;;

  apkpath)
    need_daemon
    PKG="${2:-}"
    [ -n "$PKG" ] || { echo 'Usage: neon apkpath nama.package'; exit 1; }
    send_cmd "pm path $PKG"
    ;;

  backupapk)
    need_daemon
    PKG="${2:-}"
    [ -n "$PKG" ] || { echo 'Usage: neon backupapk nama.package'; exit 1; }
    send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; mkdir -p /storage/emulated/0/NeonEngine/apk; APK=\$(pm path $PKG | head -n 1 | sed 's/package://'); if [ -n \"\$APK\" ] && [ -f \"\$APK\" ]; then cp \"\$APK\" /storage/emulated/0/NeonEngine/apk/${PKG}.apk && echo \"[✓] Saved: /storage/emulated/0/NeonEngine/apk/${PKG}.apk\"; else echo \"[!] APK tidak bisa dibaca atau package tidak ditemukan\"; fi"
    ;;

  logerr)
    need_daemon
    send_cmd 'logcat -d | grep -i -E "error|crash|fatal|exception" | tail -n 120'
    ;;

  logsave)
    need_daemon
    send_cmd 'logcat -d > /storage/emulated/0/NeonEngine/log/logcat.txt; echo "[✓] Saved: /storage/emulated/0/NeonEngine/log/logcat.txt"'
    ;;

  settings-anim-off)
    need_daemon
    send_cmd 'settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0; echo "[✓] Animation scale set to 0"'
    ;;

  settings-anim-normal)
    need_daemon
    send_cmd 'settings put global window_animation_scale 1; settings put global transition_animation_scale 1; settings put global animator_duration_scale 1; echo "[✓] Animation scale set to 1"'
    ;;

  ziptest)
    need_daemon
    send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; mkdir -p /storage/emulated/0/zipestrak; wget -O /storage/emulated/0/zipestrak/github-test.zip https://github.com/octocat/Hello-World/archive/refs/heads/master.zip && unzip -o /storage/emulated/0/zipestrak/github-test.zip -d /storage/emulated/0/zipestrak && ls -lah /storage/emulated/0/zipestrak'
    ;;

  clean)
    need_daemon
    send_cmd 'rm -rf /data/local/tmp/neon-core /data/local/tmp/neon /data/local/tmp/neon-work /data/local/tmp/neon-dump /data/local/tmp/neon-log; rm -f /sdcard/Download/neon; echo "[✓] Neon shell side cleaned"'
    ;;

  help|-h|--help)
    echo 'Neon Engine - Termux Controller'
    echo ''
    echo 'Basic:'
    echo '  neon test                    cek daemon Neon/Brevent'
    echo '  neon install                 install BusyBox + toolkit ke shell daemon'
    echo '  neon doctor                  cek device + toolkit'
    echo '  neon sh                      pseudo-shell Android dari Termux'
    echo '  neon run "command"           jalankan command Android shell'
    echo ''
    echo 'Device info:'
    echo '  neon device                  info device'
    echo '  neon props                   simpan getprop ke file'
    echo '  neon battery                 tampilkan battery info'
    echo '  neon battery-save            simpan battery dump'
    echo '  neon storage                 cek storage'
    echo ''
    echo 'Apps:'
    echo '  neon apps                    list semua package'
    echo '  neon userapps                list app user'
    echo '  neon sysapps                 list app sistem'
    echo '  neon appinfo nama.package    dumpsys package'
    echo '  neon apkpath nama.package    lihat path APK'
    echo '  neon backupapk nama.package  backup APK ke /storage/emulated/0/NeonEngine/apk'
    echo ''
    echo 'Logs & tweak aman:'
    echo '  neon logerr                  tampilkan error logcat'
    echo '  neon logsave                 simpan logcat'
    echo '  neon settings-anim-off       matikan animasi'
    echo '  neon settings-anim-normal    normalisasi animasi'
    echo ''
    echo 'Test:'
    echo '  neon ziptest                 download + unzip ZIP publik pakai BusyBox'
    echo ''
    echo 'Maintenance:'
    echo '  neon clean                   hapus toolkit shell side'
    ;;

  *)
    need_daemon
    send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*"
    ;;
esac
CLIENT_EOF

chmod 755 "$CLIENT" || fail "Gagal chmod $CLIENT"

say "${G}[✓] Command ready: neon${N}"

line
say "${B}[6/6] Checking daemon...${N}"

if "$CLIENT" test >/dev/null 2>&1; then
  say "${G}[✓] Daemon aktif.${N}"
  say "${B}[•] Installing toolkit into daemon shell...${N}"
  "$CLIENT" install || fail 'Install toolkit ke daemon gagal.'
else
  say "${Y}[!] Daemon belum aktif di 127.0.0.1:45555.${N}"
  say "${Y}[!] Buka Neon Core/Brevent lalu aktifkan engine sampai ready.${N}"
  say "${Y}[!] Setelah ready, jalankan: neon install${N}"
fi

line
say "${G}[✓] TERMUX SETUP COMPLETE${N}"

say ""
say "${C}Command utama:${N}"
say "${W}    neon test${N}"
say "${W}    neon install${N}"
say "${W}    neon doctor${N}"
say "${W}    neon sh${N}"
say "${W}    neon run 'pm list packages'${N}"

say ""
say "${C}Command keren siap pakai:${N}"
say "${W}    neon device${N}"
say "${W}    neon apps${N}"
say "${W}    neon userapps${N}"
say "${W}    neon storage${N}"
say "${W}    neon logerr${N}"
say "${W}    neon ziptest${N}"

say ""
say "${Y}Catatan: daemon Neon/Brevent tetap harus aktif. Termux hanya mengontrol daemon itu lewat localhost.${N}"
