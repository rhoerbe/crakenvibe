# Credential assurance tiers (T1/T2/T3)

CRAKEN defends two distinct attack scenarios that need different mechanics: leaked long-standing copies (answered by comprehensive rotation) and in-session memory scraping (answered by per-use disclosure). Credentials therefore carry an assurance tier that determines storage form, disclosure ceremony, and replica policy. **T1 standard**: plain KDBX entry; ecosystem autofill; replicas in login-unlocked OS stores allowed where APIs exist — tolerable because rotation time-bounds any copy exfiltrated from them. **T2 high**: per-item envelope encryption to a YubiKey PIV key with touch policy; plaintext exists in memory only transiently, one touch per disclosure; no replicas, no silent autofill. **T3 privileged**: credentials that can control other credentials or accounts (engine admin keys; email, IdP, registrar); same envelope, stricter policy — used only inside engine sessions, never displayed, exported, or replicated. Cost accepted deliberately: T2/T3 entries are opaque to plain KeePassXC, because silent autofill *is* the threat at those tiers.

## Considered Options

- **Per-tier vault files** (second KDBX for T2 with YubiKey challenge-response): fully ecosystem-readable, but unlocking the file decrypts all T2 secrets at once — "unlock on request" degrades to whole-file granularity.
- **Tiers as policy metadata only**: no storage or ceremony difference; fails the memory-scraping requirement outright.
- **Envelope-wrap everything**: kills T1 ecosystem autofill, violating the equal-convenience requirement for everyday credentials.

## Consequences

- T2/T3 secrets are never stored in or replicated to OS/browser stores — the browser *storage* problem collapses to T1 (ADR-0015). Use-time transit of T2/T3 plaintext does exist and is governed by the ceremonial disclosure paths of ADR-0018.
- Honest limit, documented: rotation does not protect the *current* secret from live in-session malware; for T2/T3 the per-item envelope narrows exposure to per-use windows.
- The presence gate of ADR-0003 is the T3 ceremony; tiers generalize it.
