# Exposure raises an alarm and queues rotation

Refining ADR-0018's four-property contract into two bundles — **ceremony** (explicit request, fresh presence proof, logged event; the human-facing protocol steps, in Ellison's ceremony sense) and **hygiene** (decryption only after the presence proof, short-lived plaintext erased after use, conveyance only through a permitted path) — creates a clean taxonomy for plaintext events: a **disclosure** satisfies both bundles; an **export** lacks a bounded plaintext lifetime by design (file, printout, unmanaged clipboard) and is forbidden for T2/T3; an **exposure** is a runtime failure — the ceremony ran but hygiene broke (crash before erasure, clipboard captured, window outlived its TTL). The rule this ADR adds: **every exposure emits an alarm event and automatically queues an out-of-cycle rotation of the affected credential.** Rotation is the antidote to the system's own failure modes; a leak that is rotated away within hours has the lifetime the whole project exists to enforce.

## Consequences

- The event schema gains `exposure` and (policy-violation) `export` event types alongside disclosure events; the kraken alarms on both.
- CONTEXT.md's disclosure vocabulary adopts ISO-27002-style entries: terse authoritative definition plus verbose guidance with examples, so the precise language stays accessible to general IT-security readers.
