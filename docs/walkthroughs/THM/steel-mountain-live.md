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

### 2026-05-22 21:42:48Z — VPN connected successfully
Commands:
```bash
sudo openvpn --config /home/kali/Downloads/us-west-2-DeSecurity-premium.ovpn
```
Result:
- OpenVPN reached `Initialization Sequence Completed`
- `tun0` interface assigned: `192.168.129.182/17`

### 2026-05-22 21:46:27Z — Full TCP port discovery
Command:
```bash
nmap -Pn -n -p- --min-rate 1500 --max-retries 2 10.146.141.173
```
Result:
- Open ports: `80,135,139,445,3389,5985,8080,47001,49152-49156,49188,49190`

### 2026-05-22 21:46:44Z — Service/version enumeration
Command:
```bash
nmap -Pn -n -sC -sV -p80,135,139,445,3389,5985,8080,47001 10.146.141.173
```
Key findings:
- `80/tcp`: Microsoft IIS 8.5 (TRACE enabled)
- `8080/tcp`: HttpFileServer `HFS 2.3` (title: `HFS /`)
- `445/tcp`: SMB (signing enabled but not required)
- `3389/tcp`: RDP, hostname indicates `STEELMOUNTAIN`
- `5985` and `47001`: WinRM/HTTPAPI endpoints

### 2026-05-22 21:47:00Z — Web validation + exploit surface triage
Commands:
```bash
curl -sI http://10.146.141.173:8080
curl -s http://10.146.141.173:8080
searchsploit -w "Rejetto HFS 2.3"
```
Result:
- Server header confirms `HFS 2.3`
- `searchsploit` returns multiple public RCE entries for Rejetto HFS 2.3

### 2026-05-22 21:47:30Z — SMB and IIS follow-up
Commands:
```bash
nmap -Pn -n --script smb-enum-shares,smb-enum-users -p445 10.146.141.173
smbclient -L //10.146.141.173 -N
curl -s http://10.146.141.173 | iconv -f utf-16le -t utf-8
nmap -Pn -n --script smb-protocols,smb2-security-mode,smb-security-mode -p445 10.146.141.173
```
Result:
- Anonymous SMB listing denied: `NT_STATUS_ACCESS_DENIED`
- SMBv1 is enabled; signing not required (useful for later relay-style considerations in real ops)
- IIS homepage decoded from UTF-16LE reveals `Employee of the month` image: `BillHarper.png`

Assessment:
- Primary attack path remains Rejetto HFS 2.3 RCE (8080).
- Web clue captured (`BillHarper`) for potential credential/user correlation.
- SMB currently gives no anonymous foothold.

## Next Actions
1. Perform controlled HFS 2.3 RCE validation against 8080.
2. If execution succeeds, establish stable shell and collect host/user context.
3. Enumerate local privilege escalation paths and continue timeline logging.
4. Continue updating this live blog after each meaningful step.

### 2026-05-22 21:57:29Z — Session re-validation after site/theme work
Commands:
```bash
sudo openvpn --config /home/kali/Downloads/us-west-2-DeSecurity-premium.ovpn
nmap -Pn -n -p8080 --script http-title,http-server-header 10.146.141.173
ping -c 2 -W 1 10.146.141.173
nmap -Pn -n -F 10.146.141.173
```
Result:
- VPN connected again (`Initialization Sequence Completed`)
- Target now appears transient/unavailable from this path:
  - `8080/tcp filtered`
  - Top-100 ports all filtered/no-response

Assessment:
- Earlier enumeration confirmed Steel Mountain services and HFS 2.3 attack path.
- False negative was caused by unstable operator state (duplicate OpenVPN sessions/tunnels and transient filtering during check window).
- Corrective action: verify with both browser and terminal before declaring target down; keep a single stable VPN session.

### 2026-05-22 21:59:40Z — Recovery validation
Commands:
```bash
curl -sI http://10.146.141.173:8080
nmap -Pn -n -p80,8080 -sV 10.146.141.173
```
Result:
- `8080/tcp` reachable again and serves `HFS 2.3`
- `80/tcp` reachable and serves `IIS 8.5`

Updated assessment:
- Target is up and exploitable path remains intact.
- Next step: execute controlled HFS 2.3 RCE validation and land initial shell.
