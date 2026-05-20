#!/data/data/com.termux/files/usr/bin/bash

API_KEY="AIzaSyAnHG_bGWjvOxsUptlgsUb_FOpopzp4YDY"

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 45555
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
    
    while true; do
        NEW_FILE=$(ls -t /sdcard/Pictures/Screenshots/* /sdcard/DCIM/Screenshots/* 2>/dev/null | head -n 1)
        
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            LAST_FILE="$NEW_FILE"
            
            B64=$(base64 -w 0 "$NEW_FILE")
            PAYLOAD=$(jq -n --arg b64 "$B64" '{"contents":[{"parts":[{"inline_data":{"mime_type":"image/png","data":$b64}},{"text":"Extract all text from this image. Only output the text."}]}]}')
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY")
            
            ERR=$(echo "$RESP" | jq -r '.error.message // empty')
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            
            if [ -n "$ERR" ]; then
                SAFE_ERR=$(echo "$ERR" | tr "'" " " | tr '"' " " | tr "\n" " ")
                send_to_daemon "cmd notification post -S bigtext -t 'Vision Error' 'Tag' '$SAFE_ERR'"
            elif [ -n "$TEXT" ]; then
                SAFE_TEXT=$(echo "$TEXT" | tr "'" " " | tr '"' " " | tr "\n" " ")
                send_to_daemon "cmd notification post -S bigtext -t 'Vision AI' 'Tag' '$SAFE_TEXT'"
            fi
        fi
        sleep 2
    done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Vision AI via Direct Socket 45555 "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! nc -z 127.0.0.1 45555 2>/dev/null; then
    echo "[X] Error: DaemonServer tidak terdeteksi di port 45555!"
    exit 1
fi

echo "[*] Memeriksa dependencies sistem..."
pkg install -y netcat-openbsd curl jq termux-api >/dev/null 2>&1

if [ ! -d ~/storage/shared ]; then
    echo "[*] Meminta izin akses penyimpanan Termux..."
    termux-setup-storage
    exit 1
fi

if pgrep -f "screenread.sh daemon" >/dev/null; then
    echo "[!] Daemon sudah beroperasi."
    exit 0
fi

echo "[+] Memicu proses daemon..."
nohup bash "$0" daemon > /sdcard/vision_daemon.log 2>&1 &

echo "[✓] ScreenMonitor Daemon AKTIF!"
