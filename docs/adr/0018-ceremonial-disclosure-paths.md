# Ceremonial disclosure paths for T2/T3

ADR-0014's consequences overstated that T2/T3 are "never fillable plaintext": admin web UIs (Proxmox, firewalls, IPMI, cloud consoles, registrars) are precisely the T2/T3 population, and they authenticate through password fields — at use time, plaintext must materialize. The corrected invariant: **T2/T3 plaintext materializes only through ceremonial disclosure paths** — explicit intent naming the credential, fresh hardware presence proof, transient materialization with zeroization, attested event — and is never persisted outside the envelope, never replicated. The path hierarchy: **T3** — managed session only (the engine logs into its isolated browser profile via a stored recipe and hands over the authenticated window; ssh-agent with confirm-per-use for keys); root secrets and break-glass accounts disclose only via break-glass disclosure, which always raises an alarm event. **T2** — managed session preferred; hardened clipboard and environment injection as v1 fallbacks; extension fill and auto-type in v1.1+. Complement, not path: password-displacing auth (WebAuthn/security keys, SSO reverse-proxy) is pursued opportunistically so high-tier passwords decay into rarely-disclosed fallbacks (ADR-0017 applied to infrastructure). The normative rendering is the V6 tier policy matrix in `docs/model/views.md`.

## Considered Options

- **Extension fill as primary T2**: best UX continuity, but plaintext and the session cookie land in the daily browser's extension attack surface, and a per-item native-messaging host joins the v1 critical path.
- **Managed session only, T2 included**: purest, but sites without a login recipe become unusable and CLI-consumed secrets (PATs) get no path at all.
- **All paths at all tiers, per-entry choice**: flexibility without invariant — tier stops constraining transit, which was its purpose.

## Consequences

- ADR-0014's "structurally cannot leak" consequence is narrowed to storage and replication; use-time transit is governed here.
- Managed session reuses the ADR-0008 profile and the login recipes rotation enrollment needs anyway — the launch-pad (v2) mechanism arrives early as a disclosure path.
- New domain terms enter CONTEXT.md: disclosure path, managed session, hardened clipboard, environment injection, root secret, break-glass account, break-glass disclosure.
