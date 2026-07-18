# No unattended rotation in v1

Presence-gating (ADR-0003) conflicts with cron-style rotation — a 3 a.m. job can't touch a YubiKey. But the agentic web connector hits 2FA prompts mid-flow anyway, so v1 is semi-attended by nature, and the SOHO persona's pain is "rotation never happens", not "rotation must happen at 3 a.m.". V1 is therefore presence-gated only: the engine pre-plans queued batches and one hardware touch executes the whole batch. This deletes the long-lived-operator-key attack surface from v1 entirely.

## Consequences

- The event schema carries an `attestation` field from day one, so unattended mode (TPM- or software-bound operator key, weaker attestation recorded per event) can arrive in v1.1+ as an additive change, not a breaking one.
