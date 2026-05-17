#!/data/data/com.termux/files/usr/bin/sh
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
say(){ printf '%b\n' "$1"; }
line(){ printf '%b\n' "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
fail(){ say "${R}[!] $1${N}"; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
clear 2>/dev/null || true
say "${M}"
say ' _   _                  ____'
say '| \ | | ___  ___  _ __ / ___|___  _ __ ___'
say '|  \| |/ _ \/ _ \| _  \ |   / _ \| __/ _ \'
say '| |\  |  __/ (_) | | | | |__| (_) | | |  __/'
say '|_| \_|\___|\___/|_| |_|\____\___/|_|  \___|'
say '        N E O N   C O R E   T E R M U X'
say "${N}"
line
say "${B}[1/6] Menyiapkan Termux...${N}"
have curl || fail 'curl belum terpasang. Jalankan: pkg install curl -y'
mkdir -p "$BIN_DIR" || fail "Gagal membuat $BIN_DIR"
say "${G}[✓] Termux siap${N}"
line
say "${B}[2/6] Memeriksa akses penyimpanan...${N}"
if [ ! -d "$PUBLIC_DIR" ]; then
  if have termux-setup-storage; then
    termux-setup-storage >/dev/null 2>&1 || true
    sleep 2
  fi
fi
[ -d "$PUBLIC_DIR" ] || fail 'Storage belum aktif. Izinkan akses storage Termux lalu jalankan ulang.'
say "${G}[✓] Storage siap${N}"
line
say "${B}[3/6] Mendeteksi arsitektur perangkat...${N}"
ABI="$(getprop ro.product.cpu.abi 2>/dev/null || true)"
case "$ABI" in
  arm64-v8a) ENGINE_FILE='busybox-arm64' ;;
  armeabi-v7a|armeabi) ENGINE_FILE='busybox-arm' ;;
  x86) ENGINE_FILE='busybox-x86' ;;
  x86_64) ENGINE_FILE='busybox-x86_64' ;;
  *)
    U="$(uname -m 2>/dev/null || true)"
    case "$U" in
      aarch64|arm64*) ENGINE_FILE='busybox-arm64' ;;
      armv7*|arm*) ENGINE_FILE='busybox-arm' ;;
      i*86) ENGINE_FILE='busybox-x86' ;;
      x86_64) ENGINE_FILE='busybox-x86_64' ;;
      *) ENGINE_FILE='busybox-arm64' ;;
    esac
  ;;
