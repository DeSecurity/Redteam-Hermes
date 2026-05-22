# Steel Mountain (THM) — Live Blog

Status: In Progress
Target IP: 10.146.141.173
Start Time (UTC): 2026-05-22 21:41:26Z
Scope: Authorized lab target (TryHackMe)

## Engagement Notes
- This is a live operational log updated as actions are performed.
- No walkthrough spoilers beyond what we actively verify during this engagement.

## Timeline (UTC)

### 2026-05-22 21:38:00Z — Task kickoff
- Received target: `10.146.141.173`
- Operator note: VPN config downloaded to `~/Downloads`

### 2026-05-22 21:39:00Z — VPN profile identified
Command:
```bash
find ~/Downloads -name "*.ovpn"
```
Result:
- `/home/kali/Downloads/us-west-2-DeSecurity-premium.ovpn`

### 2026-05-22 21:40:00Z — VPN connection attempt (agent side)
Command:
```bash
sudo openvpn --config /home/kali/Downloads/us-west-2-DeSecurity-premium.ovpn
```
Result:
- Failed in non-interactive context due sudo password prompt:
  - `sudo: a terminal is required to read the password`
  - `sudo: a password is required`

Impact:
- Agent cannot elevate to root in this session without interactive sudo auth.

### 2026-05-22 21:41:00Z — Network baseline check
Command:
```bash
ip -br a
```
Result:
- No `tun0`/VPN interface visible from agent context.

### 2026-05-22 21:41:00Z — Initial target probe
Commands:
```bash
ping -c 2 -W 2 10.146.141.173
nmap -Pn -n --min-rate 2000 --max-retries 1 -F 10.146.141.173
```
Result:
- `ping`: 100% packet loss
- `nmap`: host reported up; all top-100 TCP ports filtered (no-response)

Assessment:
- Current signal is consistent with either:
  1) VPN not active in this execution context, or
  2) transient THM machine/network filtering during startup.

## Next Actions
1. Bring THM VPN up with privileged local shell.
2. Re-run full TCP discovery:
   - `nmap -sC -sV -p- --min-rate 1000 10.146.141.173`
3. Start web/service enumeration based on discovered ports.
4. Continue updating this live blog after each meaningful step.
