#!/bin/bash

# ==============================================================================
#  DNS MONITOR - V17 (CLEAN EXIT & STABILITY FIX)
# ==============================================================================

set -o pipefail

# --- 1. Setup Global Variables ---
CURRENT_DIR="$(dirname "$0")"
SESSION_ERROR_LOG="${CURRENT_DIR}/.session_failures.tmp"
LOCK_DIR="/tmp/dns_monitor_v17.lock" 
SCAN_ITERATION=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
CLR_LINE='\033[K' 

# --- 2. System Functions ---

cleanup_and_exit() {
    # [FIX] Matikan trap agar tidak looping (Double Output Fix)
    trap - INT TERM EXIT
    
    # Hapus file lock & temp
    rm -rf "$LOCK_DIR"
    rm -f "$SESSION_ERROR_LOG"
    
    # [FIX] Hapus tput cup agar tidak lompat jauh
    echo -e "\n${RED}🛑 STOP SIGNAL RECEIVED.${NC} Shutdown complete."
    exit 0
}

# Trap untuk Ctrl+C (SIGINT) dan Termination (SIGTERM)
trap cleanup_and_exit INT TERM EXIT

if mkdir "$LOCK_DIR" 2>/dev/null; then
    : 
else
    echo -e "${RED}❌ ERROR: Script is already running!${NC}"
    # Lepas trap sebelum exit agar tidak memicu cleanup message
    trap - INT TERM EXIT
    exit 1
fi

# --- 3. Helper Functions ---

load_config() {
    if [ -f "config.env" ]; then
        source config.env
        TEAMS_WEBHOOK_URL=$(echo "$TEAMS_WEBHOOK_URL" | tr -d '\r')
        SOURCE_SERVERS=$(echo "$SOURCE_SERVERS" | tr -d '\r')
        DOMAIN_LIST_PATH=$(echo "$DOMAIN_LIST_PATH" | tr -d '\r')
        FAILURE_OUTPUT=$(echo "$FAILURE_OUTPUT" | tr -d '\r')
        PER_DOMAIN_DELAY=$(echo "$PER_DOMAIN_DELAY" | tr -d '\r')
        SCAN_INTERVAL=$(echo "$SCAN_INTERVAL" | tr -d '\r')
        MAX_LOG_SIZE_MB=$(echo "$MAX_LOG_SIZE_MB" | tr -d '\r')
        
        [[ -z "$PER_DOMAIN_DELAY" ]] && PER_DOMAIN_DELAY=1
        [[ -z "$SCAN_INTERVAL" ]] && SCAN_INTERVAL=60
        [[ -z "$MAX_LOG_SIZE_MB" ]] && MAX_LOG_SIZE_MB=5
    else
        echo "Error: config.env not found."
        exit 1
    fi
}

check_internet_connection() {
    if ! ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then return 1; fi
    return 0
}

rotate_log_if_needed() {
    if [ -f "$FAILURE_OUTPUT" ]; then
        local file_size=$(stat -c%s "$FAILURE_OUTPUT" 2>/dev/null || wc -c < "$FAILURE_OUTPUT")
        local max_bytes=$((MAX_LOG_SIZE_MB * 1024 * 1024))
        if [ "$file_size" -gt "$max_bytes" ]; then
            mv "$FAILURE_OUTPUT" "${FAILURE_OUTPUT}.$(date "+%Y%m%d_%H%M%S").bak"
            touch "$FAILURE_OUTPUT"
        fi
    fi
}

reset_cursor() { printf "\033[H"; }
clear_rest_of_screen() { printf "\033[J"; }

draw_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
██████╗ ███╗   ██╗███████╗    ███████╗ ██████╗ █████╗ ███╗   ██╗
██╔══██╗████╗  ██║██╔════╝    ██╔════╝██╔════╝██╔══██╗████╗  ██║
██║  ██║██╔██╗ ██║███████╗    ███████╗██║     ███████║██╔██╗ ██║
██║  ██║██║╚██╗██║╚════██║    ╚════██║██║     ██╔══██║██║╚██╗██║
██████╔╝██║ ╚████║███████║    ███████║╚██████╗██║  ██║██║ ╚████║
╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
    echo -e "${NC}${CLR_LINE}"
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}${CLR_LINE}"
    echo -e "  ${BOLD}:: SYSTEM STATUS ::${NC}${CLR_LINE}"
    echo -e "  ${CYAN}▶${NC} Iteration : ${BOLD}#$SCAN_ITERATION${NC}${CLR_LINE}"
    echo -e "  ${CYAN}▶${NC} Servers   : $SOURCE_SERVERS${CLR_LINE}"
    echo -e "  ${CYAN}▶${NC} Config    : ${GREEN}LIVE${NC} (Delay: ${PER_DOMAIN_DELAY}s | Loop: ${SCAN_INTERVAL}s)${CLR_LINE}"
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}${CLR_LINE}"
}

draw_progress_bar() {
    local current=$1; local total=$2; local width=45
    [[ $total -eq 0 ]] && total=1
    local percent=$(( 100 * current / total ))
    local filled=$(( width * current / total ))
    local empty=$(( width - filled ))
    local bar_filled=$(printf "%0.s█" $(seq 1 $filled))
    local bar_empty=$(printf "%0.s░" $(seq 1 $empty))
    echo -e "  ${BOLD}SCAN PROGRESS:${NC} ${percent}%${CLR_LINE}"
    echo -e "  ${CYAN}[${bar_filled}${NC}${bar_empty}${CYAN}]${NC} (${current}/${total})${CLR_LINE}"
    echo -e "${CLR_LINE}"
}

