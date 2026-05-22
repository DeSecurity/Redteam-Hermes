# Steel Mountain (THM) — Live Walkthrough

Status: In Progress
Target: 10.146.141.173
Scope: Authorized TryHackMe lab target
Last reset (UTC): 2026-05-22 22:05:22Z

## Quick status
- Initial access path confirmed: Rejetto HFS 2.3 on port 8080.
- One valid Meterpreter foothold was obtained.
- Progress is currently paused when duplicate VPN tunnels are detected (safety rule to prevent false network conclusions).

## Attack path (human-readable)
1. Enumerate exposed services.
2. Validate HFS 2.3 as primary initial-access vector.
3. Run controlled exploit attempts with payload/port rotation.
4. On session open, stabilize shell and start privesc enumeration.

## Recon baseline
Confirmed externally reachable services:
- 80/tcp: Microsoft IIS 8.5
- 8080/tcp: Rejetto HttpFileServer 2.3
- 445/tcp: SMB (anonymous listing denied)
- 3389/tcp: RDP
- 5985/tcp, 47001/tcp: WinRM / HTTPAPI

Primary lead:
- HFS 2.3 on 8080 is the best initial foothold candidate.

## Snapshots (useful checkpoints)
### Snapshot 1 — Service discovery
Time (UTC): 2026-05-22 22:04:45Z
- 8080 identified as HFS 2.3.
- Attack path prioritized to HFS RCE.

### Snapshot 2 — Foothold proof
Time (UTC): 2026-05-22 22:24:24Z
- Meterpreter session opened via `exploit/windows/http/rejetto_hfs_exec`.
- Session context observed as `STEELMOUNTAIN\\bill @ STEELMOUNTAIN`.

### Snapshot 3 — Operational blocker + guardrail
Time (UTC): 2026-05-22 22:26:22Z
- Duplicate active tunnels detected (`tun0` and `tun1`).
- Worker now auto-pauses on duplicate tunnels to avoid false filtered/down reads.
- Worker auto-resumes once a single tunnel remains.

## Timeline (condensed)
### 2026-05-22 22:07:28Z — First autonomous pass
- Started focused HFS exploitation cycle.

### 2026-05-22 22:07:51Z — No foothold yet
- No stable session from first pass.
- Added payload/port rotation for retries.

### 2026-05-22 22:22:19Z — Continuous worker mode enabled
- Worker switched from one-shot to persistent supervisor loop.
- Added self-healing retries and compatibility handling.

### 2026-05-22 22:24:24Z — Foothold achieved
- Meterpreter session opened successfully.

### 2026-05-22 22:26:22Z — Duplicate-tunnel blocker detected
- Safety rule triggered; exploit attempts paused until tunnel state is clean.

## Next actions
- Keep exactly one VPN tunnel active.
- Resume post-foothold host enumeration and privilege escalation chain.
- Capture user/root proof and append new snapshots only for meaningful milestones.
