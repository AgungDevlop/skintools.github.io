#!/data/data/com.termux/files/usr/bin/bash

API_KEY="AIzaSyDSmrsPvRweMnpEuB0UptUeQwKLYWOTUOQ"
MODEL="gemini-2.5-flash"
PORT=45555
TMP_JSON="$HOME/vision_payload.json"
DAEMON_LOG="/sdcard/vision_daemon.log"

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT
}

# Fungsi ini lebih luas untuk meng-cover semua jalur storage Android
get_latest_screenshot() {
    local dirs=("/sdcard/Pictures/Screenshots" "/sdcard/DCIM/Screenshots" "/storage/emulated/0/Pictures/Screenshots" "/storage/emulated/0/DCIM/Screenshots")
    local LATEST_FILE=""
    local LATEST_TIME=0
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            FILE=$(ls -t "$dir"/*.jpg "$dir"/*.png 2>/dev/null | head -n 1)
            if [ -n "$FILE" ]; then
                TIME=$(stat -c %Y "$FILE" 2>/dev/null || echo 0)
                if [ "$TIME" -gt "$LATEST_TIME" ]; then
                    LATEST_TIME=$TIME
                    LATEST_FILE="$FILE"
                fi
            fi
        fi
    done
    echo "$LATEST_FILE"
}

if [ "$1" == "stop" ]; then
    pkill -f "screenread.sh daemon"
    termux-wake-unlock 2>/dev/null
    echo "[✓] Daemon berhenti."
    exit 0
fi

if [ "$1" == "daemon" ]; then
    echo "[$(date)] --- DAEMON START ---" > "$DAEMON_LOG"
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(get_latest_screenshot)
    echo "[$(date)] Awal path: $LAST_FILE" >> "$DAEMON_LOG"
    
    while true; do
        NEW_FILE=$(get_latest_screenshot)
        
        # DEBUGGING: Cek apakah file terdeteksi
        if [ -z "$NEW_FILE" ]; then
            # Jangan log terus menerus agar log tidak penuh, cukup setiap 10 detik
            if (( $(date +%s) % 10 == 0 )); then
                echo "[$(date)] Mencari screenshot... (Belum ditemukan)" >> "$DAEMON_LOG"
            fi
        elif [ "$NEW_FILE" != "$LAST_FILE" ]; then
            echo "[$(date)] DETEKSI FILE BARU: $NEW_FILE" >> "$DAEMON_LOG"
            LAST_FILE="$NEW_FILE"
            
            # Konversi Base64
            if base64 -w 0 "$NEW_FILE" > /dev/null 2>&1; then
                echo "[$(date)] Base64 OK" >> "$DAEMON_LOG"
                
                # Payload
                printf '{"contents":[{"parts":[{"text":"Jawab pertanyaan di gambar ini."},{"inline_data":{"mime_type":"image/png","data":"' > "$TMP_JSON"
                base64 -w 0 "$NEW_FILE" >> "$TMP_JSON"
                printf '"}}]}]}' >> "$TMP_JSON"
                
                echo "[$(date)] Mengirim ke Gemini..." >> "$DAEMON_LOG"
                RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
                
                TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
                
                if [ -n "$TEXT" ]; then
                    echo "[$(date)] SUCCESS: Mendapatkan jawaban." >> "$DAEMON_LOG"
                    send_to_daemon "cmd notification post -S bigtext -t 'Vision AI' 'Tag' '${TEXT//\'/ }'"
                else
                    echo "[$(date)] API RESP EMPTY: $RESP" >> "$DAEMON_LOG"
                fi
                rm -f "$TMP_JSON"
            else
                echo "[$(date)] GAGAL Base64 pada file: $NEW_FILE" >> "$DAEMON_LOG"
            fi
        fi
        sleep 2
    done
fi

# Main Setup
if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    echo "[!] Port $PORT tutup. Jalankan Daemon Server di aplikasi Neon."
    exit 1
fi

if pgrep -f "screenread.sh daemon" >/dev/null; then
    pkill -f "screenread.sh daemon"
    sleep 1
fi

nohup bash "$0" daemon > /dev/null 2>&1 &
echo "[✓] ScreenMonitor Daemon AKTIF!"
echo "[!] Pantau log: tail -f /sdcard/vision_daemon.log"
