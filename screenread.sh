#!/data/data/com.termux/files/usr/bin/bash

API_KEY="AIzaSyAnHG_bGWjvOxsUptlgsUb_FOpopzp4YDY"
MODEL="gemini-2.5-flash"
PORT=45555

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT
}

show_alert() {
    local TITLE="$1"
    local MSG="$2"
    local FALLBACK_MODE="FALSE"
    
    if command -v termux-dialog >/dev/null 2>&1; then
        T_RES=$(termux-dialog confirm -t "$TITLE" -i "$MSG" 2>/dev/null)
        if [ -z "$T_RES" ] || echo "$T_RES" | grep -q "error"; then
            FALLBACK_MODE="TRUE"
        fi
    else
        FALLBACK_MODE="TRUE"
    fi

    if [ "$FALLBACK_MODE" == "TRUE" ]; then
        local SAFE_MSG=$(echo "$MSG" | tr "'" " " | tr '"' " " | tr "\n" " ")
        send_to_daemon "cmd notification post -S bigtext -t '$TITLE' 'Tag' '$SAFE_MSG'"
    fi
}

if [ "$1" == "stop" ]; then
    echo "[!] Menghentikan Vision Daemon..."
    pkill -f "screenread.sh daemon"
    termux-wake-unlock 2>/dev/null
    echo "[✓] Daemon berhasil dihentikan."
    exit 0
fi

if [ "$1" == "daemon" ]; then
    termux-wake-lock 2>/dev/null
    LAST_FILE=$(ls -t /sdcard/Pictures/Screenshots/* /sdcard/DCIM/Screenshots/* 2>/dev/null | head -n 1)
    TMP_B64="/data/local/tmp/vision_b64.txt"
    TMP_JSON="/data/local/tmp/vision_payload.json"
    
    while true; do
        NEW_FILE=$(ls -t /sdcard/Pictures/Screenshots/* /sdcard/DCIM/Screenshots/* 2>/dev/null | head -n 1)
        
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 1 
            LAST_FILE="$NEW_FILE"
            
            base64 -w 0 "$NEW_FILE" > "$TMP_B64"
            
            jq -R -s '{
              "contents": [{
                "parts": [
                  {"text": "Extract all text from this image. Only output the text."},
                  {"inline_data": {"mime_type": "image/png", "data": (gsub("\n";"") | gsub("\r";""))}}
                ]
              }]
            }' "$TMP_B64" > "$TMP_JSON"
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            ERR=$(echo "$RESP" | jq -r '.error.message // empty')
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            
            if [ -n "$ERR" ]; then
                show_alert "Vision Error" "$ERR"
            elif [ -n "$TEXT" ]; then
                show_alert "Vision AI" "$TEXT"
            fi
            
            rm -f "$TMP_B64" "$TMP_JSON"
        fi
        sleep 2
    done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Vision AI (Termux UI + Auto Restart)    "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    echo "[X] Error: DaemonServer tidak terdeteksi di port $PORT!"
    exit 1
fi

send_to_daemon "appops set com.termux SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"
send_to_daemon "appops set com.termux.api SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"

pkg install -y netcat-openbsd curl jq termux-api >/dev/null 2>&1

if [ ! -d ~/storage/shared ]; then
    echo "[*] Meminta izin akses penyimpanan Termux..."
    termux-setup-storage
    exit 1
fi

if pgrep -f "screenread.sh daemon" >/dev/null; then
    echo "[!] Daemon lama terdeteksi. Memulai ulang dengan kode terbaru..."
    pkill -f "screenread.sh daemon"
    sleep 1
fi

echo "[+] Memicu proses daemon..."
nohup bash "$0" daemon > /sdcard/vision_daemon.log 2>&1 &

echo "[✓] ScreenMonitor Daemon AKTIF!"
