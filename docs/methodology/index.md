# Methodology Overview

This section is the reusable playbook layer for authorized labs.
Goal: a reader should be able to follow this from target IP to user shell to SYSTEM/root with minimal guesswork.

## Operator rules
- Evidence before action: confirm service/version/path before exploit selection.
- One change at a time: if a path fails, rotate one variable (payload, port, transport), not everything.
- Keep a clean timeline: UTC timestamps, command, result, decision.
- Record blockers with fixes (not just failures).
- Never assume target is down from one probe; verify with dual checks.

## 0 -> root/system master flow
1) Pre-flight
- Verify VPN state and routes.
- Confirm exactly one active lab tunnel interface.
- Validate target reachability with two probes (HTTP-style + terminal scan).

2) Surface mapping
- Run scoped service discovery.
- Fingerprint web/server software and auth boundaries.
- Build a short candidate list ranked by reliability.

3) Initial access
- Pick the highest-confidence path first.
- Use stable payloads and rotate payload/port only when evidence says so.
- Verify shell quality and identity immediately (`whoami`, host info, privileges).

4) Local enumeration
- Run host-specific enumeration (Windows/Linux/AD).
- Identify privilege boundaries, credential material, and execution opportunities.

5) Privilege escalation
- Execute the highest-probability privesc path first.
- Confirm boundary change with proof commands.
- Capture user/root or equivalent proof artifacts.

6) Closeout
- Document attack chain, key decisions, failed-but-useful paths, and hardening notes.
- Promote repeatable improvements into methodology pages.

## From Steel Mountain (lessons applied)
- Duplicate VPN tunnel state can create false filtered/down reads.
  - Rule: block exploitation when more than one `tun*` is active.
- Exploit modules can reject certain payloads.
  - Rule: add compatibility-aware payload rotation instead of one-shot failure.
- Session commands must be gated on session existence.
  - Rule: never run session commands against invalid IDs.

## Quick links
- [Windows playbook](Windows/)
- [Web playbook](Web/)
- [Privilege escalation playbook](PrivEsc/)
- [Linux playbook](Linux/)
- [Active Directory playbook](AD/)
- [Pivoting playbook](Pivoting/)