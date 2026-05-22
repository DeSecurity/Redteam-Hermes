# THM - Steel Mountain (Example Walkthrough)

## Scope
Platform: TryHackMe
Target: Example IP placeholder (`10.10.10.10`)
Authorization: Lab environment only

## Status
Current Phase: Completed example timeline

## Timeline

### 10:00
Action:
- Host discovery and baseline scan

Findings:
- Host up
- HTTP and SMB exposed

Notes:
- Starting web + SMB parallel enumeration

Commands:
```bash
nmap -Pn -sC -sV -oN logs/steel-mountain/nmap-initial.txt 10.10.10.10
```

### 10:14
Action:
- Web content discovery

Findings:
- `/admin` reachable
- Version banner disclosed legacy software

Notes:
- Potential auth weakness and known-vuln angle

Commands:
```bash
ffuf -u http://10.10.10.10/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200,301,302,403 -o logs/steel-mountain/ffuf.json
whatweb http://10.10.10.10 | tee logs/steel-mountain/whatweb.txt
```

### 10:31
Action:
- Initial access validation

Findings:
- RCE path confirmed via vulnerable web component
- User shell obtained

Notes:
- Minimal payload used to reduce crash/noise risk

Commands:
```bash
# Example placeholder command sequence
# exploit-tool --target 10.10.10.10 --check
# exploit-tool --target 10.10.10.10 --payload reverse_shell
```

### 10:52
Action:
- Privilege escalation enumeration

Findings:
- Misconfigured service executable writable by low-priv user
- Service restart produced SYSTEM shell

Notes:
- Privilege separation implemented as a suggestion, not a boundary.

Commands:
```bash
whoami /priv
sc qc <service-name>
icacls "C:\Path\To\Service\binary.exe"
```

## Recon
- Confirmed reachable host
- Scoped port and version identification

## Enumeration
- Web path discovery + tech fingerprinting
- Service-specific validation for exploitability

## Initial Access
- Confirmed vulnerable component path
- Achieved low-priv shell

## Privilege Escalation
- Identified writable service path
- Escalated to SYSTEM

## Loot
- user.txt (recorded locally, not published)
- root/system proof (recorded locally, not published)

## Lessons Learned
- Early version fingerprinting reduced exploit search time
- Logged outputs made path revalidation straightforward

## Mitigations
- Patch vulnerable web component
- Remove write access from service paths
- Harden service permissions and restart controls

## Final Thoughts
This example shows the intended structure and tone for future machine posts: concise, timestamped, reproducible, and evidence-driven.
