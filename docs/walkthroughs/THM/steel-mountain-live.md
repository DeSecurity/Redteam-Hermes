# Steel Mountain (THM) — Live Blog

Status: In Progress
Target IP: 10.146.141.173
Last Reset (UTC): 2026-05-22 22:05:22Z
Scope: Authorized lab target (TryHackMe)

## Recon Baseline
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

### 2026-05-22 22:07:28Z — Autonomous exploitation pass
- Starting focused foothold attempt on Rejetto HFS 2.3 (8080).

### 2026-05-22 22:07:51Z — Foothold not yet achieved
- Current pass did not open a stable reverse session.
- Next pass should rotate payload/port and retry.
