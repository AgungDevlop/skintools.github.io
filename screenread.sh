#!/data/data/com.termux/files/usr/bin/bash

API_KEY="AIzaSyDSmrsPvRweMnpEuB0UptUeQwKLYWOTUOQ"
MODEL="gemini-2.5-flash"
PORT=45555
TMP_JSON="$HOME/vision_payload.json"
REAL_PATH="$(realpath "$0")"

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT
}

show_alert() {
    local TITLE="$1"
    local MSG="$2"
    local SAFE_MSG=$(echo "$MSG" | tr "'" " " | tr '"' " " | tr "\n" " ")
    
    send_to_daemon "cmd notification post -S bigtext -t '$TITLE' 'Tag' '$SAFE_MSG'"
    
    if pm list packages 2>/dev/null | grep -q "com.termux.api"; then
        termux-toast -c gray "$TITLE Selesai" &
        termux-dialog confirm -t "$TITLE" -i "$MSG" >/dev/null 2>&1 &
    fi
}

if [ "$1" == "clipboard" ]; then
    CLIP=$(termux-clipboard-get 2>/dev/null)
    if [ -z "$CLIP" ]; then
        show_alert "Vision AI" "Clipboard kosong atau tidak bisa dibaca."
        exit 0
    fi
    
    command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "AI memproses soal dari clipboard..." &
    
    jq -n --arg txt "$CLIP" '{
      "contents": [{
        "parts": [{"text": ("Selesaikan pertanyaan, kuis, atau soal matematika berikut dengan jawaban yang paling tepat, detail, dan penjelasan langkah demi langkah (dukung semua bahasa termasuk Inggris & Indonesia):\n\n" + $txt)}]
      }]
    }' > "$TMP_JSON"
    
    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
    
    ERR=$(echo "$RESP" | jq -r '.error.message // empty')
    TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
    
    if [ -n "$ERR" ]; then
        show_alert "Vision Error" "$ERR"
    elif [ -n "$TEXT" ]; then
        show_alert "Vision AI (Teks)" "$TEXT"
    fi
    
    rm -f "$TMP_JSON"
    exit 0
fi

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
    command -v termux-notification >/dev/null 2>&1 && termux-notification-remove "vision_ai_daemon" 2>/dev/null
    exit 0
fi

if [ "$1" == "daemon" ]; then
    echo "[$(date)] Daemon AI Dimulai..." > /sdcard/vision_daemon.log
    termux-wake-lock 2>/dev/null
    
    if command -v termux-notification >/dev/null 2>&1; then
        termux-notification \
            -i "vision_ai_daemon" \
            --title "Vision AI Aktif 🚀" \
            --content "AI siap menjawab soal dari layar & clipboard." \
            --ongoing \
            --button1 "Tanya (Clipboard)" \
            --button1-action "bash $REAL_PATH clipboard" \
            --button2 "Stop AI" \
            --button2-action "bash $REAL_PATH stop"
    fi
    
    LAST_FILE=$(get_latest_screenshot)
    
    while true; do
        NEW_FILE=$(get_latest_screenshot)
        
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 2
            LAST_FILE="$NEW_FILE"
            
            command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "AI membedah kuis dari layar..." &
            
            MIME="image/png"
            [[ "$NEW_FILE" == *.jpg ]] || [[ "$NEW_FILE" == *.jpeg ]] && MIME="image/jpeg"
            
            printf '{"contents":[{"parts":[{"text":"Analisis gambar ini secara detail. Jika terdapat soal kuis, soal ujian, matematika, bahasa Inggris, atau pertanyaan apa pun, berikan jawaban yang paling tepat beserta cara penyelesaian dan penjelasannya secara ringkas. Jika bukan soal, jelaskan saja isi gambar ini."},{"inline_data":{"mime_type":"%s","data":"' "$MIME" > "$TMP_JSON"
            
            if base64 -w 0 "$NEW_FILE" >> "$TMP_JSON"; then
                printf '"}}]}]}' >> "$TMP_JSON"
            else
                continue
            fi
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            rm -f "$NEW_FILE"
            
            ERR=$(echo "$RESP" | jq -r '.error.message // empty')
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            
            if [ -n "$ERR" ]; then
                show_alert "Vision Error" "$ERR"
            elif [ -n "$TEXT" ]; then
                show_alert "Vision AI (Layar)" "$TEXT"
            fi
            
            rm -f "$TMP_JSON"
        fi
        sleep 2
    done
fi

if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    exit 1
fi

send_to_daemon "appops set com.termux SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"
send_to_daemon "appops set com.termux.api SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1"

pkg install -y netcat-openbsd curl jq termux-api coreutils >/dev/null 2>&1

if [ ! -d ~/storage/shared ]; then
    termux-setup-storage
    exit 1
fi

if pgrep -f "screenread.sh daemon" >/dev/null; then
    pkill -f "screenread.sh daemon"
    sleep 1
fi

nohup bash "$0" daemon > /sdcard/vision_daemon.log 2>&1 &
