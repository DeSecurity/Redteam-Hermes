# Walkthrough Quality Gate (Repeatable)

Use this checklist before publishing any machine walkthrough.

## Teaching flow
- [ ] Starts with full port discovery (`nmap -p-`) before targeted service enumeration.
- [ ] Shows the narrowed service/version scan only after full-port results.
- [ ] Includes web validation commands (`curl`/browser) for discovered web ports.
- [ ] Explains exploit-selection reasoning (why this path, why now).
- [ ] Uses exploit research order: searchsploit/manual PoC first, Metasploit second, then Google/GitHub PoC search if needed.
- [ ] If Metasploit is used, documents why framework use was chosen over manual PoC for that step.

## Reproducibility
- [ ] Includes exact commands and at least one real output snippet per milestone.
- [ ] Includes foothold proof (`session opened` + `sessions -l` or equivalent).
- [ ] Includes post-ex baseline (`getuid/sysinfo/whoami` or equivalent).
- [ ] Includes privesc branch logic (not a single blind loop).
- [ ] Includes final user + root/system proof commands and outputs.

## Narrative quality
- [ ] No repeated tunnel/listener/worker churn in public narrative.
- [ ] No blocker/retry spam unless it changed decisions.
- [ ] 2-3 useful snapshots minimum.
- [ ] Timeline contains meaningful UTC milestones only.

## Publishing quality
- [ ] Entry is clickable from the platform index page.
- [ ] Entry is present in `mkdocs.yml` nav.
- [ ] Changes pushed to remote before declaring update complete.
