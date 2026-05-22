# Steel Mountain (THM) — Live Blog

Status: In Progress
Target IP: 10.146.141.173
Last Reset (UTC): 2026-05-22 22:05:22Z
Scope: Authorized lab target (TryHackMe)

## Operator Standard (what gets logged)
Only material progress is recorded:
- Confirmed attack surface and decision points
- Successful/failed exploitation attempts with evidence
- Shell/privilege milestones
- Key obstacles and how they were solved
- Flags, proof, and reproducible commands

Noise (VPN hiccups, transient retries, tooling friction) is excluded unless it directly changes the attack path.

## Recon Baseline (useful findings only)
Confirmed externally reachable services:
- 80/tcp: Microsoft IIS 8.5
- 8080/tcp: Rejetto HttpFileServer 2.3
- 445/tcp: SMB (anonymous listing denied)
- 3389/tcp: RDP
- 5985/tcp + 47001/tcp: WinRM / HTTPAPI

High-value lead:
- HFS 2.3 on 8080 is the primary initial access candidate.

## Current Plan
1) Gain initial shell via controlled HFS 2.3 RCE path.
2) Stabilize shell and collect host/user context.
3) Enumerate local privilege escalation vectors.
4) Obtain Administrator/root equivalent proof and flags.

## Progress Timeline

### 2026-05-22 22:05:22Z — Blog quality reset
- Pruned low-value operational noise.
- Preserved only actionable recon baseline and attack plan.
- Continuing with exploitation-focused updates from this point onward.
