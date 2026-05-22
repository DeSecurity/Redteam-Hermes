# Windows Methodology (0 -> SYSTEM)

Use this for standalone Windows lab hosts (THM/HTB/OSCP-style).

## Phase 1: Confirm attack surface
1. Host/service baseline
- `nmap -Pn -n -sV -sC -p- <TARGET>`
- If speed needed: start with top ports, then expand.

2. Service focus by port
- 80/443/8080: web stack, version, auth, upload/input points
- 445: SMB shares, null/guest behavior, file exposure
- 3389: RDP access surface and credential requirement
- 5985/5986: WinRM authentication path

Decision output:
- Produce top 1-3 initial foothold candidates with evidence.

## Phase 2: Initial foothold
1. Start with the highest-confidence candidate.
2. Prefer reliable payloads first, then rotate if blocked.
3. On session open, run immediate proof:
- `whoami`
- `hostname`
- `systeminfo` (or equivalent)
- privilege context (`whoami /priv`)

If foothold fails:
- Rotate one variable at a time: payload OR callback port OR transport.
- Keep notes on what failed and why.

## Phase 3: Post-foothold local enumeration
Prioritize:
1. Identity and local groups
- `whoami /groups`
- `net user <user>`
- `net localgroup administrators`

2. Credentials and secrets
- config files, scripts, service arguments, saved creds
- plaintext in app/web config locations

3. Service/task abuse paths
- unquoted service paths
- weak service permissions
- writable binaries/scripts run by higher-priv context
- scheduled task misconfigurations

4. Defensive context
- AV/EDR constraints
- PowerShell policy and execution constraints

## Phase 4: Privilege escalation to SYSTEM
1. Rank opportunities by reliability and noise.
2. Execute lowest-risk high-confidence path first.
3. Validate boundary change:
- `whoami` should show `nt authority\system` (or equivalent admin boundary)

4. Capture proof cleanly
- user proof + SYSTEM/root-equivalent proof
- timestamped commands used to obtain each

## Failure handling rules
- No blind reruns; update hypothesis each retry.
- If route/tunnel instability exists, pause exploitation and fix network state first.
- Never assume service down from a single tool result.

## Deliverable standard (for walkthroughs)
Each Windows walkthrough should include at least 3 snapshots:
1. Recon proof (services + lead)
2. Foothold proof (session/identity)
3. SYSTEM proof (boundary change + final evidence)
