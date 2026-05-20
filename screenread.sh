#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# VISION AI - POWERFUL CORE ENGINE (v3.0)
# ========================================================

CONFIG_FILE="$HOME/.vision_config"
PORT=45555
TMP_JSON="$HOME/vision_payload.json"
DAEMON_LOG="/sdcard/vision_daemon.log"

# Setup Konfigurasi Interaktif
if [ ! -f "$CONFIG_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INITIAL SETUP - VISION AI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Masukkan API Key Gemini: " INPUT_KEY
    echo "Pilih Model:"
    echo "1) gemini-2.5-flash (Fast - Default)"
    echo "2) gemini-1.5-pro (Precise - Complex Math/Code)"
    read -p "Pilihan (1/2): " INPUT_MODEL
    
    [[ "$INPUT_MODEL" == "2" ]] && SEL_MODEL="gemini-1.5-pro" || SEL_MODEL="gemini-2.5-flash"
    
    echo "API_KEY=\"$INPUT_KEY\"" > "$CONFIG_FILE"
    echo "MODEL=\"$SEL_MODEL\"" >> "$CONFIG_FILE"
    echo "[✓] Konfigurasi tersimpan."
fi
source "$CONFIG_FILE"

send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT >/dev/null 2>&1
}

# Modul Notifikasi & Modal
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

# Processor Utama (Mendeteksi Kuis/Soal)
process_ai() {
    local TYPE="$1"
    local INPUT_VAL="$2"
    
    echo "[$(date)] Menganalisis ($TYPE)..." >> "$DAEMON_LOG"
    
    if [ "$TYPE" == "visual" ]; then
        printf '{"contents":[{"parts":[{"text":"Analisis gambar ini. Jika ini soal kuis/matematika/bahasa Inggris, berikan jawaban tepat & penjelasan. Jika teks biasa, rangkum."},{"inline_data":{"mime_type":"image/png","data":"' > "$TMP_JSON"
        base64 -w 0 "$INPUT_VAL" >> "$TMP_JSON"
        printf '"}}]}]}' >> "$TMP_JSON"
    else
        jq -n --arg txt "$INPUT_VAL" '{
          "contents": [{"parts": [{"text": ("Tolong jawab soal berikut: " + $txt + ". Berikan jawaban yang tepat dan penjelasan ringkas.")}]}]
        }' > "$TMP_JSON"
    fi

    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
    
    ERR=$(echo "$RESP" | jq -r '.error.message // empty')
    TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
    
    if [ -n "$ERR" ]; then
        echo "[$(date)] ERROR: $ERR" >> "$DAEMON_LOG"
        show_alert "Vision Error" "$ERR"
    elif [ -n "$TEXT" ]; then
        show_alert "Vision AI Answer" "$TEXT"
    fi
    rm -f "$TMP_JSON"
}

# Daemon Mode
if [ "$1" == "daemon" ]; then
    echo "[$(date)] Daemon Start." > "$DAEMON_LOG"
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(ls -t /sdcard/DCIM/Screenshots/* 2>/dev/null | head -n 1)
    LAST_CLIP=$(termux-clipboard-get 2>/dev/null)
    
    while true; do
        # Trigger 1: Screenshot
        NEW_FILE=$(ls -t /sdcard/DCIM/Screenshots/* 2>/dev/null | head -n 1)
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 2
            LAST_FILE="$NEW_FILE"
            process_ai "visual" "$NEW_FILE"
            rm -f "$NEW_FILE" 
        fi
        
        # Trigger 2: Clipboard (Copy teks soal)
        NEW_CLIP=$(termux-clipboard-get 2>/dev/null)
        if [ -n "$NEW_CLIP" ] && [ "$NEW_CLIP" != "$LAST_CLIP" ] && [ ${#NEW_CLIP} -gt 10 ]; then
            LAST_CLIP="$NEW_CLIP"
            process_ai "text" "$NEW_CLIP"
        fi
        sleep 2
    done
fi

# Main Setup
if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    echo "[X] Error: Port $PORT tidak aktif. Jalankan Daemon di Aplikasi Neon."
    exit 1
fi

pkg install -y netcat-openbsd curl jq termux-api coreutils >/dev/null 2>&1
pgrep -f "screenread.sh daemon" | xargs kill -9 >/dev/null 2>&1
nohup bash "$0" daemon > /dev/null 2>&1 &

echo "[✓] Vision AI Aktif!"
echo "    - Screenshot akan dianalisis otomatis & dihapus."
echo "    - Copy teks soal apa pun untuk langsung dijawab."
echo "    - Pantau log: tail -f /sdcard/vision_daemon.log"
