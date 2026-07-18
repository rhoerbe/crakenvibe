# Hardware trust root gates secret release

A rotation engine is structurally a credential-exfiltration machine with good intentions; what makes it defensible is that possession of the host must not equal ability to operate it. Target/admin credentials are therefore wrapped to a key on a hardware token (YubiKey first, HSM-class later), and a rotation batch requires user presence (touch/PIN) to unwrap — malware on the box cannot silently drain the vault through the engine. Two further anchors come nearly free: vault-at-rest protection is inherited from existing KDBX + YubiKey challenge-response support (zero build), and the audit log is hash-chained with periodic hardware signatures, upgrading it from "log file" to "evidence".

## Consequences

- Presence-gating forces the v1 attended-only model (ADR-0004).
- Connector signing is a *different* trust root (maintainer/registry keys, ADR-0010), not the user's token.
