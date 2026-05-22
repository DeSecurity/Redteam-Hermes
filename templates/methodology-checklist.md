# Methodology Checklist

## 1) Recon
- [ ] Host reachability
- [ ] Fast port discovery
- [ ] Service/version detection
- [ ] TLS/HTTP tech fingerprinting

## 2) Enumeration
- [ ] Web content discovery
- [ ] Vhost/subdomain checks
- [ ] SMB/LDAP/RPC as applicable
- [ ] Credential and secret exposure checks

## 3) Exploitation
- [ ] Validate exploit path against evidence
- [ ] Use minimal reliable payloads
- [ ] Document impact and constraints

## 4) Privilege Escalation
- [ ] sudo / SUID / capabilities
- [ ] cron / PATH hijack / writable services
- [ ] credential reuse / keys / history
- [ ] container/group escape paths

## 5) Documentation
- [ ] Timestamped timeline updates
- [ ] Commands + rationale
- [ ] Screenshots and proof
- [ ] Lessons + mitigation notes
