#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# VISION AI - NEON ENGINE CORE (POWERFUL UNIVERSAL AI)
# ========================================================

CONFIG_FILE="$HOME/.vision_config"
PORT=45555
DAEMON_LOG="/sdcard/vision_daemon.log"
TMP_JSON="$HOME/vision_payload.json"

# --- 1. SETUP CONFIGURATION ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INITIAL SETUP - VISION AI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Masukkan API Key Gemini: " INPUT_KEY
    echo "Pilih Model AI:"
    echo "1) gemini-2.5-flash (Cepat, Hemat Token)"
    echo "2) gemini-1.5-pro (Sangat Cerdas, Akurat)"
    read -p "Pilihan (1/2): " MODEL_CHOICE
    
    [ "$MODEL_CHOICE" == "2" ] && SEL_MODEL="gemini-1.5-pro" || SEL_MODEL="gemini-2.5-flash"
    
    echo "API_KEY='$INPUT_KEY'" > "$CONFIG_FILE"
    echo "MODEL='$SEL_MODEL'" >> "$CONFIG_FILE"
    echo "[✓] Konfigurasi tersimpan."
fi
source "$CONFIG_FILE"

# --- 2. CORE FUNCTIONS ---
send_to_daemon() { echo "$1" | nc 127.0.0.1 $PORT >/dev/null 2>&1; }

debug_log() { echo "[$(date)] $1" >> "$DAEMON_LOG"; }

show_output() {
    local TITLE="$1"
    local MSG="$2"
    local SAFE_MSG=$(echo "$MSG" | tr "'" " " | tr '"' " " | tr "\n" " ")
    
    debug_log "Mengirim hasil ke sistem..."
    send_to_daemon "cmd notification post -S bigtext -t '$TITLE' 'Tag' '$SAFE_MSG'"
    
    if pm list packages 2>/dev/null | grep -q "com.termux.api"; then
        termux-toast -c gray "AI $TITLE Selesai" &
        termux-dialog confirm -t "$TITLE" -i "$MSG" >/dev/null 2>&1 &
    fi
}

get_latest_screenshot() {
    local LATEST_FILE=""
    local LATEST_TIME=0
    for dir in "/sdcard/Pictures/Screenshots" "/sdcard/DCIM/Screenshots"; do
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

# --- 3. DAEMON MODE ---
if [ "$1" == "daemon" ]; then
    debug_log "DAEMON START"
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(get_latest_screenshot)
    LAST_CLIP=$(termux-clipboard-get 2>/dev/null)
    
    while true; do
        # Monitor Screenshot
        NEW_FILE=$(get_latest_screenshot)
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 2
            LAST_FILE="$NEW_FILE"
            debug_log "Screenshot terdeteksi: $NEW_FILE"
            
            MIME="image/png"
            [[ "$NEW_FILE" == *.jpg ]] || [[ "$NEW_FILE" == *.jpeg ]] && MIME="image/jpeg"
            
            printf '{"contents":[{"parts":[{"text":"Analisis soal/kuis ini. Jawab dengan singkat dan tepat."},{"inline_data":{"mime_type":"%s","data":"' "$MIME" > "$TMP_JSON"
            base64 -w 0 "$NEW_FILE" >> "$TMP_JSON"
            printf '"}}]}]}' >> "$TMP_JSON"
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            [ -n "$TEXT" ] && show_output "Vision AI (Visual)" "$TEXT" || debug_log "API ERROR: $RESP"
            
            rm -f "$NEW_FILE" "$TMP_JSON"
        fi
        
        # Monitor Clipboard (Text Trigger)
        NEW_CLIP=$(termux-clipboard-get 2>/dev/null)
        if [ -n "$NEW_CLIP" ] && [ "$NEW_CLIP" != "$LAST_CLIP" ] && [ ${#NEW_CLIP} -gt 15 ]; then
            LAST_CLIP="$NEW_CLIP"
            debug_log "Teks baru terdeteksi di clipboard"
            
            jq -n --arg txt "$NEW_CLIP" '{
              "contents": [{"parts": [{"text": ("Jawab soal/teks berikut: " + $txt)}]}]
            }' > "$TMP_JSON"
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            [ -n "$TEXT" ] && show_output "Vision AI (Teks)" "$TEXT" || debug_log "API ERROR: $RESP"
            
            rm -f "$TMP_JSON"
        fi
        sleep 2
    done
fi

# --- 4. CLI COMMANDS ---
if [ "$1" == "stop" ]; then
    pkill -f "screenread.sh daemon"
    echo "[✓] Daemon dihentikan."
    exit 0
fi

echo "[*] Inisialisasi Sistem..."
pkg install -y netcat-openbsd curl jq termux-api coreutils >/dev/null 2>&1
send_to_daemon "appops set com.termux SYSTEM_ALERT_WINDOW allow"
send_to_daemon "appops set com.termux.api SYSTEM_ALERT_WINDOW allow"

if pgrep -f "screenread.sh daemon" >/dev/null; then
    pkill -f "screenread.sh daemon"
    sleep 1
fi

nohup bash "$0" daemon > /dev/null 2>&1 &
echo "[✓] Vision AI Aktif!"
echo "[!] Debug log: tail -f $DAEMON_LOG"
