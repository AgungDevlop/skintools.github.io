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
    local SAFE_MSG=$(echo "$MSG" | tr "'" " " | tr '"' " " | tr "\n" " ")
    
    send_to_daemon "cmd notification post -S bigtext -t '$TITLE' 'Tag' '$SAFE_MSG'"
    
    command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "$TITLE Selesai" &
    command -v termux-dialog >/dev/null 2>&1 && termux-dialog confirm -t "$TITLE" -i "$MSG" >/dev/null 2>&1 &
}

get_latest_screenshot() {
    local LATEST_FILE=""
    local LATEST_TIME=0
    for dir in "/sdcard/Pictures/Screenshots" "/sdcard/DCIM/Screenshots"; do
        if [ -d "$dir" ]; then
            FILE=$(ls -t "$dir" 2>/dev/null | head -n 1)
            if [ -n "$FILE" ]; then
                TIME=$(stat -c %Y "$dir/$FILE" 2>/dev/null || echo 0)
                if [ "$TIME" -gt "$LATEST_TIME" ]; then
                    LATEST_TIME=$TIME
                    LATEST_FILE="$dir/$FILE"
                fi
            fi
        fi
    done
    echo "$LATEST_FILE"
}

if [ "$1" == "stop" ]; then
    pkill -f "screenread.sh daemon"
    termux-wake-unlock 2>/dev/null
    echo "[✓] Daemon berhasil dihentikan."
    exit 0
fi

if [ "$1" == "daemon" ]; then
    echo "[$(date)] Daemon AI Dimulai..." > /sdcard/vision_daemon.log
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(get_latest_screenshot)
    echo "[$(date)] Target pemantauan awal: $LAST_FILE" >> /sdcard/vision_daemon.log
    
    TMP_JSON="/data/local/tmp/vision_payload.json"
    
    while true; do
        NEW_FILE=$(get_latest_screenshot)
        
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            echo "[$(date)] Screenshot baru terdeteksi: $NEW_FILE" >> /sdcard/vision_daemon.log
            sleep 2
            LAST_FILE="$NEW_FILE"
            
            command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "AI sedang menganalisis layar..." &
            
            MIME="image/png"
            [[ "$NEW_FILE" == *.jpg ]] || [[ "$NEW_FILE" == *.jpeg ]] && MIME="image/jpeg"
            
            echo "[$(date)] Merakit payload (OOM Safe Stream)..." >> /sdcard/vision_daemon.log
            
            printf '{"contents":[{"parts":[{"text":"Extract all text from this image. Only output the text."},{"inline_data":{"mime_type":"%s","data":"' "$MIME" > "$TMP_JSON"
            
            if base64 -w 0 "$NEW_FILE" >> "$TMP_JSON"; then
                printf '"}}]}]}' >> "$TMP_JSON"
                echo "[$(date)] Perakitan JSON sukses, mengirim ke Gemini..." >> /sdcard/vision_daemon.log
            else
                echo "[$(date)] GAGAL: Konversi Base64 error" >> /sdcard/vision_daemon.log
                continue
            fi
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            ERR=$(echo "$RESP" | jq -r '.error.message // empty')
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            
            if [ -n "$ERR" ]; then
                echo "[$(date)] API ERROR: $ERR" >> /sdcard/vision_daemon.log
                show_alert "Vision Error" "$ERR"
            elif [ -n "$TEXT" ]; then
                echo "[$(date)] Teks berhasil ditangkap" >> /sdcard/vision_daemon.log
                show_alert "Vision AI" "$TEXT"
            else
                echo "[$(date)] GAGAL KONEKSI: API respons kosong" >> /sdcard/vision_daemon.log
            fi
            
            rm -f "$TMP_JSON"
        fi
        sleep 2
    done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Vision AI (OOM Safe & Async UI Mode)    "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    echo "[X] GAGAL: Port $PORT (Daemon Java) tidak merespons!"
    exit 1
fi
echo "[✓] Koneksi ke Port $PORT stabil."

send_to_daemon "appops set com.termux SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"
send_to_daemon "appops set com.termux.api SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"
echo "[✓] Injeksi Bypass Izin Pop-Up berhasil."

pkg install -y netcat-openbsd curl jq termux-api >/dev/null 2>&1

if [ ! -d ~/storage/shared ]; then
    echo "[X] GAGAL: Termux belum mendapat izin penyimpanan file."
    termux-setup-storage
    exit 1
fi

if pgrep -f "screenread.sh daemon" >/dev/null; then
    echo "[!] Membunuh daemon versi lama..."
    pkill -f "screenread.sh daemon"
    sleep 1
fi

nohup bash "$0" daemon > /sdcard/vision_daemon.log 2>&1 &

echo "[✓] ScreenMonitor Daemon BERHASIL START!"
echo "    Ketik perintah ini untuk memantau langsung:"
echo "    tail -f /sdcard/vision_daemon.log"