log_failure() {
    local domain="$1"; local server="$2"; local reason="$3"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_block="=========================
ITERATION        : #$SCAN_ITERATION
DOMAIN           : $domain
SOURCE SERVER    : $server
LAST CHECKED     : $timestamp
REASON           : $reason
========================="
    echo "$log_block" >> "$FAILURE_OUTPUT"
    echo "$log_block" >> "$SESSION_ERROR_LOG"
}

send_teams_notification() {
    if [ -s "$SESSION_ERROR_LOG" ]; then
        echo -e "\n  🔔 ${YELLOW}Sending notification to Teams...${NC}${CLR_LINE}"
        local content
        content=$(cat "$SESSION_ERROR_LOG" | sed 's/\\/\\\\/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
        local json_payload="{ \"title\": \"DNS MONITOR (#$SCAN_ITERATION) - ISSUES FOUND\", \"text\": \"<pre>${content}</pre>\" }"
        local http_code
        http_code=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -d "$json_payload" "$TEAMS_WEBHOOK_URL")
        if [[ "$http_code" =~ ^2 ]]; then echo -e "  ✅ ${GREEN}Notification sent.${NC}${CLR_LINE}"; else echo -e "  ❌ ${RED}Failed (HTTP $http_code).${NC}${CLR_LINE}"; fi
    else
        echo -e "\n  ✅ ${GREEN}No failures found in this cycle.${NC}${CLR_LINE}"
    fi
    > "$SESSION_ERROR_LOG"
}

# --- 4. Main Loop ---
load_config
clear

while true; do
    rotate_log_if_needed
    
    if ! check_internet_connection; then
        reset_cursor; draw_banner
        echo -e "\n  ❌ ${RED}${BOLD}CRITICAL ERROR: NO INTERNET CONNECTION${NC}${CLR_LINE}"
        echo -e "  🔄  Will retry in 10 seconds...${CLR_LINE}"
        clear_rest_of_screen; sleep 10; continue
    fi

    ((SCAN_ITERATION++))
    load_config
    
    COUNT_TOTAL=$(grep -cve '^\s*$' "$DOMAIN_LIST_PATH")
    COUNT_CURRENT=0
    CLEAN_SERVERS=$(echo "$SOURCE_SERVERS" | tr ',' ' ')

    while IFS= read -r domain || [ -n "$domain" ]; do
        domain=$(echo "$domain" | tr -d '\r')
        [[ -z "$domain" ]] && continue
        [[ "$domain" =~ ^#.*$ ]] && continue
        ((COUNT_CURRENT++))

        reset_cursor
        draw_banner
        draw_progress_bar $COUNT_CURRENT $COUNT_TOTAL
        
        echo -e "  🔎 ${BOLD}TARGET DOMAIN:${NC} ${CYAN}$domain${NC}${CLR_LINE}"
        echo -e "  ${BLUE}--------------------------------------------------${NC}${CLR_LINE}"

        for server in $CLEAN_SERVERS; do
            start_time=$(date +%s%N)
            
            lookup_result=$(nslookup -timeout=2 "$domain" "$server" 2>&1)
            
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            
            if [ "$duration" -lt 300 ]; then lat_color=$GREEN
            elif [ "$duration" -lt 1000 ]; then lat_color=$YELLOW
            else lat_color=$RED; fi
            
            # [SMART PARSING V16]
            if [[ "$lookup_result" == *"NXDOMAIN"* ]]; then
                echo -e "  ❌ $server : ${RED}NXDOMAIN${NC} (${lat_color}${duration}ms${NC})${CLR_LINE}"
                log_failure "$domain" "$server" "NXDOMAIN"
                continue
            elif [[ "$lookup_result" == *"SERVFAIL"* ]]; then
                echo -e "  ❌ $server : ${RED}SERVFAIL${NC} (${lat_color}${duration}ms${NC})${CLR_LINE}"
                log_failure "$domain" "$server" "SERVFAIL"
                continue
            elif [[ "$lookup_result" == *"timed out"* ]]; then
                echo -e "  ❌ $server : ${RED}TIMEOUT${NC} (${lat_color}${duration}ms${NC})${CLR_LINE}"
                log_failure "$domain" "$server" "TIMEOUT"
                continue
            fi
            
            extracted_ips=$(echo "$lookup_result" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
            target_ip=$(echo "$extracted_ips" | grep -v "$server" | head -n 1)

            if [[ -n "$target_ip" ]]; then
                 echo -e "  ✔️ $server : ${GREEN}$target_ip${NC} (${lat_color}${duration}ms${NC})${CLR_LINE}"
            else
                 echo -e "  ❌ $server : ${RED}No Answer / Refused${NC} (${lat_color}${duration}ms${NC})${CLR_LINE}"
                 log_failure "$domain" "$server" "No Answer / Parsing Failed"
            fi
        done
        clear_rest_of_screen
        sleep "$PER_DOMAIN_DELAY"
    done < "$DOMAIN_LIST_PATH"

    send_teams_notification
    
    seconds=$SCAN_INTERVAL
    echo -e "\n  ${BLUE}──────────────────────────────────────────────────────────────────${NC}${CLR_LINE}"
    echo -e "  💤 ${BOLD}CYCLE COMPLETED.${NC} Standby for next scan...${CLR_LINE}"
    while [ $seconds -gt 0 ]; do
        echo -ne "     Resuming in: ${YELLOW}${seconds}s${NC}   \r"
        sleep 1
        : $((seconds--))
    done
done
