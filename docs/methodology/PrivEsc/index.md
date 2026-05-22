# Privilege Escalation Methodology

Goal: move from initial user context to root/SYSTEM using evidence-driven, reproducible checks.

## Universal sequence
1. Confirm current boundary
- user, groups, token/privileges, host role

2. Enumerate privesc classes
- misconfigurations
- weak permissions
- credential material
- unsafe automation/scheduled execution

3. Rank by reliability
- deterministic > fragile/racy
- low-noise > high-noise

4. Execute one path at a time
- verify result before moving on

5. Prove final boundary
- root/SYSTEM identity confirmation
- proof artifact capture

## Linux checklist
- `id`, `uname -a`, distro/version context
- `sudo -l`
- SUID binaries and GTFOBins mapping
- file capabilities
- cron/systemd timers and writable scripts
- writable service paths and dangerous permissions
- credential material in configs/history/env

## Windows checklist
- `whoami /priv`, `whoami /groups`
- local admin membership and token usability
- vulnerable/misconfigured services
- scheduled tasks (author/run-as/permissions)
- writable binaries/scripts in privileged execution paths
- saved credentials/config secrets
- WinRM/RDP credential reuse opportunities

## Decision logging format (required)
For each attempted privesc path, log:
- Why it was selected
- Command(s) executed
- Result (success/fail)
- Next decision

## Snapshot standard
Every completed box should show:
1. Initial user-context snapshot
2. Escalation-path proof snapshot
3. root/SYSTEM confirmation snapshot
