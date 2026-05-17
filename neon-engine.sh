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
ROOT="$HOME/.neon-engine"
BIN="$ROOT/bin"
BB="$BIN/busybox"
PUBLIC='/sdcard/Download'
PUBLIC_BB="$PUBLIC/busybox"
CLIENT="${PREFIX:-/data/data/com.termux/files/usr}/bin/neon"
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
say '        N E O N   C O R E   W E B'
say "${N}"
line
say "${B}[1/6] Menyiapkan Termux...${N}"
have curl || fail 'curl belum terpasang. Jalankan: pkg install curl -y'
mkdir -p "$BIN" || fail "Gagal membuat $BIN"
say "${G}[✓] Termux siap${N}"
line
say "${B}[2/6] Memeriksa storage...${N}"
if [ ! -d "$PUBLIC" ]; then
  if have termux-setup-storage; then
    termux-setup-storage >/dev/null 2>&1 || true
    sleep 2
  fi
fi
[ -d "$PUBLIC" ] || fail 'Storage belum aktif. Izinkan storage Termux lalu jalankan ulang.'
say "${G}[✓] Storage siap${N}"
line
say "${B}[3/6] Mendeteksi arsitektur...${N}"
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
rm -f "$BB" "$PUBLIC_BB"
curl -L --fail --connect-timeout 15 --max-time 180 --retry 3 --retry-delay 2 "$BASE_URL/$ENGINE_FILE" -o "$BB" || fail 'Download BusyBox gagal.'
SIZE="$(wc -c < "$BB" 2>/dev/null || echo 0)"
[ "$SIZE" -gt 100000 ] || fail 'File BusyBox tidak valid.'
chmod 755 "$BB" || fail 'chmod BusyBox gagal.'
cp "$BB" "$PUBLIC_BB" || fail 'Gagal menyalin BusyBox ke storage publik.'
chmod 755 "$PUBLIC_BB" 2>/dev/null || true
say "${G}[✓] BusyBox siap${N}"
line
say "${B}[5/6] Membuat command neon...${N}"
cat > "$CLIENT" <<'CLIENT_EOF'
#!/data/data/com.termux/files/usr/bin/sh
set -u
HOST='127.0.0.1'
DAEMON_PORT='45555'
WEB_PORT='8787'
ROOT="$HOME/.neon-engine"
BIN="$ROOT/bin"
BB="$BIN/busybox"
WEB="$ROOT/web"
CGI="$WEB/cgi-bin"
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
need_dirs(){ mkdir -p "$ROOT" "$BIN" "$WEB" "$CGI" "$MODULE_DIR" "$OUT_DIR/dump" "$OUT_DIR/log" "$OUT_DIR/apk" "$OUT_DIR/media" "$OUT_DIR/report" 2>/dev/null || true; }
enc(){ printf '%s' "$1" | sed 's/ /%20/g'; }
send_cmd(){ CMD="$*"; [ -n "$CMD" ] || return 1; if [ -x "$BB" ]; then printf '%s\n' "$CMD" | "$BB" nc -w 45 "$HOST" "$DAEMON_PORT"; return $?; fi; if command -v nc >/dev/null 2>&1; then printf '%s\n' "$CMD" | nc -w 45 "$HOST" "$DAEMON_PORT"; return $?; fi; if command -v toybox >/dev/null 2>&1; then printf '%s\n' "$CMD" | toybox nc -w 45 "$HOST" "$DAEMON_PORT"; return $?; fi; p "${RED}[!] Netcat tidak tersedia. Jalankan ulang installer.${NC}"; return 1; }
daemon_alive(){ OUT="$(send_cmd 'echo NEON_CORE_READY' 2>/dev/null || true)"; printf '%s' "$OUT" | grep -q 'NEON_CORE_READY'; }
need_daemon(){ if ! daemon_alive; then p "${RED}[!] Neon Core Engine belum aktif.${NC}"; p "${YELLOW}[!] Aktifkan Neon Core Engine, lalu ulangi command ini.${NC}"; exit 1; fi; }
refresh(){ need_dirs; curl -L --fail --connect-timeout 15 --max-time 120 "$CATALOG_URL" -o "$CATALOG" >/dev/null 2>&1 || { p "${RED}[!] Gagal mengambil daftar module.${NC}"; return 1; }; COUNT="$(grep -c '"id"' "$CATALOG" 2>/dev/null || echo 0)"; p "${GREEN}[✓] Catalog diperbarui: $COUNT module${NC}"; }
field(){ ID="$1"; KEY="$2"; awk -v id="$ID" -v key="$KEY" 'BEGIN{RS="\\},";FS="\n"} $0~"\"id\"[[:space:]]*:[[:space:]]*\""id"\""{for(i=1;i<=NF;i++){if($i~"\""key"\""){x=$i;sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);print x;exit}}}' "$CATALOG" 2>/dev/null; }
modules(){ [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; awk 'BEGIN{RS="\\},";FS="\n"} {id="";title="";cat="";tier="";for(i=1;i<=NF;i++){x=$i;if(x~"\"id\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);id=x} x=$i;if(x~"\"title\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);title=x} x=$i;if(x~"\"category\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);cat=x} x=$i;if(x~"\"tier\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);tier=x}} if(id!="") printf "%-10s | %-36s | %-18s | %s\n",id,title,cat,tier}' "$CATALOG" | ${PAGER:-cat}; }
search_mod(){ Q="${1:-}"; [ -n "$Q" ] || { p 'Usage: neon search kata'; return 1; }; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; awk -v q="$Q" 'BEGIN{RS="\\},";FS="\n";q=tolower(q)} {rec=tolower($0); if(index(rec,q)){id="";title="";cat="";for(i=1;i<=NF;i++){x=$i;if(x~"\"id\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);id=x} x=$i;if(x~"\"title\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);title=x} x=$i;if(x~"\"category\""){sub(/^[^:]*:[[:space:]]*\"/,"",x);sub(/\",?[[:space:]]*$/,"",x);cat=x}} printf "%-10s | %-44s | %s\n",id,title,cat}}' "$CATALOG"; }
info_mod(){ ID="$1"; [ -n "$ID" ] || { p 'Usage: neon info shell-001'; return 1; }; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; TITLE="$(field "$ID" title)"; [ -n "$TITLE" ] || { p "${RED}[!] Module tidak ditemukan: $ID${NC}"; return 1; }; p "${CYAN}ID       :${NC} $ID"; p "${CYAN}Nama     :${NC} $TITLE"; p "${CYAN}Kategori :${NC} $(field "$ID" category)"; p "${CYAN}Tier     :${NC} $(field "$ID" tier)"; p "${CYAN}Versi    :${NC} $(field "$ID" version)"; p "${CYAN}Support  :${NC} $(field "$ID" support)"; p "${CYAN}Deskripsi:${NC} $(field "$ID" description)"; }
get_mod(){ ID="$1"; need_dirs; [ -n "$ID" ] || { p 'Usage: neon get shell-001'; return 1; }; [ -s "$CATALOG" ] || refresh >/dev/null 2>&1 || return 1; URL_PATH="$(field "$ID" downloadUrl)"; TITLE="$(field "$ID" title)"; [ -n "$URL_PATH" ] || { p "${RED}[!] Module tidak ditemukan: $ID${NC}"; return 1; }; URL="$BASE_WEB/$URL_PATH"; URL="$(enc "$URL")"; DEST="$MODULE_DIR/$ID.zip"; DIR="$MODULE_DIR/$ID"; rm -rf "$DIR"; mkdir -p "$DIR"; p "${BLUE}[•] Download:${NC} $TITLE"; if [ -x "$BB" ]; then "$BB" wget -O "$DEST" "$URL" >/dev/null 2>&1 || curl -L "$URL" -o "$DEST" || return 1; "$BB" unzip -o "$DEST" -d "$DIR" >/dev/null 2>&1 || { p "${RED}[!] Gagal extract module.${NC}"; return 1; }; else curl -L "$URL" -o "$DEST" || return 1; unzip -o "$DEST" -d "$DIR" >/dev/null 2>&1 || { p "${RED}[!] unzip tidak tersedia.${NC}"; return 1; }; fi; p "${GREEN}[✓] Module siap: $DIR${NC}"; }
run_script(){ ID="$1"; NAME="$2"; need_daemon; [ -n "$ID" ] || { p 'Usage: neon exec shell-001'; return 1; }; DIR="$MODULE_DIR/$ID"; [ -d "$DIR" ] || get_mod "$ID" || return 1; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; F=\$(find '$DIR' -name '$NAME' 2>/dev/null | head -n 1); if [ -n \"\$F\" ]; then sh \"\$F\"; else echo '[!] File $NAME tidak ditemukan di module $ID'; exit 1; fi"; }
install_engine(){ need_daemon; need_dirs; p "${BLUE}[1/7] Menyiapkan ruang kerja...${NC}"; send_cmd 'rm -rf /data/local/tmp/neon-core; mkdir -p /data/local/tmp/neon-core/bin /data/local/tmp/neon-work /data/local/tmp/neon-dump /data/local/tmp/neon-log /sdcard/Download/NeonEngine /sdcard/Download/NeonEngine/dump /sdcard/Download/NeonEngine/log /sdcard/Download/NeonEngine/apk /sdcard/Download/NeonEngine/media /sdcard/Download/NeonEngine/report' || return 1; p "${BLUE}[2/7] Memasang BusyBox...${NC}"; send_cmd '[ -f /sdcard/Download/busybox ] || { echo "[!] busybox belum ada di /sdcard/Download"; exit 1; }; cp /sdcard/Download/busybox /data/local/tmp/neon-core/bin/busybox 2>/dev/null || cat /sdcard/Download/busybox > /data/local/tmp/neon-core/bin/busybox; chmod 755 /data/local/tmp/neon-core/bin/busybox; /data/local/tmp/neon-core/bin/busybox --help >/dev/null 2>&1 || { echo "[!] BusyBox gagal jalan"; exit 1; }; echo "[✓] BusyBox OK"' || return 1; p "${BLUE}[3/7] Mengaktifkan applet...${NC}"; send_cmd 'cd /data/local/tmp/neon-core/bin && /data/local/tmp/neon-core/bin/busybox --install -s /data/local/tmp/neon-core/bin && echo "[✓] Applet OK"' || return 1; p "${BLUE}[4/7] Membuat environment...${NC}"; send_cmd 'printf "%s\n" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "export TMPDIR=\"/data/local/tmp\"" "export NEON_HOME=\"/data/local/tmp/neon-core\"" "export NEON_OUT=\"/sdcard/Download/NeonEngine\"" > /data/local/tmp/neon-core/env.sh; chmod 755 /data/local/tmp/neon-core/env.sh; echo "[✓] Env OK"' || return 1; p "${BLUE}[5/7] Membuat shortcut shell...${NC}"; send_cmd 'printf "%s\n" "#!/system/bin/sh" "BB=\"/data/local/tmp/neon-core/bin/busybox\"" "ENV=\"/data/local/tmp/neon-core/env.sh\"" "[ -x \"\$BB\" ] || { echo \"[!] Engine belum terpasang\"; exit 1; }" "export PATH=\"/data/local/tmp/neon-core/bin:\$PATH\"" "[ -f \"\$ENV\" ] && . \"\$ENV\"" "if [ \"\${1:-shell}\" = \"test\" ]; then command -v busybox; command -v wget; command -v unzip; command -v find; exit 0; fi" "if [ \"\${1:-shell}\" = \"run\" ]; then shift; exec \"\$BB\" sh -c \"\$*\"; fi" "exec \"\$BB\" sh" > /data/local/tmp/neon; chmod 755 /data/local/tmp/neon; printf "%s\n" "#!/system/bin/sh" "sh /data/local/tmp/neon \"\$@\"" > /sdcard/Download/neon; chmod 755 /sdcard/Download/neon 2>/dev/null || true; echo "[✓] Shortcut OK"' || return 1; p "${BLUE}[6/7] Mengunduh catalog module...${NC}"; refresh || true; p "${BLUE}[7/7] Test akhir...${NC}"; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; command -v busybox; command -v wget; command -v unzip; echo "[✓] Neon Core Engine siap"' || return 1; }
status(){ if daemon_alive; then p "${GREEN}[✓] Neon Core Engine aktif${NC}"; send_cmd 'id; getprop ro.product.model; getprop ro.build.version.release'; else p "${RED}[!] Neon Core Engine belum aktif${NC}"; fi; }
device(){ need_daemon; send_cmd 'echo "Brand   : $(getprop ro.product.brand)"; echo "Model   : $(getprop ro.product.model)"; echo "Device  : $(getprop ro.product.device)"; echo "Android : $(getprop ro.build.version.release)"; echo "SDK     : $(getprop ro.build.version.sdk)"; echo "ABI     : $(getprop ro.product.cpu.abi)"'; }
report(){ need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/report; getprop > /sdcard/Download/NeonEngine/report/props.txt; dumpsys battery > /sdcard/Download/NeonEngine/report/battery.txt; dumpsys meminfo > /sdcard/Download/NeonEngine/report/meminfo.txt; df -h > /sdcard/Download/NeonEngine/report/storage.txt; logcat -d | tail -n 400 > /sdcard/Download/NeonEngine/report/logcat_tail.txt; echo "[✓] Report tersimpan di /sdcard/Download/NeonEngine/report"'; }
features(){ cat <<EOF
Interface: neon web, neon web-stop, neon panel
Status: neon test, neon doctor, neon device, neon battery, neon storage, neon report, neon cpu, neon mem
Module: neon refresh, neon modules, neon search kata, neon info id, neon get id, neon exec id, neon agresif id, neon del id
Aplikasi: neon apps, neon userapps, neon sysapps, neon appinfo package, neon app-start package, neon app-stop package, neon backupapk package, neon appops package
Layar: neon screenshot, neon record 10, neon tap x y, neon swipe x1 y1 x2 y2 durasi, neon text teks, neon key kode
Tweak aman: neon anim-off, neon anim-normal, neon trim-cache, neon logerr, neon logsave, neon wm-size, neon wm-density, neon wm-reset
Jaringan: neon net, neon dns, neon services, neon props, neon top, neon process
EOF
}
pause(){ printf '\nEnter untuk lanjut...'; read _ || true; }
text_panel(){ while true; do clear 2>/dev/null || true; p "${MAG}NEON CORE TERMUX PANEL${NC}"; hr; p "${WHITE}1.${NC} Buka Web Control"; p "${WHITE}2.${NC} Status Engine"; p "${WHITE}3.${NC} Install / Repair Engine"; p "${WHITE}4.${NC} Module Center"; p "${WHITE}5.${NC} Device Tools"; p "${WHITE}6.${NC} App Tools"; p "${WHITE}7.${NC} Media & Input"; p "${WHITE}8.${NC} Report & Log"; p "${WHITE}9.${NC} Shell Command"; p "${WHITE}0.${NC} Keluar"; hr; printf 'Pilih: '; read A || exit 0; case "$A" in 1) web_start; pause ;; 2) status; pause ;; 3) install_engine; pause ;; 4) module_panel ;; 5) device_panel ;; 6) app_panel ;; 7) media_panel ;; 8) report_panel ;; 9) printf 'Command: '; read C; [ -n "$C" ] && send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; $C"; pause ;; 0) exit 0 ;; *) p 'Pilihan tidak ada'; sleep 1 ;; esac; done; }
module_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}MODULE CENTER${NC}"; hr; p '1. Refresh catalog'; p '2. Lihat semua module'; p '3. Cari module'; p '4. Info module'; p '5. Download module'; p '6. Jalankan execute.sh'; p '7. Jalankan agresif.sh'; p '8. Jalankan del.sh'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) refresh; pause ;; 2) modules; pause ;; 3) printf 'Kata kunci: '; read Q; search_mod "$Q"; pause ;; 4) printf 'ID module: '; read ID; info_mod "$ID"; pause ;; 5) printf 'ID module: '; read ID; get_mod "$ID"; pause ;; 6) printf 'ID module: '; read ID; run_script "$ID" execute.sh; pause ;; 7) printf 'ID module: '; read ID; run_script "$ID" agresif.sh; pause ;; 8) printf 'ID module: '; read ID; run_script "$ID" del.sh; pause ;; 0) return ;; esac; done; }
device_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}DEVICE TOOLS${NC}"; hr; p '1. Info device'; p '2. Battery'; p '3. Storage'; p '4. Network'; p '5. Thermal'; p '6. Matikan animasi'; p '7. Normalisasi animasi'; p '8. Trim cache'; p '9. Display info'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) device ;; 2) need_daemon; send_cmd 'dumpsys battery' ;; 3) need_daemon; send_cmd 'export PATH=/data/local/tmp/neon-core/bin:$PATH; df -h' ;; 4) need_daemon; send_cmd 'ip addr 2>/dev/null || ifconfig; getprop | grep -i dns' ;; 5) need_daemon; send_cmd 'for f in /sys/class/thermal/thermal_zone*/temp; do echo "$f: $(cat $f 2>/dev/null)"; done | head -n 30' ;; 6) need_daemon; send_cmd 'settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0; echo "[✓] Animasi dimatikan"' ;; 7) need_daemon; send_cmd 'settings put global window_animation_scale 1; settings put global transition_animation_scale 1; settings put global animator_duration_scale 1; echo "[✓] Animasi normal"' ;; 8) need_daemon; send_cmd 'pm trim-caches 999G; echo "[✓] Trim cache dikirim"' ;; 9) need_daemon; send_cmd 'wm size; wm density; dumpsys display | head -n 80' ;; 0) return ;; esac; pause; done; }
app_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}APP TOOLS${NC}"; hr; p '1. Semua package'; p '2. App user'; p '3. App sistem'; p '4. Info app'; p '5. Force stop app'; p '6. Start app'; p '7. Backup APK'; p '8. AppOps'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) need_daemon; send_cmd 'pm list packages' ;; 2) need_daemon; send_cmd 'pm list packages -3' ;; 3) need_daemon; send_cmd 'pm list packages -s' ;; 4) printf 'Package: '; read P; need_daemon; send_cmd "dumpsys package $P | head -n 180" ;; 5) printf 'Package: '; read P; need_daemon; send_cmd "am force-stop $P; echo '[✓] Force stop dikirim'" ;; 6) printf 'Package: '; read P; need_daemon; send_cmd "monkey -p $P 1" ;; 7) printf 'Package: '; read P; need_daemon; send_cmd "export PATH=/data/local/tmp/neon-core/bin:\$PATH; mkdir -p /sdcard/Download/NeonEngine/apk; APK=\$(pm path $P | head -n1 | sed 's/package://'); [ -f \"\$APK\" ] && cp \"\$APK\" /sdcard/Download/NeonEngine/apk/$P.apk && echo '[✓] APK tersimpan' || echo '[!] APK tidak bisa dibaca'" ;; 8) printf 'Package: '; read P; need_daemon; send_cmd "cmd appops get $P 2>/dev/null || appops get $P 2>/dev/null" ;; 0) return ;; esac; pause; done; }
media_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}MEDIA & INPUT${NC}"; hr; p '1. Screenshot'; p '2. Screenrecord 10 detik'; p '3. Tap'; p '4. Swipe'; p '5. Ketik teks'; p '6. Key event'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/media; screencap -p /sdcard/Download/NeonEngine/media/screenshot_$(date +%s).png; echo "[✓] Screenshot tersimpan"' ;; 2) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/media; timeout 10 screenrecord /sdcard/Download/NeonEngine/media/record_$(date +%s).mp4; echo "[✓] Record selesai"' ;; 3) printf 'x y: '; read X Y; need_daemon; send_cmd "input tap $X $Y" ;; 4) printf 'x1 y1 x2 y2 durasi: '; read X1 Y1 X2 Y2 D; need_daemon; send_cmd "input swipe $X1 $Y1 $X2 $Y2 $D" ;; 5) printf 'Teks: '; read T; need_daemon; send_cmd "input text '$T'" ;; 6) printf 'Keycode: '; read K; need_daemon; send_cmd "input keyevent $K" ;; 0) return ;; esac; pause; done; }
report_panel(){ while true; do clear 2>/dev/null || true; p "${CYAN}REPORT & LOG${NC}"; hr; p '1. Buat report lengkap'; p '2. Lihat error log'; p '3. Simpan logcat'; p '4. Buka folder hasil'; p '0. Kembali'; hr; printf 'Pilih: '; read A || return; case "$A" in 1) report ;; 2) need_daemon; send_cmd 'logcat -d | grep -i -E "error|crash|fatal|exception" | tail -n 180' ;; 3) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/log; logcat -d > /sdcard/Download/NeonEngine/log/logcat.txt; echo "[✓] Log tersimpan"' ;; 4) if command -v termux-open >/dev/null 2>&1; then termux-open /sdcard/Download/NeonEngine; else p '/sdcard/Download/NeonEngine'; fi ;; 0) return ;; esac; pause; done; }
web_assets(){ need_dirs; SELF="$(command -v neon 2>/dev/null || printf '%s' "$0")"; cat > "$WEB/index.html" <<'HTML_EOF'
<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Core Termux Web Control</title><script src="https://cdn.tailwindcss.com"></script><script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script><link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"><style>*{box-sizing:border-box}body{margin:0;min-height:100vh;background:radial-gradient(circle at 12% 0%,rgba(255,0,60,.24),transparent 28%),radial-gradient(circle at 90% 5%,rgba(0,180,255,.15),transparent 30%),linear-gradient(180deg,#070707,#020202);color:#e5e7eb;font-family:Inter,system-ui,Segoe UI,sans-serif}.glass{background:linear-gradient(180deg,rgba(22,22,26,.88),rgba(8,8,10,.92));border:1px solid rgba(255,255,255,.08);box-shadow:0 20px 70px rgba(0,0,0,.36);backdrop-filter:blur(18px)}.neon{color:#ff003c;text-shadow:0 0 16px rgba(255,0,60,.48)}.btn{display:flex;align-items:center;justify-content:center;gap:.45rem;border:1px solid rgba(255,0,60,.35);background:linear-gradient(180deg,rgba(255,0,60,.16),rgba(255,0,60,.06));border-radius:16px;padding:.78rem .9rem;font-size:.82rem;font-weight:800;letter-spacing:.04em;transition:.18s}.btn:hover{transform:translateY(-1px);border-color:#ff003c;background:rgba(255,0,60,.20)}.btn2{border-color:rgba(255,255,255,.12);background:rgba(255,255,255,.045)}.input,.select{width:100%;background:#050505;border:1px solid rgba(255,255,255,.1);border-radius:16px;padding:.8rem .9rem;outline:none;color:white}.input:focus,.select:focus{border-color:#ff003c}.tab{border:1px solid rgba(255,255,255,.1);background:rgba(255,255,255,.04);border-radius:999px;padding:.65rem .95rem;white-space:nowrap;font-weight:800;font-size:.78rem;color:#a1a1aa}.tab.active{border-color:#ff003c;background:rgba(255,0,60,.18);color:white;box-shadow:0 0 18px rgba(255,0,60,.15)}.out{background:#020202;border:1px solid rgba(255,255,255,.09);border-radius:22px;padding:1rem;white-space:pre-wrap;min-height:420px;max-height:72vh;overflow:auto;font:12px ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:#d1d5db}.badge{display:inline-flex;align-items:center;gap:.35rem;border:1px solid rgba(255,0,60,.30);background:rgba(255,0,60,.08);border-radius:999px;padding:.35rem .55rem;font-size:.68rem;font-weight:900;color:#ff9ab0}.mini{border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.035);border-radius:18px;padding:1rem}.gridbtn{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.65rem}@media(min-width:720px){.gridbtn{grid-template-columns:repeat(3,minmax(0,1fr))}}::-webkit-scrollbar{width:7px;height:7px}::-webkit-scrollbar-thumb{background:#ff003c;border-radius:999px}::-webkit-scrollbar-track{background:#111}</style></head><body x-data="app()" x-init="boot()"><main class="max-w-7xl mx-auto p-3 md:p-6"><section class="glass rounded-[28px] p-5 md:p-7 mb-4 overflow-hidden relative"><div class="absolute -right-24 -top-24 w-72 h-72 bg-red-500/10 blur-3xl rounded-full"></div><div class="relative flex flex-col lg:flex-row lg:items-center lg:justify-between gap-5"><div><div class="flex flex-wrap gap-2 mb-3"><span class="badge"><i class="fas fa-server"></i> Localhost 8787</span><span class="badge"><i class="fas fa-terminal"></i> CGI API</span><span class="badge"><i class="fas fa-mobile-screen"></i> Neon Core</span></div><h1 class="text-3xl md:text-6xl font-black tracking-[.18em] neon">NEON CORE</h1><p class="text-gray-400 mt-3 max-w-2xl">Panel lokal Termux untuk menjalankan fitur Neon Core Engine lewat tombol. Semua output muncul di panel kanan, jadi user tidak perlu mengetik command panjang kecuali memang sedang mencari masalah hidup baru.</p></div><div class="grid grid-cols-2 md:grid-cols-4 gap-2 min-w-full lg:min-w-[520px]"><button class="btn" @click="call('status')"><i class="fas fa-signal"></i>Status</button><button class="btn" @click="call('install')"><i class="fas fa-wrench"></i>Install</button><button class="btn" @click="call('doctor')"><i class="fas fa-stethoscope"></i>Doctor</button><button class="btn" @click="call('report')"><i class="fas fa-file-lines"></i>Report</button></div></div></section><section class="flex gap-2 overflow-x-auto pb-2 mb-4"><template x-for="t in tabs" :key="t.id"><button class="tab" :class="tab===t.id?'active':''" @click="tab=t.id"><i :class="t.icon" class="mr-1"></i><span x-text="t.name"></span></button></template></section><section class="grid lg:grid-cols-[440px_1fr] gap-4"><div class="space-y-4"><div class="glass rounded-[24px] p-4" x-show="tab==='dash'"><h2 class="font-black text-xl neon mb-3">Dashboard</h2><div class="gridbtn"><template x-for="a in quick" :key="a.act"><button class="btn btn2" @click="call(a.act)"><i :class="a.icon"></i><span x-text="a.name"></span></button></template></div><div class="mini mt-4 text-sm text-gray-400 leading-relaxed"><b class="text-white">Alur benar:</b> jalankan Status, Install, lalu gunakan Module Center atau Device Tools. Kalau output merah, berarti engine belum aktif atau akses shell belum nyambung, bukan karena jin router sedang cuti.</div></div><div class="glass rounded-[24px] p-4" x-show="tab==='module'"><h2 class="font-black text-xl neon mb-3">Module Center</h2><div class="space-y-3"><input class="input" x-model="q" placeholder="Cari module: fps, battery, samsung, gaming"><button class="btn w-full" @click="call('search',{q:q})"><i class="fas fa-search"></i>Cari Module</button><input class="input" x-model="mid" placeholder="ID module, contoh: shell-047"><div class="grid grid-cols-2 gap-2"><button class="btn btn2" @click="call('info',{id:mid})">Info</button><button class="btn btn2" @click="call('get',{id:mid})">Download</button><button class="btn" @click="call('exec',{id:mid})">Execute</button><button class="btn" @click="call('agresif',{id:mid})">Agresif</button><button class="btn btn2 col-span-2" @click="call('del',{id:mid})">Delete / Reset</button></div><button class="btn btn2 w-full" @click="call('modules')">Tampilkan Semua Module</button><button class="btn btn2 w-full" @click="call('refresh')">Refresh Catalog</button></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='device'"><h2 class="font-black text-xl neon mb-3">Device Tools</h2><div class="gridbtn"><template x-for="a in device" :key="a.act"><button class="btn btn2" @click="call(a.act)"><i :class="a.icon"></i><span x-text="a.name"></span></button></template></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='apps'"><h2 class="font-black text-xl neon mb-3">App Tools</h2><input class="input mb-3" x-model="pkg" placeholder="Package name, contoh: com.android.chrome"><div class="grid grid-cols-2 gap-2"><button class="btn btn2" @click="call('apps')">All Apps</button><button class="btn btn2" @click="call('userapps')">User Apps</button><button class="btn btn2" @click="call('sysapps')">System Apps</button><button class="btn btn2" @click="call('appinfo',{pkg:pkg})">App Info</button><button class="btn" @click="call('appstart',{pkg:pkg})">Start</button><button class="btn" @click="call('appstop',{pkg:pkg})">Force Stop</button><button class="btn btn2" @click="call('appops',{pkg:pkg})">AppOps</button><button class="btn btn2" @click="call('backupapk',{pkg:pkg})">Backup APK</button></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='media'"><h2 class="font-black text-xl neon mb-3">Media & Input</h2><div class="grid grid-cols-2 gap-2 mb-3"><button class="btn" @click="call('screenshot')">Screenshot</button><button class="btn" @click="call('record',{sec:sec})">Record</button></div><input class="input mb-2" x-model="sec" placeholder="Durasi record detik"><div class="grid grid-cols-2 gap-2 mb-3"><input class="input" x-model="tapx" placeholder="Tap X"><input class="input" x-model="tapy" placeholder="Tap Y"><button class="btn btn2 col-span-2" @click="call('tap',{x:tapx,y:tapy})">Tap Koordinat</button></div><input class="input mb-2" x-model="text" placeholder="Teks input"><button class="btn btn2 w-full" @click="call('text',{text:text})">Ketik Teks</button></div><div class="glass rounded-[24px] p-4" x-show="tab==='network'"><h2 class="font-black text-xl neon mb-3">Network & Services</h2><div class="gridbtn"><button class="btn btn2" @click="call('net')">Network</button><button class="btn btn2" @click="call('dns')">DNS</button><button class="btn btn2" @click="call('services')">Services</button><button class="btn btn2" @click="call('props')">Props</button><button class="btn btn2" @click="call('top')">Top</button><button class="btn btn2" @click="call('process')">Process</button></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='display'"><h2 class="font-black text-xl neon mb-3">Display & Tweak Aman</h2><div class="gridbtn"><button class="btn btn2" @click="call('animoff')">Anim Off</button><button class="btn btn2" @click="call('animnormal')">Anim Normal</button><button class="btn btn2" @click="call('wm-size')">WM Size</button><button class="btn btn2" @click="call('wm-density')">WM Density</button><button class="btn btn2" @click="call('wm-reset')">WM Reset</button><button class="btn btn2" @click="call('trimcache')">Trim Cache</button></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='logs'"><h2 class="font-black text-xl neon mb-3">Report & Log</h2><div class="gridbtn"><button class="btn btn2" @click="call('logerr')">Error Log</button><button class="btn btn2" @click="call('logsave')">Save Logcat</button><button class="btn btn2" @click="call('report')">Full Report</button><button class="btn btn2" @click="call('openfolder')">Open Folder</button></div></div><div class="glass rounded-[24px] p-4" x-show="tab==='terminal'"><h2 class="font-black text-xl neon mb-3">Command Runner</h2><input class="input mb-3" x-model="cmd" placeholder="Command shell"><button class="btn w-full" @click="call('run',{cmd:cmd})"><i class="fas fa-terminal"></i>Run Command</button><p class="text-xs text-gray-500 mt-3">Command dijalankan lewat Neon Core Engine. Pakai seperlunya, bukan untuk mengetes seberapa cepat Android bisa menyesal.</p></div><div class="glass rounded-[24px] p-4" x-show="tab==='docs'"><h2 class="font-black text-xl neon mb-3">Panduan Singkat</h2><div class="space-y-3 text-sm text-gray-300 leading-relaxed"><div class="mini"><b class="text-white">1. Setup awal</b><br><code>pkg update -y && pkg install curl -y && termux-setup-storage</code></div><div class="mini"><b class="text-white">2. Install script</b><br><code>curl -L https://neonmagisk.my.id/neon-engine.sh -o neon-engine.sh && chmod +x neon-engine.sh && sh neon-engine.sh</code></div><div class="mini"><b class="text-white">3. Sambungkan engine</b><br><code>neon test && neon install</code></div><div class="mini"><b class="text-white">4. Buka panel</b><br><code>neon web</code><br>Buka <code>http://127.0.0.1:8787</code></div><div class="mini"><b class="text-white">Folder output</b><br><code>/sdcard/Download/NeonEngine</code></div></div></div></div><div class="glass rounded-[24px] p-4 sticky top-3 h-fit"><div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-3"><div><h2 class="font-black text-xl neon">Output Console</h2><p class="text-xs text-gray-500" x-text="last"></p></div><div class="flex gap-2"><button class="btn btn2 text-xs" @click="copy(out)">Copy</button><button class="btn btn2 text-xs" @click="out=''">Clear</button></div></div><div class="out" x-text="loading?'Menjalankan command...':out"></div></div></section></main><script>function app(){return{tab:'dash',loading:false,out:'Panel siap. Klik Status untuk cek koneksi Neon Core Engine.',last:'Belum ada command',q:'',mid:'shell-047',pkg:'',cmd:'id',sec:'10',tapx:'500',tapy:'500',text:'hello',tabs:[{id:'dash',name:'Dashboard',icon:'fas fa-gauge'},{id:'module',name:'Module',icon:'fas fa-box-open'},{id:'device',name:'Device',icon:'fas fa-mobile-screen'},{id:'apps',name:'Apps',icon:'fas fa-layer-group'},{id:'media',name:'Media Input',icon:'fas fa-camera'},{id:'network',name:'Network',icon:'fas fa-wifi'},{id:'display',name:'Display',icon:'fas fa-display'},{id:'logs',name:'Logs',icon:'fas fa-bug'},{id:'terminal',name:'Terminal',icon:'fas fa-terminal'},{id:'docs',name:'Docs',icon:'fas fa-book'}],quick:[{name:'Status',act:'status',icon:'fas fa-signal'},{name:'Install',act:'install',icon:'fas fa-wrench'},{name:'Doctor',act:'doctor',icon:'fas fa-stethoscope'},{name:'Features',act:'features',icon:'fas fa-list'},{name:'Report',act:'report',icon:'fas fa-file-lines'},{name:'Open Folder',act:'openfolder',icon:'fas fa-folder-open'}],device:[{name:'Device',act:'device',icon:'fas fa-mobile'},{name:'Battery',act:'battery',icon:'fas fa-battery-half'},{name:'Storage',act:'storage',icon:'fas fa-hard-drive'},{name:'Thermal',act:'thermal',icon:'fas fa-temperature-half'},{name:'Memory',act:'mem',icon:'fas fa-memory'},{name:'CPU',act:'cpu',icon:'fas fa-microchip'}],boot(){this.call('status')},async call(act,args={}){this.loading=true;this.last='Command: '+act;let q=new URLSearchParams({act,...args});try{let r=await fetch('/cgi-bin/api?'+q.toString(),{cache:'no-store'});this.out=await r.text()}catch(e){this.out='Gagal koneksi ke API lokal: '+e}this.loading=false},copy(t){if(navigator.clipboard)navigator.clipboard.writeText(t)}}}</script></body></html>
HTML_EOF
cat > "$CGI/api" <<API_EOF
#!/data/data/com.termux/files/usr/bin/sh
printf 'Content-Type: text/plain\r\n\r\n'
NEON='__CLIENT__'
urldecode(){ v=\$(printf '%s' "\$1" | sed 's/+/ /g;s/%/\\\\x/g'); printf '%b' "\$v"; }
param(){ printf '%s' "\${QUERY_STRING:-}" | tr '&' '\n' | sed -n "s/^\$1=//p" | head -n 1 | while IFS= read -r x; do urldecode "\$x"; done; }
ACT=\$(param act)
ID=\$(param id)
Q=\$(param q)
PKG=\$(param pkg)
CMD=\$(param cmd)
SEC=\$(param sec)
X=\$(param x)
Y=\$(param y)
TXT=\$(param text)
case "\$ACT" in
status) "\$NEON" test ;;
install) "\$NEON" install ;;
doctor) "\$NEON" doctor ;;
features) "\$NEON" features ;;
refresh) "\$NEON" refresh ;;
modules) "\$NEON" modules ;;
search) "\$NEON" search "\$Q" ;;
info) "\$NEON" info "\$ID" ;;
get) "\$NEON" get "\$ID" ;;
exec) "\$NEON" exec "\$ID" ;;
agresif) "\$NEON" agresif "\$ID" ;;
del) "\$NEON" del "\$ID" ;;
device) "\$NEON" device ;;
battery) "\$NEON" battery ;;
storage) "\$NEON" storage ;;
thermal) "\$NEON" thermal ;;
mem) "\$NEON" mem ;;
cpu) "\$NEON" cpu ;;
net) "\$NEON" net ;;
dns) "\$NEON" dns ;;
services) "\$NEON" services ;;
props) "\$NEON" props ;;
top) "\$NEON" top ;;
process) "\$NEON" process ;;
apps) "\$NEON" apps ;;
userapps) "\$NEON" userapps ;;
sysapps) "\$NEON" sysapps ;;
appinfo) "\$NEON" appinfo "\$PKG" ;;
appstart) "\$NEON" app-start "\$PKG" ;;
appstop) "\$NEON" app-stop "\$PKG" ;;
appops) "\$NEON" appops "\$PKG" ;;
backupapk) "\$NEON" backupapk "\$PKG" ;;
screenshot) "\$NEON" screenshot ;;
record) "\$NEON" record "\${SEC:-10}" ;;
tap) "\$NEON" tap "\${X:-0}" "\${Y:-0}" ;;
text) "\$NEON" text "\$TXT" ;;
animoff) "\$NEON" anim-off ;;
animnormal) "\$NEON" anim-normal ;;
trimcache) "\$NEON" trim-cache ;;
wm-size) "\$NEON" wm-size ;;
wm-density) "\$NEON" wm-density ;;
wm-reset) "\$NEON" wm-reset ;;
logerr) "\$NEON" logerr ;;
logsave) "\$NEON" logsave ;;
report) "\$NEON" report ;;
openfolder) "\$NEON" open-folder ;;
run) "\$NEON" run "\$CMD" ;;
*) echo 'Neon Core Web API aktif' ;;
esac
API_EOF
sed -i "s#__CLIENT__#$SELF#g" "$CGI/api"
chmod 755 "$CGI/api"
}
web_running(){ [ -x "$BB" ] || return 1; "$BB" wget -q -O - "http://127.0.0.1:$WEB_PORT/" >/dev/null 2>&1; }
web_start(){ need_dirs; [ -x "$BB" ] || { p "${RED}[!] BusyBox belum siap. Jalankan ulang installer.${NC}"; return 1; }; "$BB" --list 2>/dev/null | grep -qx httpd || { p "${RED}[!] BusyBox ini tidak memiliki httpd.${NC}"; p "${YELLOW}[!] Jalankan: pkg install busybox -y lalu ulangi neon web${NC}"; return 1; }; web_assets; if web_running; then p "${GREEN}[✓] Web Control sudah aktif${NC}"; else "$BB" httpd -p "127.0.0.1:$WEB_PORT" -h "$WEB" >/dev/null 2>&1 || { p "${RED}[!] Gagal menjalankan web server.${NC}"; return 1; }; sleep 1; fi; URL="http://127.0.0.1:$WEB_PORT"; p "${GREEN}[✓] Neon Core Termux Web Control:${NC} $URL"; if command -v termux-open-url >/dev/null 2>&1; then termux-open-url "$URL" >/dev/null 2>&1 || true; fi; }
web_stop(){ if [ -x "$BB" ] && "$BB" --list 2>/dev/null | grep -qx pkill; then "$BB" pkill -f "httpd.*127.0.0.1:$WEB_PORT" 2>/dev/null || true; else pkill -f "httpd.*127.0.0.1:$WEB_PORT" 2>/dev/null || true; fi; p "${GREEN}[✓] Web server dihentikan jika sebelumnya aktif.${NC}"; }
case "${1:-help}" in
  test|status) status ;;
  install|repair) install_engine ;;
  panel|menu) text_panel ;;
  web|server|ui) web_start ;;
  web-stop|stop-web) web_stop ;;
  web-path) p "$WEB" ;;
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
  net) need_daemon; send_cmd 'ip addr 2>/dev/null || ifconfig; getprop | grep -i dns' ;;
  thermal) need_daemon; send_cmd 'for f in /sys/class/thermal/thermal_zone*/temp; do echo "$f: $(cat $f 2>/dev/null)"; done | head -n 30' ;;

  dns) need_daemon; send_cmd 'getprop | grep -i dns; ip route 2>/dev/null' ;;
  props) need_daemon; send_cmd 'getprop | head -n 220' ;;
  cpu) need_daemon; send_cmd 'cat /proc/cpuinfo | head -n 80; echo; cat /proc/loadavg 2>/dev/null' ;;
  mem) need_daemon; send_cmd 'cat /proc/meminfo | head -n 40; echo; dumpsys meminfo | head -n 80 2>/dev/null' ;;
  top) need_daemon; send_cmd 'top -n 1 -b 2>/dev/null | head -n 40 || ps -A | head -n 40' ;;
  process) need_daemon; send_cmd 'ps -A 2>/dev/null | head -n 160 || ps | head -n 160' ;;
  services) need_daemon; send_cmd 'cmd -l 2>/dev/null || service list' ;;
  apps) need_daemon; send_cmd 'pm list packages' ;;
  userapps) need_daemon; send_cmd 'pm list packages -3' ;;
  sysapps) need_daemon; send_cmd 'pm list packages -s' ;;
  appinfo) need_daemon; send_cmd "dumpsys package ${2:-} | head -n 180" ;;
  app-start) need_daemon; send_cmd "monkey -p ${2:-} 1" ;;
  app-stop) need_daemon; send_cmd "am force-stop ${2:-}; echo '[✓] Force stop dikirim'" ;;
  appops) need_daemon; send_cmd "cmd appops get ${2:-} 2>/dev/null || appops get ${2:-} 2>/dev/null" ;;
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
  wm-size) need_daemon; send_cmd 'wm size' ;;
  wm-density) need_daemon; send_cmd 'wm density' ;;
  wm-reset) need_daemon; send_cmd 'wm size reset; wm density reset; echo "[✓] Display reset"' ;;
  report) report ;;
  logerr) need_daemon; send_cmd 'logcat -d | grep -i -E "error|crash|fatal|exception" | tail -n 180' ;;
  logsave) need_daemon; send_cmd 'mkdir -p /sdcard/Download/NeonEngine/log; logcat -d > /sdcard/Download/NeonEngine/log/logcat.txt; echo "[✓] Log tersimpan"' ;;
  open-folder) if command -v termux-open >/dev/null 2>&1; then termux-open /sdcard/Download/NeonEngine; else p '/sdcard/Download/NeonEngine'; fi ;;
  features) features ;;
  copy) shift; if command -v termux-clipboard-set >/dev/null 2>&1; then printf '%s' "$*" | termux-clipboard-set; p "${GREEN}[✓] Disalin ke clipboard${NC}"; else p "$*"; fi ;;
  help|-h|--help) p 'Neon Core Termux Web Control'; p 'Mulai: neon test && neon install && neon web'; p 'Panel teks: neon panel'; p 'Module: neon refresh, neon search kata, neon exec shell-001'; p 'Lihat fitur: neon features' ;;
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
say "${C}Mulai:${N}"
say "${W}    neon test${N}"
say "${W}    neon install${N}"
say "${W}    neon web${N}"
say ""
say "${C}Buka di browser:${N}"
say "${W}    http://127.0.0.1:8787${N}"
say ""
say "${C}Fallback panel teks:${N}"
say "${W}    neon panel${N}"
