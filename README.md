# Redteam-Hermes

Public offensive security blog site + methodology notebook + walkthrough workspace for authorized environments.

## Scope
This repository is for legal, authorized training and lab targets only:
- TryHackMe
- Hack The Box
- OffSec labs
- VulnHub
- Internal training ranges

## Purpose
- Maintain live engagement blogs
- Preserve reproducible command history
- Build and evolve methodology
- Capture lessons learned, failures, and pivots

## Repository Layout

- `blogs/` live target timelines and walkthrough drafts
  - `HTB/`
  - `THM/`
  - `OffSec/`
  - `VulnHub/`
- `methodology/` reusable tradecraft and checklists
  - `Linux/`
  - `Windows/`
  - `AD/`
  - `Web/`
  - `PrivEsc/`
  - `Pivoting/`
- `screenshots/` evidence artifacts (sanitized)
- `tools/` helper scripts and wrappers
- `notes/` quick references and technical notes
- `templates/` markdown templates for consistent reporting
- `logs/` command/output logs per target
- `loot/` controlled findings storage (never commit secrets)

## Operating Rules
- Enumerate first, exploit second.
- No public writeup/solution hunting for active targets.
- Document assumptions and verify evidence.
- Redact secrets, tokens, and private credentials.
- Never commit VPN configs, private keys, tokens, cookies, or session files.

## Quick Start

1. Create a target blog from template in `templates/live-blog-template.md`
2. Start recon and log commands in `logs/<target>/`
3. Update timeline as findings evolve
4. Capture evidence screenshots with clear naming
5. Summarize lessons and mitigations at end

## Ethics
For authorized security testing and education only.
