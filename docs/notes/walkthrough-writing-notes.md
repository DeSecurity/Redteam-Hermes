# Walkthrough readability notes (from strong cyber writeup patterns)

Sources reviewed:
- https://0xdf.gitlab.io/2023/09/30/htb-format.html
- https://desecurity.github.io/Redteam-Hermes/walkthroughs/THM/steel-mountain-live/

## What good writeups do well
1. Start with a short "what happened" summary
- Readers get outcome and attack chain in 30 seconds.
- Avoids forcing people to parse long timelines first.

2. Keep a clear phase flow
- Recon -> Exploitation -> PrivEsc -> Proof -> Lessons.
- Each phase has only the commands/findings that changed decisions.

3. Convert raw output into decision statements
- Not just "nmap output"; also "why this output matters".
- Example: "HFS 2.3 present -> primary RCE candidate".

4. Use checkpoint snapshots
- 2-3 key milestones per walkthrough.
- Typical snapshot set:
  - service discovery / initial lead
  - foothold proof
  - privilege change or blocker + remediation

5. Separate facts from blockers
- Facts: confirmed service, confirmed shell, confirmed user context.
- Blockers: route instability, failed payload, auth failure.
- Blockers should include immediate corrective action.

6. Prefer compact bullets over dense paragraphs
- One idea per bullet.
- Keep lines short enough to scan quickly on mobile.

## Style rules to enforce in this repo
- Keep a "Quick status" section near the top.
- Keep "Next actions" explicit and short.
- Log only meaningful milestones (no operator noise).
- Ensure each walkthrough has at least 2-3 snapshots.
- Use UTC timestamps for reproducibility.