esac
say "${G}[✓] ABI: ${ABI:-unknown}${N}"
say "${G}[✓] Paket: $ENGINE_FILE${N}"
line
say "${B}[4/6] Mengunduh BusyBox static...${N}"
rm -f "$TERMUX_BB" "$PUBLIC_BB"
curl -L --fail --connect-timeout 15 --max-time 180 --retry 3 --retry-delay 2 "$BASE_URL/$ENGINE_FILE" -o "$TERMUX_BB" || fail 'Download BusyBox gagal.'
SIZE="$(wc -c < "$TERMUX_BB" 2>/dev/null || echo 0)"
[ "$SIZE" -gt 100000 ] || fail 'File BusyBox tidak valid.'
chmod 755 "$TERMUX_BB" || fail 'chmod BusyBox gagal.'
cp "$TERMUX_BB" "$PUBLIC_BB" || fail 'Gagal menyalin BusyBox ke penyimpanan publik.'
chmod 755 "$PUBLIC_BB" 2>/dev/null || true
say "${G}[✓] BusyBox siap${N}"
line
say "${B}[5/6] Membuat panel Neon di Termux...${N}"
cat > "$CLIENT" <<'CLIENT_EOF'
#!/data/data/com.termux/files/usr/bin/sh
set -u
HOST='127.0.0.1'
PORT='45555'
ROOT="$HOME/.neon-engine"
BIN="$ROOT/bin"
BB="$BIN/busybox"
CATALOG="$ROOT/shell.json"
MODULE_DIR='/sdcard/Download/NeonEngine/modules'
OUT_DIR='/sdcard/Download/NeonEngine'
BASE_WEB='https://neonmagisk.my.id/tweak'
CATALOG_URL='https://neonmagisk.my.id/tweak/shell.json'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAG='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'
p(){ printf '%b\n' "$1"; }
hr(){ printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
need_storage(){ mkdir -p "$ROOT" "$BIN" "$MODULE_DIR" "$OUT_DIR/dump" "$OUT_DIR/log" "$OUT_DIR/apk" "$OUT_DIR/media" 2>/dev/null || true; }
enc(){ printf '%s' "$1" | sed 's/ /%20/g'; }
send_cmd(){ CMD="$*"; [ -n "$CMD" ] || return 1; if [ -x "$BB" ]; then printf '%s\n' "$CMD" | "$BB" nc -w 30 "$HOST" "$PORT"; return $?; fi; if command -v nc >/dev/null 2>&1; then printf '%s\n' "$CMD" | nc -w 30 "$HOST" "$PORT"; return $?; fi; if command -v toybox >/dev/null 2>&1; then printf '%s\n' "$CMD" | toybox nc -w 30 "$HOST" "$PORT"; return $?; fi; p "${RED}[!] Netcat tidak tersedia. Jalankan ulang installer.${NC}"; return 1; }
daemon_alive(){ OUT="$(send_cmd 'echo NEON_CORE_READY' 2>/dev/null || true)"; printf '%s' "$OUT" | grep -q 'NEON_CORE_READY'; }
need_daemon(){ if ! daemon_alive; then p "${RED}[!] Neon Core Engine belum aktif.${NC}"; p "${YELLOW}[!] Aktifkan Neon Core Engine dulu, lalu ulangi command ini.${NC}"; exit 1; fi; }
refresh(){ need_storage; curl -L --fail --connect-timeout 15 --max-time 120 "$CATALOG_URL" -o "$CATALOG" >/dev/null 2>&1 || { p "${RED}[!] Gagal mengambil daftar module.${NC}"; return 1; }; COUNT="$(grep -c '"id"' "$CATALOG" 2>/dev/null || echo 0)"; p "${GREEN}[✓] Catalog diperbarui: $COUNT module${NC}"; }
field(){ ID="$1"; KEY="$2"; awk -v id="$ID" -v key="$KEY" 'BEGIN{RS="\\},";FS="\n"} $0~"\"id\"[[:space:]]*:[[:space:]]*\""id"\""{for(i=1;i<=NF;i++){if($i~"\""key"\""){x=$i;sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);print x;exit}}}' "$CATALOG" 2>/dev/null; }
modules(){ [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; awk 'BEGIN{RS="\\},";FS="\n"} {id="";title="";cat="";tier="";for(i=1;i<=NF;i++){x=$i;if(x~"\"id\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);id=x} x=$i;if(x~"\"title\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);title=x} x=$i;if(x~"\"category\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);cat=x} x=$i;if(x~"\"tier\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);tier=x}} if(id!="") printf "%-10s | %-32s | %-18s | %s\n",id,title,cat,tier}' "$CATALOG" | ${PAGER:-cat}; }
search_mod(){ Q="${1:-}"; [ -n "$Q" ] || { p 'Usage: neon search kata'; return 1; }; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; awk -v q="$Q" 'BEGIN{RS="\\},";FS="\n";q=tolower(q)} {rec=tolower($0); if(index(rec,q)){id="";title="";cat="";for(i=1;i<=NF;i++){x=$i;if(x~"\"id\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);id=x} x=$i;if(x~"\"title\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);title=x} x=$i;if(x~"\"category\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);cat=x}} printf "%-10s | %-42s | %s\n",id,title,cat}}' "$CATALOG"; }
info_mod(){ ID="$1"; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; TITLE="$(field "$ID" title)"; [ -n "$TITLE" ] || { p "${RED}[!] Module tidak ditemukan: $ID${NC}"; return 1; }; p "${CYAN}ID       :${NC} $ID"; p "${CYAN}Nama     :${NC} $TITLE"; p "${CYAN}Kategori :${NC} $(field "$ID" category)"; p "${CYAN}Tier     :${NC} $(field "$ID" tier)"; p "${CYAN}Versi    :${NC} $(field "$ID" version)"; p "${CYAN}Support  :${NC} $(field "$ID" support)"; p "${CYAN}Deskripsi:${NC} $(field "$ID" description)"; }
get_mod(){ ID="$1"; need_storage; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; URL_PATH="$(field "$ID" downloadUrl)"; TITLE="$(field "$ID" title)"; [ -n "$URL_PATH" ] || { p "${RED}[!] Module tidak ditemukan: $ID${NC}"; return 1; }; URL="$BASE_WEB/$URL_PATH"; URL="$(enc "$URL")"; DEST="$MODULE_DIR/$ID.zip"; DIR="$MODULE_DIR/$ID"; rm -rf "$DIR"; mkdir -p "$DIR"; p "${BLUE}[•] Download:${NC} $TITLE"; if [ -x "$BB" ]; then "$BB" wget -O "$DEST" "$URL" >/dev/null 2>&1 || curl -L "$URL" -o "$DEST" || return 1; "$BB" unzip -o "$DEST" -d "$DIR" >/dev/null 2>&1 || { p "${RED}[!] Gagal extract module.${NC}"; return 1; }; else curl -L "$URL" -o "$DEST" || return 1; unzip -o "$DEST" -d "$DIR" >/dev/null 2>&1 || { p "${RED}[!] unzip tidak tersedia. Jalankan ulang installer.${NC}"; return 1; }; fi; p "${GREEN}[✓] Module siap: $DIR${NC}"; }
run_script(){ ID="$1"; NAME="$2"; need_daemon; DIR="$MODULE_DIR/$ID"; [ -d "$DIR" ] || get_mod "$ID" || return 1; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; F=\$(find '$DIR' -name '$NAME' 2>/dev/null | head -n 1); if [ -n \"\$F\" ]; then sh \"\$F\"; else echo '[!] File $NAME tidak ditemukan di module $ID'; exit 1; fi"; }
install_engine(){ need_daemon; need_storage; p "${BLUE}[1/7] Menyiapkan ruang kerja...${NC}"; send_cmd 'rm -rf /data/local/tmp/neon-core; mkdir -p /data/local/tmp/neon-core/bin /data/local/tmp/neon-work /data/local/tmp/neon-dump /data/local/tmp/neon-log /sdcard/Download/NeonEngine /sdcard/Download/NeonEngine/dump /sdcard/Download/NeonEngine/log /sdcard/Download/NeonEngine/apk /sdcard/Download/NeonEngine/media' || return 1; p "${BLUE}[2/7] Memasang BusyBox...${NC}"; send_cmd '[ -f /sdcard/Download/busybox ] || { echo "[!] busybox belum ada di /sdcard/Download"; exit 1; }; cp /sdcard/Download/busybox /data/local/tmp/neon-core/bin/busybox 2>/dev/null || cat /sdcard/Download/busybox > /data/local/tmp/neon-core/bin/busybox; chmod 755 /data/local/tmp/neon-core/bin/busybox; /data/local/tmp/neon-core/bin/busybox --help >/dev/null 2>&1 || { echo "[!] BusyBox gagal jalan"; exit 1; }; echo "[✓] BusyBox OK"' || return 1; p "${BLUE}[3/7] Mengaktifkan applet...${NC}"; send_cmd 'cd /data/local/tmp/neon-core/bin && /data/local/tmp/neon-core/bin/busybox --install -s /data/local/tmp/neon-core/bin && echo "[✓] Applet OK"' || return 1; p "${BLUE}[4/7] Membuat environment...${NC}"; send_cmd 'printf "%s\n" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "export TMPDIR=\"/data/local/tmp\"" "export NEON_HOME=\"/data/local/tmp/neon-core\"" "export NEON_OUT=\"/sdcard/Download/NeonEngine\"" > /data/local/tmp/neon-core/env.sh; chmod 755 /data/local/tmp/neon-core/env.sh; echo "[✓] Env OK"' || return 1; p "${BLUE}[5/7] Membuat shortcut shell...${NC}"; send_cmd 'printf "%s\n" "#!/system/bin/sh" "BB=\"/data/local/tmp/neon-core/bin/busybox\"" "ENV=\"/data/local/tmp/neon-core/env.sh\"" "[ -x \"\$BB\" ] || { echo \"[!] Engine belum terpasang\"; exit 1; }" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "[ -f \"\$ENV\" ] && . \"\$ENV\"" "if [ \"\${1:-shell}\" = \"test\" ]; then command -v busybox; command -v wget; command -v unzip; command -v find; exit 0; fi" "if [ \"\${1:-shell}\" = \"run\" ]; then shift; exec \"\$BB\" sh -c \"\$*\"; fi" "exec \"\$BB\" sh" > /data/local/tmp/neon; chmod 755 /data/local/tmp/neon; printf "%s\n" "#!/system/bin/sh" "sh /data/local/tmp/neon \"\$@\"" > /sdcard/Download/neon; chmod 755 /sdcard/Download/neon 2>/dev/null || true; echo "[✓] Shortcut OK"' || return 1; p "${BLUE}[6/7] Mengunduh catalog module...${NC}"; refresh || true; p "${BLUE}[7/7] Test akhir...${NC}"; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; command -v busybox; command -v wget; command -v unzip; echo "[✓] Neon Core Engine siap"' || return 1; }
status(){ if daemon_alive; then p "${GREEN}[✓] Neon Core Engine aktif${NC}"; send_cmd 'id; getprop ro.product.model; getprop ro.build.version.release'; else p "${RED}[!] Neon Core Engine belum aktif${NC}"; fi; }
report(){ need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/dump; getprop > /sdcard/Download/NeonEngine/dump/props.txt; dumpsys battery > /sdcard/Download/NeonEngine/dump/battery.txt; dumpsys meminfo > /sdcard/Download/NeonEngine/dump/meminfo.txt; df -h > /sdcard/Download/NeonEngine/dump/storage.txt; echo "[✓] Report tersimpan di /sdcard/Download/NeonEngine/dump"'; }
features(){ cat <<EOF
Status & info: neon test, neon doctor, neon device, neon battery, neon storage, neon report
Module: neon refresh, neon modules, neon search kata, neon info id, neon get id, neon exec id, neon agresif id, neon del id
Aplikasi: neon apps, neon userapps, neon sysapps, neon appinfo package, neon app-start package, neon app-stop package, neon backupapk package
Layar & input: neon screenshot, neon record 10, neon tap x y, neon swipe x1 y1 x2 y2 durasi, neon text teks, neon key kode
Tweak aman: neon anim-off, neon anim-normal, neon trim-cache, neon logerr, neon logsave
Interface: neon panel, neon gui
EOF
}
device(){ need_daemon; send_cmd 'echo "Brand   : $(getprop ro.product.brand)"; echo "Model   : $(getprop ro.product.model)"; echo "Device  : $(getprop ro.product.device)"; echo "Android : $(getprop ro.build.version.release)"; echo "SDK     : $(getprop ro.build.version.sdk)"; echo "ABI     : $(getprop ro.product.cpu.abi)"'; }
text_panel(){ while true; do clear 2>/dev/null || true; p "${MAG}NEON CORE TERMUX PANEL${NC}"; hr; p "${WHITE}1.${NC} Status Engine"; p "${WHITE}2.${NC} Install / Repair Engine"; p "${WHITE}3.${NC} Module Center"; p "${WHITE}4.${NC} Device Tools"; p "${WHITE}5.${NC} App Tools"; p "${WHITE}6.${NC} Media & Input"; p "${WHITE}7.${NC} Report & Log"; p "${WHITE}8.${NC} Shell Command"; p "${WHITE}0.${NC} Keluar"; hr; printf 'Pilih: '; read A || exit 0; case "$A" in 1) status; pause ;; 2) install_engine; pause ;; 3) module_panel ;; 4) device_panel ;; 5) app_panel ;; 6) media_panel ;; 7) report_panel ;; 8) printf 'Command: '; read C; [ -n "$C" ] && send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $C"; pause ;; 0) exit 0 ;; *) p "Pilihan tidak ada"; sleep 1 ;; esac; done; }
pause(){ printf '\nEnter untuk lanjut...'; read _ || true; }
module_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}MODULE CENTER${NC}"; hr; p '1. Refresh catalog'; p '2. Lihat semua module'; p '3. Cari module'; p '4. Info module'; p '5. Download module'; p '6. Jalankan execute.sh'; p '7. Jalankan agresif.sh'; p '8. Jalankan del.sh'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) refresh; pause ;; 2) modules; pause ;; 3) printf 'Kata kunci: '; read Q; search_mod "$Q"; pause ;; 4) printf 'ID module: '; read ID; info_mod "$ID"; pause ;; 5) printf 'ID module: '; read ID; get_mod "$ID"; pause ;; 6) printf 'ID module: '; read ID; run_script "$ID" execute.sh; pause ;; 7) printf 'ID module: '; read ID; run_script "$ID" agresif.sh; pause ;; 8) printf 'ID module: '; read ID; run_script "$ID" del.sh; pause ;; 0) return ;; esac; done; }
device_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}DEVICE TOOLS${NC}"; hr; p '1. Info device'; p '2. Battery'; p '3. Storage'; p '4. Network'; p '5. Thermal'; p '6. Matikan animasi'; p '7. Normalisasi animasi'; p '8. Trim cache'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) device ;; 2) need_daemon; send_cmd 'dumpsys battery' ;; 3) need_daemon; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; df -h' ;; 4) need_daemon; send_cmd 'ip addr 2>/dev/null || ifconfig; getprop | grep -i dns' ;; 5) need_daemon; send_cmd 'for f in /sys/class/thermal/thermal_zone*/temp; do echo "$f: $(cat $f 2>/dev/null)"; done | head -n 30' ;; 6) need_daemon; send_cmd 'settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0; echo "[✓] Animasi dimatikan"' ;; 7) need_daemon; send_cmd 'settings put global window_animation_scale 1; settings put global transition_animation_scale 1; settings put global animator_duration_scale 1; echo "[✓] Animasi normal"' ;; 8) need_daemon; send_cmd 'pm trim-caches 999G; echo "[✓] Trim cache dikirim"' ;; 0) return ;; esac; pause; done; }
app_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}APP TOOLS${NC}"; hr; p '1. Semua package'; p '2. App user'; p '3. App sistem'; p '4. Info app'; p '5. Force stop app'; p '6. Start app'; p '7. Backup APK'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) need_daemon; send_cmd 'pm list packages' ;; 2) need_daemon; send_cmd 'pm list packages -3' ;; 3) need_daemon; send_cmd 'pm list packages -s' ;; 4) printf 'Package: '; read P; need_daemon; send_cmd "dumpsys package $P | head -n 160" ;; 5) printf 'Package: '; read P; need_daemon; send_cmd "am force-stop $P; echo '[✓] Force stop dikirim'" ;; 6) printf 'Package: '; read P; need_daemon; send_cmd "monkey -p $P 1" ;; 7) printf 'Package: '; read P; need_daemon; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; mkdir -p /sdcard/Download/NeonEngine/apk; APK=\$(pm path $P | head -n1 | sed 's/package://'); [ -f \"\$APK\" ] && cp \"\$APK\" /sdcard/Download/NeonEngine/apk/$P.apk && echo '[✓] APK tersimpan' || echo '[!] APK tidak bisa dibaca'" ;; 0) return ;; esac; pause; done; }
media_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}MEDIA & INPUT${NC}"; hr; p '1. Screenshot'; p '2. Screenrecord 10 detik'; p '3. Tap'; p '4. Swipe'; p '5. Ketik teks'; p '6. Key event'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/media; screencap -p /sdcard/Download/NeonEngine/media/screenshot_$(date +%s).png; echo "[✓] Screenshot tersimpan"' ;; 2) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/media; timeout 10 screenrecord /sdcard/Download/NeonEngine/media/record_$(date +%s).mp4; echo "[✓] Record selesai"' ;; 3) printf 'x y: '; read X Y; need_daemon; send_cmd "input tap $X $Y" ;; 4) printf 'x1 y1 x2 y2 durasi: '; read X1 Y1 X2 Y2 D; need_daemon; send_cmd "input swipe $X1 $Y1 $X2 $Y2 $D" ;; 5) printf 'Teks: '; read T; need_daemon; send_cmd "input text '$T'" ;; 6) printf 'Keycode: '; read K; need_daemon; send_cmd "input keyevent $K" ;; 0) return ;; esac; pause; done; }
report_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}REPORT & LOG${NC}"; hr; p '1. Buat report lengkap'; p '2. Lihat error log'; p '3. Simpan logcat'; p '4. Buka folder hasil'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) report ;; 2) need_daemon; send_cmd 'logcat -d | grep -i -E "error|crash|fatal|exception" | tail -n 160' ;; 3) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/log; logcat -d > /sdcard/Download/NeonEngine/log/logcat.txt; echo "[✓] Log tersimpan"' ;; 4) if command -v termux-open >/dev/null 2>&1; then termux-open /sdcard/Download/NeonEngine; else p '/sdcard/Download/NeonEngine'; fi ;; 0) return ;; esac; pause; done; }
gui_choice(){ TITLE="$1"; VALUES="$2"; if command -v termux-dialog >/dev/null 2>&1; then OUT="$(termux-dialog radio -t "$TITLE" -v "$VALUES" 2>/dev/null || true)"; TXT="$(printf '%s' "$OUT" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p')"; [ -n "$TXT" ] && { printf '%s' "$TXT"; return 0; }; fi; return 1; }
gui(){ CH="$(gui_choice 'Neon Core Panel' 'Status,Install Engine,Module Center,Device Tools,App Tools,Media Input,Report Log,Text Panel' || true)"; case "$CH" in Status) status ;; 'Install Engine') install_engine ;; 'Module Center') module_panel ;; 'Device Tools') device_panel ;; 'App Tools') app_panel ;; 'Media Input') media_panel ;; 'Report Log') report_panel ;; 'Text Panel'|'') text_panel ;; esac; }
case "${1:-help}" in
  test) status ;;
  install|repair) install_engine ;;
  panel|menu) text_panel ;;
  gui) gui ;;
  shell|sh) need_daemon; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; /data/local/tmp/neon 2>/dev/null || sh' ;;
  run) shift; need_daemon; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*" ;;
  refresh) refresh ;;
  modules) modules ;;
  search) shift; search_mod "$*" ;;
  info) info_mod "${2:-}" ;;
  get) get_mod "${2:-}" ;;
  exec) run_script "${2:-}" execute.sh ;;
  agresif) run_script "${2:-}" agresif.sh ;;
  del) run_script "${2:-}" del.sh ;;
  doctor) status; p ''; send_cmd '/data/local/tmp/neon test 2>/dev/null || echo "Engine shell belum diinstall"' ;;
  device) device ;;
  battery) need_daemon; send_cmd 'dumpsys battery' ;;
  storage) need_daemon; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; df -h' ;;
  apps) need_daemon; send_cmd 'pm list packages' ;;
  userapps) need_daemon; send_cmd 'pm list packages -3' ;;
  sysapps) need_daemon; send_cmd 'pm list packages -s' ;;
  appinfo) need_daemon; send_cmd "dumpsys package ${2:-} | head -n 160" ;;
  app-start) need_daemon; send_cmd "monkey -p ${2:-} 1" ;;
  app-stop) need_daemon; send_cmd "am force-stop ${2:-}; echo '[✓] Force stop dikirim'" ;;
  backupapk) P="${2:-}"; [ -n "$P" ] || { p 'Usage: neon backupapk package'; exit 1; }; need_daemon; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; mkdir -p /sdcard/Download/NeonEngine/apk; APK=\$(pm path $P | head -n1 | sed 's/package://'); [ -f \"\$APK\" ] && cp \"\$APK\" /sdcard/Download/NeonEngine/apk/$P.apk && echo '[✓] APK tersimpan' || echo '[!] APK tidak bisa dibaca'" ;;
  screenshot) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/media; screencap -p /sdcard/Download/NeonEngine/media/screenshot_$(date +%s).png; echo "[✓] Screenshot tersimpan"' ;;
  record) SEC="${2:-10}"; need_daemon; send_cmd "mkdir -p /sdcard/Download/NeonEngine/media; timeout $SEC screenrecord /sdcard/Download/NeonEngine/media/record_\$(date +%s).mp4; echo '[✓] Record selesai'" ;;
  tap) need_daemon; send_cmd "input tap ${2:-0} ${3:-0}" ;;
  swipe) need_daemon; send_cmd "input swipe ${2:-0} ${3:-0} ${4:-0} ${5:-0} ${6:-300}" ;;
  text) shift; need_daemon; send_cmd "input text '$*'" ;;
  key) need_daemon; send_cmd "input keyevent ${2:-3}" ;;
  anim-off) need_daemon; send_cmd 'settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0; echo "[✓] Animasi dimatikan"' ;;
  anim-normal) need_daemon; send_cmd 'settings put global window_animation_scale 1; settings put global transition_animation_scale 1; settings put global animator_duration_scale 1; echo "[✓] Animasi normal"' ;;
  trim-cache) need_daemon; send_cmd 'pm trim-caches 999G; echo "[✓] Trim cache dikirim"' ;;
  report) report ;;
  logerr) need_daemon; send_cmd 'logcat -d | grep -i -E "error|crash|fatal|exception" | tail -n 160' ;;
  logsave) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/log; logcat -d > /sdcard/Download/NeonEngine/log/logcat.txt; echo "[✓] Log tersimpan"' ;;
  features) features ;;
  copy) shift; if command -v termux-clipboard-set >/dev/null 2>&1; then printf '%s' "$*" | termux-clipboard-set; p "${GREEN}[✓] Disalin ke clipboard${NC}"; else p "$*"; fi ;;
  help|-h|--help) p 'Neon Core Termux Control'; p 'Mulai: neon test && neon install && neon panel'; p 'GUI: neon gui'; p 'Module: neon refresh, neon search kata, neon exec shell-001'; p 'Lihat semua: neon features' ;;
  *) need_daemon; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $*" ;;
esac
CLIENT_EOF
chmod 755 "$CLIENT" || fail 'Gagal membuat command neon.'
say "${G}[✓] Command neon siap${N}"
line
say "${B}[6/6] Mengecek Neon Core Engine...${N}"
if "$CLIENT" test >/dev/null 2>&1; then
  say "${G}[✓] Neon Core Engine aktif${N}"
  "$CLIENT" install || fail 'Install engine gagal.'
else
  say "${Y}[!] Neon Core Engine belum aktif.${N}"
  say "${Y}[!] Aktifkan Neon Core Engine, lalu jalankan: neon install${N}"
fi
line
say "${G}[✓] SETUP TERMUX SELESAI${N}"
say ""
say "${C}Mulai dari sini:${N}"
say "${W}    neon test${N}"
say "${W}    neon install${N}"
say "${W}    neon panel${N}"
say "${W}    neon gui${N}"
say ""
say "${C}Module:${N}"
say "${W}    neon refresh${N}"
say "${W}    neon search fps${N}"
say "${W}    neon exec shell-001${N}"
