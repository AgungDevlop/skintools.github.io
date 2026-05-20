#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# VISION AI - NEON ENGINE CORE (POWERFUL)
# ==========================================

API_KEY="AIzaSyDSmrsPvRweMnpEuB0UptUeQwKLYWOTUOQ"
MODEL="gemini-2.5-flash"
PORT=45555
TMP_JSON="$HOME/vision_payload.json"
DAEMON_LOG="/sdcard/vision_daemon.log"

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT >/dev/null 2>&1
}

# Fungsi AI Core (Satu Fungsi untuk semua kebutuhan)
process_with_ai() {
    local TYPE="$1"
    local INPUT_DATA="$2"
    local IS_FILE="$3"

    echo "[$(date)] Memulai analisis AI (Mode: $TYPE)..." >> "$DAEMON_LOG"
    
    # Rakit Payload JSON yang cerdas (Mendeteksi apakah soal kuis atau teks)
    if [ "$IS_FILE" == "true" ]; then
        printf '{"contents":[{"parts":[{"text":"Analisis gambar ini. Jika ada pertanyaan/kuis, berikan jawaban tepat. Jika ada teks matematika/Inggris, selesaikan atau terjemahkan."},{"inline_data":{"mime_type":"image/png","data":"' > "$TMP_JSON"
        base64 -w 0 "$INPUT_DATA" >> "$TMP_JSON"
        printf '"}}]}]}' >> "$TMP_JSON"
    else
        jq -n --arg txt "$INPUT_DATA" '{
          "contents": [{"parts": [{"text": ("Tolong analisis teks berikut: " + $txt + ". Jika ini soal kuis/matematika/Inggris, berikan jawaban yang benar dan penjelasan singkat.")}]}]
        }' > "$TMP_JSON"
    fi

    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
    
    ERR=$(echo "$RESP" | jq -r '.error.message // empty')
    TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')

    if [ -n "$ERR" ]; then
        echo "[$(date)] API ERROR: $ERR" >> "$DAEMON_LOG"
        send_to_daemon "cmd notification post -S bigtext -t 'Vision AI Error' 'Tag' '$ERR'"
    elif [ -n "$TEXT" ]; then
        echo "[$(date)] AI Sukses menjawab." >> "$DAEMON_LOG"
        send_to_daemon "cmd notification post -S bigtext -t 'Vision AI Answer' 'Tag' '${TEXT//\'/ }'"
        # Tampilkan Modal Jika Termux API ada
        command -v termux-dialog >/dev/null 2>&1 && termux-dialog confirm -t "Jawaban AI" -i "$TEXT" >/dev/null 2>&1 &
    fi
    rm -f "$TMP_JSON"
}

# Daemon Loop
if [ "$1" == "daemon" ]; then
    echo "[$(date)] Daemon AI Dimulai..." > "$DAEMON_LOG"
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(get_latest_screenshot 2>/dev/null)
    LAST_CLIP=$(termux-clipboard-get 2>/dev/null)
    
    while true; do
        # 1. Pantau Screenshot
        NEW_FILE=$(get_latest_screenshot 2>/dev/null)
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 2
            LAST_FILE="$NEW_FILE"
            process_with_ai "VISUAL" "$NEW_FILE" "true"
            rm -f "$NEW_FILE" # Auto delete untuk bersih-bersih
        fi
        
        # 2. Pantau Clipboard (Text Trigger)
        NEW_CLIP=$(termux-clipboard-get 2>/dev/null)
        if [ -n "$NEW_CLIP" ] && [ "$NEW_CLIP" != "$LAST_CLIP" ] && [ ${#NEW_CLIP} -gt 10 ]; then
            LAST_CLIP="$NEW_CLIP"
            process_with_ai "TEXT" "$NEW_CLIP" "false"
        fi
        sleep 2
    done
fi

# Setup & Main CLI
if [ "$1" == "stop" ]; then
    pkill -f "screenread.sh daemon"
    termux-wake-unlock 2>/dev/null
    echo "[✓] Daemon berhasil dihentikan."
    exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VISION AI - SMART QUIZ SOLVER ACTIVE    "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
pkg install -y netcat-openbsd curl jq termux-api coreutils >/dev/null 2>&1
nohup bash "$0" daemon > /dev/null 2>&1 &
echo "[✓] Monitor aktif! Copy teks soal atau Screenshot layar Anda."
echo "[!] Debug log: tail -f $DAEMON_LOG"
