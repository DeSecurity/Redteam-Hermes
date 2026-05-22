# Web Exploitation Methodology (for foothold)

Use this when web services are part of the initial access path.

## Phase 1: Fingerprint and map
1. Identify stack and versions
- server banners, framework hints, JS assets, headers

2. Enumerate content and endpoints
- directories, parameters, API paths, virtual hosts/subdomains

3. Map trust boundaries
- authenticated vs unauthenticated areas
- upload, file-read, template/render, admin surfaces

Decision output:
- List concrete weakness hypotheses tied to observed behavior.

## Phase 2: Validate vulnerabilities safely
1. Reproduce with minimal payloads first.
2. Confirm exploit preconditions (version/config/auth state).
3. Promote hypothesis -> confirmed finding only after deterministic reproduction.

## Phase 3: Weaponize to shell/access
1. Select path with best reliability and least guesswork.
2. Keep payload strategy simple and compatible with target stack.
3. Verify callback path and egress assumptions before repeated attempts.

## Phase 4: Post-exploit handoff
- Stabilize shell/session.
- Capture host/user identity proof.
- Transition to OS-level privesc methodology.

## Common pitfalls to avoid
- Treating scanner output as proof without manual verification.
- Running exploit chains before confirming vulnerable code path.
- Dense raw output dumps without stating why they matter.

## Walkthrough quality standard
For web-led boxes, include these snapshots:
1. Surface map snapshot (stack + key endpoints)
2. Exploit trigger snapshot (proof of vulnerability)
3. Post-exploit snapshot (shell/session identity)
