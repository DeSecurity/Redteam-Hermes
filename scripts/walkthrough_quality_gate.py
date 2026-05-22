#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("Usage: walkthrough_quality_gate.py <walkthrough.md>")
    sys.exit(2)

p = Path(sys.argv[1])
if not p.exists():
    print(f"ERROR: file not found: {p}")
    sys.exit(2)

text = p.read_text(encoding="utf-8", errors="ignore")
low = text.lower()

checks = {
    "full_port_scan_first": bool(re.search(r"nmap[^\n]*-p-", low)),
    "targeted_service_scan": bool(re.search(r"nmap[^\n]*-s[vVcC]|nmap[^\n]*-p\d", low)),
    "web_validation": ("curl" in low) or ("http" in low and "browser" in low),
    "searchsploit_or_manual_first": ("searchsploit" in low) or ("manual poc" in low) or ("manual exploit" in low),
    "metasploit_documented_if_used": (("metasploit" not in low) and ("msfconsole" not in low)) or ("search " in low and "info exploit" in low),
    "google_github_poc_fallback_noted": ("github" in low) or ("google" in low) or ("poc" in low),
    "foothold_proof": ("meterpreter session" in low) and ("sessions -l" in low),
    "post_ex_baseline": ("getuid" in low) and ("sysinfo" in low),
    "privesc_branches": ("token" in low and "service" in low and "credential" in low) or ("branch" in low and "privesc" in low),
    "proof_paths": ("user.txt" in low) and (("root.txt" in low) or ("administrator" in low and "desktop" in low)),
    "no_tunnel_churn_spam": low.count("tunnel") <= 3,
}

print(f"Quality gate report: {p}")
failed = 0
for k, ok in checks.items():
    print(f"- {k}: {'PASS' if ok else 'FAIL'}")
    if not ok:
        failed += 1

if failed:
    print(f"\nResult: FAIL ({failed} checks failed)")
    sys.exit(1)

print("\nResult: PASS")
sys.exit(0)
