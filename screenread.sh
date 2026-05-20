#!/data/data/com.termux/files/usr/bin/bash
# Vision AI - Ultimate Quiz Solver & Clipboard Monitor
# Author: Agung Dev

CONFIG_FILE="$HOME/.vision_ai_config"
PORT=45555
TMP_JSON="$HOME/vision_payload.json"
TMP_B64="$HOME/vision_b64.txt"

# === SISTEM KONFIGURASI INTERAKTIF ===
setup_config() {
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "       VISION AI - SETUP KONFIGURASI      "
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Masukkan Gemini API Key Anda: " input_key
    
    echo ""
    echo "Pilih Model AI:"
    echo "1) gemini-2.5-flash (Sangat Cepat, Cocok untuk kuis & harian)"
    echo "2) gemini-2.5-pro   (Sangat Pintar, Logika kompleks)"
    read -p "Pilihan (1/2): " model_choice
    
    if [ "$model_choice" == "2" ]; then
        input_model="gemini-2.5-pro"
    else
        input_model="gemini-2.5-flash"
    fi
    
    echo "API_KEY=\"$input_key\"" > "$CONFIG_FILE"
    echo "MODEL=\"$input_model\"" >> "$CONFIG_FILE"
    echo ""
    echo "[✓] Konfigurasi berhasil disimpan!"
    sleep 1
}

# Muat konfigurasi, jika belum ada, paksa setup
if [ ! -f "$CONFIG_FILE" ] || [ "$1" == "--setup" ]; then
    setup_config
fi
source "$CONFIG_FILE"

# === FUNGSI INTI ===
send_to_daemon() {
    echo "$1" | nc 127.0.0.1 $PORT
}

show_alert() {
    local TITLE="$1"
    local MSG="$2"
    local SAFE_MSG=$(echo "$MSG" | tr "'" " " | tr '"' " " | tr "\n" " ")
    
    send_to_daemon "cmd notification post -S bigtext -t '$TITLE' 'Tag' '$SAFE_MSG'"
    command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "$TITLE Selesai" &
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

# === BACKGROUND DAEMON ===
if [ "$1" == "daemon" ]; then
    echo "[$(date)] Daemon AI Dimulai..." > /sdcard/vision_daemon.log
    termux-wake-lock 2>/dev/null
    
    LAST_FILE=$(get_latest_screenshot)
    LAST_CLIP=$(termux-clipboard-get 2>/dev/null)
    
    while true; do
        # 1. PEMANTAUAN SCREENSHOT (GAMBAR -> KUIS)
        NEW_FILE=$(get_latest_screenshot)
        if [ -n "$NEW_FILE" ] && [ "$NEW_FILE" != "$LAST_FILE" ]; then
            sleep 1 
            LAST_FILE="$NEW_FILE"
            
            command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "Menganalisis Soal di Layar..." &
            echo "[$(date)] Screenshot terdeteksi: $NEW_FILE" >> /sdcard/vision_daemon.log
            
            MIME="image/png"
            [[ "$NEW_FILE" == *.jpg ]] || [[ "$NEW_FILE" == *.jpeg ]] && MIME="image/jpeg"
            
            printf '{"contents":[{"parts":[{"text":"Anda adalah asisten cerdas. Analisis layar ini. Jika ini adalah kuis/soal ujian, berikan jawaban yang paling tepat secara langsung dan singkat. Jika bukan soal, jelaskan konteks utama dari gambar ini."},{"inline_data":{"mime_type":"%s","data":"' "$MIME" > "$TMP_JSON"
            
            if base64 -w 0 "$NEW_FILE" >> "$TMP_JSON"; then
                printf '"}}]}]}' >> "$TMP_JSON"
                
                RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
                
                ERR=$(echo "$RESP" | jq -r '.error.message // empty')
                TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
                
                if [ -n "$ERR" ]; then
                    show_alert "AI Error (Gambar)" "$ERR"
                elif [ -n "$TEXT" ]; then
                    show_alert "AI Vision Answer" "$TEXT"
                fi
                
                # FITUR ANTI-NYAMPAH GALERI: Hapus screenshot seketika!
                rm -f "$NEW_FILE"
                send_to_daemon "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$NEW_FILE >/dev/null 2>&1"
                echo "[$(date)] Gambar dihapus dari memori." >> /sdcard/vision_daemon.log
            fi
            rm -f "$TMP_JSON"
        fi

        # 2. PEMANTAUAN CLIPBOARD (BLOK TEKS -> COPY -> TANYA AI)
        NEW_CLIP=$(termux-clipboard-get 2>/dev/null)
        if [ -n "$NEW_CLIP" ] && [ "$NEW_CLIP" != "$LAST_CLIP" ] && [ ${#NEW_CLIP} -gt 3 ]; then
            LAST_CLIP="$NEW_CLIP"
            
            command -v termux-toast >/dev/null 2>&1 && termux-toast -c gray "Memproses Teks Bawaan..." &
            echo "[$(date)] Teks Salinan Baru Terdeteksi" >> /sdcard/vision_daemon.log
            
            jq -n --arg txt "$NEW_CLIP" '{
              "contents": [{
                "parts": [
                  {"text": "Anda adalah asisten cerdas. Jawab atau selesaikan instruksi dari teks yang disalin pengguna berikut ini dengan cepat, tepat, dan padat:\n\n\($txt)"}
                ]
              }]
            }' > "$TMP_JSON"
            
            RESP=$(curl -s -X POST -H "Content-Type: application/json" -d @"$TMP_JSON" "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY")
            
            ERR=$(echo "$RESP" | jq -r '.error.message // empty')
            TEXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[0].text // empty')
            
            if [ -n "$ERR" ]; then
                show_alert "AI Error (Teks)" "$ERR"
            elif [ -n "$TEXT" ]; then
                show_alert "AI Text Answer" "$TEXT"
            fi
            
            rm -f "$TMP_JSON"
        fi
        
        sleep 2
    done
fi

# === CLI STARTUP ===
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Vision AI (Quiz Solver & Smart Copier)  "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
    echo "[X] GAGAL: Port $PORT (Daemon Java) tidak merespons!"
    exit 1
fi

pkg install -y netcat-openbsd curl jq termux-api coreutils >/dev/null 2>&1

if pgrep -f "screenread.sh daemon" >/dev/null; then
    echo "[!] Membunuh daemon versi lama..."
    pkill -f "screenread.sh daemon"
    sleep 1
fi

nohup bash "$0" daemon > /sdcard/vision_daemon.log 2>&1 &

echo "[✓] ScreenMonitor Daemon BERHASIL START!"
echo ""
echo "FITUR AKTIF:"
echo "1. Jawab via Screenshot (Usap 3 Jari). AI menjawab & gambar langsung Dihapus dari galeri!"
echo "2. Jawab via Blok Teks (Copy). Blok teks di HP, tekan Salin/Copy, AI akan langsung menjawabnya."
echo ""
echo "Ketik: bash screenread.sh --setup  (Untuk mengganti API Key / Model)"
echo "Ketik: bash screenread.sh stop     (Untuk mematikan sistem)"
