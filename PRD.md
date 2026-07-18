# CRAKEN — Product Requirements Document

*Groomed 2026-07-18 from the initial PRD in issue #1, via a structured design interview. The original issue text remains the historical seed; this document is canonical.*

**Working name:** CRAKEN — **C**redential **R**otation, **A**udit, **K**ey-management, **E**ntitlements & **N**otifications. (Product naming is open; "crakenvibe" is the repo, not the brand.)

---

## 1. Vision

A key security control is avoiding persistent secrets: shorter lifetimes mean reduced attack surface. SSO (Kerberos, SAML, OIDC) solved this for workforce authentication, but two areas remain uncovered: **password managers** (the long tail of web/SaaS accounts) and **PAM-style privileged credentials** (SSH keys, admin passwords, API tokens). Existing PAM products rotate credentials but through proprietary connectors; password managers have historically failed at automated rotation because every website's change-password flow is different and scripted connectors rot.

CRAKEN's answer:

1. **An open, GitHub-based specification** for credential-rotation connectors and their event stream.
2. **A reference implementation**: a vault-agnostic rotation engine anchored in a hardware cryptographic trust root.
3. **A connector ecosystem** where deterministic code connectors and AI-agent-driven playbooks are peers under one protocol.

The bet that makes rotation newly tractable: LLM browser agents can handle the long tail of web UIs that killed every previous auto-rotation product — if and only if the security architecture keeps secrets out of the model's reach.

## 2. What this project is not

- Not a new password manager. The engine works against the user's existing vault (KDBX first).
- Not an enterprise PAM. Enterprise is served by the spec being adoptable, not by v1 features (no HA, RBAC, multi-tenancy, SIEM).
- Not a machine-identity system. See §8 scope cuts.
- Not an IGA/entitlements product. Entitlements are explicitly out of the v1 spec.

## 3. Persona (v1)

**The technical SOHO admin**: homelab or small-business operator who is both end user and de-facto sysadmin. Runs a KeePass-class vault; administers a NAS, a router, a few Linux boxes; holds developer tokens and dozens of web accounts. Has no PAM budget; today, rotation simply never happens. Adopts open source readily and is the population from which connector contributors come.

Enterprise vendors and MSPs are future audiences addressed through spec adoption, not v1 requirements.

## 4. Architecture decisions

Each decision below was resolved in the design interview; rationale is recorded so it stays decided.

### D1. Agentic AI's role: hybrid, with a hierarchy
Deterministic, spec-driven connectors are the primary path wherever an API/CLI exists. Agentic browser automation is the fallback for web UIs with no API. AI also assists at dev time (generating connectors/playbooks from documentation). Rationale: the long tail is the differentiator, but an LLM touching cleartext credentials is indefensible; the hierarchy keeps the security story clean.

### D2. Vault relationship: standalone, vault-agnostic engine
A separate engine (CLI + daemon) treats the vault as a pluggable backend. Backend #1 is the KDBX file itself via mature libraries; KeePassXC keeps working on the same file, unmodified. Verified constraint: KeePassXC deliberately has no plugin system, so "extend KeePassXC" was never on the menu. The vault-backend interface is spec surface — Bitwarden/pass/Vault users become adopters, not bystanders.

### D3. Trust root: possession ≠ operation
A rotation engine is structurally a credential-exfiltration machine with good intentions. What makes it defensible: compromise of the host must not equal compromise of the credentials. The hardware token (YubiKey first; HSM-class later) anchors:

1. **Secret release**: target/admin credentials are wrapped to the hardware key; a rotation batch requires user presence (touch/PIN) to unwrap.
2. **Vault at rest**: inherited from KDBX + YubiKey challenge-response (existing KeePassXC art; zero build).
3. **Audit-log integrity**: events are hash-chained and periodically anchored with a hardware signature — upgrading the log from "file" to "evidence".

Connector signing uses a different root (maintainer/registry keys) — see D10.

### D4. No unattended mode in v1
V1 is presence-gated only: the engine pre-plans queued batches; one hardware touch executes the batch. Rationale: the agentic web connector hits 2FA prompts mid-flow anyway, so v1 is semi-attended by nature; and deferring unattended mode deletes the long-lived-operator-key attack surface entirely. The event schema carries an `attestation` field from day one so unattended mode (TPM/software operator key) can arrive later without a breaking change.

### D5. Connector model: subprocess + JSON-RPC over stdio
Terraform/LSP pattern: every connector is an executable speaking a versioned JSON-RPC protocol; secrets pass through the pipe, never argv/env. Language-agnostic for contributors; process isolation now, sandboxing (bwrap/systemd) as an upgrade path. The agentic executor and a declarative-HTTP executor are themselves just interpreter-connectors under the same protocol — one mechanism, layered interpreters.

### D6. Rotation is transactional: write-ahead commit protocol
The lockout scenario (new password live on target, vault write lost) is the failure the spec exists to prevent. Mandated sequence: durably persist the pending new secret (vault history/journal) → apply on target → **verify by authenticating with the new secret** → mark active; retain the old secret until verification passes. The connector API is shaped around these phases; token-class credentials (create-verify-revoke) force the two-phase shape anyway.

### D7. LLM boundary: pluggable provider, invariant protections
Model provider is a configurable backend: frontier cloud API by default (agentic reliability), local runtimes (Ollama-class) supported. Invariants hold regardless of provider:

- **Placeholder injection**: the browser-driving tool layer substitutes `{{NEW_SECRET}}` into form fields itself; the model sees placeholders in both directions.
- **Redaction filter**: known secrets are scrubbed from DOM/screenshot payloads before they reach model context.
- **Per-target policy**: sensitive entries can forbid cloud egress or agentic rotation entirely. Privacy posture is per-credential, not global.

### D8. Browser strategy: dedicated persistent rotation profile
The engine owns a browser profile used only for rotations — headful and visible. Enrolling a site = one assisted login (user handles 2FA once); the session persists, so later rotations skip most friction. Real-browser fingerprint beats headless bot detection; full isolation from daily browsing; the user watches every action, which builds the trust a credential tool needs. Fits presence-gated batches: the human is already there for surprise CAPTCHAs.

### D9. Stack: typed Python, reference-grade
Python 3.12+, strict typing (pyright), uv packaging, Playwright, pykeepass, fido2/ykman, pluggable LLM SDKs; distribution via uvx/pipx. Rationale: connectors are language-agnostic by protocol, so engine language is not an ecosystem decision; a reference implementation optimizes for legibility and iteration speed while the spec is wet. A Rust production engine is a legitimate post-stability successor; the spec, not the engine, is the durable artifact.

### D10. Distribution & trust of connectors
V1: first-party connectors live in this monorepo, released as signed artifacts (minisign/ssh-sig). The engine verifies signatures before executing any connector not built from local source. The spec defines the connector **manifest + signature format from day one** so the first third-party connector arrives onto rails — sideloading must not become the culture. A federated index (Terraform-registry-lite) is chartered but built only when the first external connector appears.

### D11. Licensing
- **Spec + protocol schemas: CC-BY 4.0** — vendors implement freely, attribution only.
- **Engine: GPL-3.0** — embracing the pykeepass (GPL-3) constraint as strategy: reference code stays open; proprietary forks can't take it closed.
- **Connectors and vault backends are independent works**: the spec explicitly declares that programs communicating over the documented protocol are not derivative works of the engine — community connectors may use any license.

### D12. Governance
Single maintainer for now; spec changes via RFC-labeled PRs and ADRs; the spec itself is semver'd and tagged v1.0-rc only after all four v1 connectors have validated it. Contributions under DCO (no CLA). A steering group is deferred until multi-vendor interest is real.

## 5. Specification scope (v1)

Two documents:

1. **Connector interface**: target enrollment, rotation lifecycle (create–verify–activate–revoke), health check, rollback, manifest + signature format, credential-type taxonomy (password, keypair, API token; extensible).
2. **Event schema**: mandatory for every connector action. The persisted event stream **is** the audit trail; notification (the kraken that wakes up when something goes wrong) is an event consumer. Events carry an `attestation` field recording what authorized the run.

Out of the v1 spec: entitlements (declared future extension), trust-root key hierarchy (documented in the reference implementation's security architecture instead).

## 6. V1 connector set (the breadth sampler)

Connectors are chosen as spec test vectors — to stress every credential shape and channel once — not by user value:

| Connector | Credential type | Channel | What it proves |
|---|---|---|---|
| SSH keypair rotation on a Linux host | keypair | CLI/SSH | key staging, authorized_keys push |
| Linux account password via SSH | password | CLI/SSH | password over CLI channel |
| GitHub PAT **or** AWS IAM access key (choose at build time) | API token | REST | two-phase create-verify-revoke |
| One web-UI rotation via agentic executor | password | browser | the differentiator, placeholder injection, enrollment UX |

## 7. Post-v1 roadmap

- **Launch pad = connection launcher** (v2): click a vault entry → SSH/RDP/browser session opens with the credential injected, never shown. Reuses the rotation engine's target registry; turns the vault into the admin's daily cockpit — the retention feature that makes rotation ambient.
- **Unattended mode** (v1.1+): TPM/software operator key, weaker attestation recorded per event.
- **X.509/certificate renewal** connector family (SCEP/EST/ACME) — the defensible slice of machine-adjacent territory.
- **Further vault backends**: Bitwarden/Vaultwarden, pass, HashiCorp Vault.
- **Federated connector registry** once the first external connector exists.
- **Sandboxed connector execution** (bwrap/systemd, possibly WASM when WASI matures).

**Parked ideas** (discussed, deliberately not committed): AI-agent credential broker (the vault issues scoped short-lived credentials to AI agents instead of agents holding passwords) as an alternative reading of "launch pad"; Rust production engine; foundation governance.

## 8. Scope cuts (decided, with rationale, so they stay decided)

- **Machine-to-directory identity** (workstation/server auth to AD/EntraID, TPM device join): out of scope for the project. This is a platform-owned domain — OS and directory rotate those credentials natively; an external tool has no safe seat at that table. The credential-type taxonomy stays extensible; certificate renewal (above) is the adjacent slice we may claim. Principle: rotate credentials the *user* administers, never credentials the *platform* administers.
- **Entitlements/IGA**: out of the spec; future extension at most.
- **Enterprise deployment features** (HA, RBAC, multi-tenancy, SIEM): not v1; enterprise enters via spec adoption.

## 9. Milestones

- **M0 — walking skeleton + spec v0.1**: repo scaffold; spec drafts (connector protocol, event schema, manifest/signing); engine runs *one* deterministic connector (Linux password via SSH) end-to-end against a test container with the write-ahead protocol; KDBX round-trip; YubiKey-touch gating in the very first demo — it is the product's identity.
- **M1 — breadth**: all four sampler connectors including the agentic showpiece; queued-batch UX with single-touch execution; signed, hash-chained audit log.
- **M2 — public launch**: documentation, uvx packaging, demo video; spec tagged v1.0-rc only after all four connectors have validated it.

## 10. Success criteria (12 months): dogfood → community

- **Gate 1 (existence proof)**: the maintainer's own vault and machines rotate on schedule for six consecutive months.
- **Gate 2 (community proof)**: at least one connector or vault backend contributed by an unaffiliated contributor, and the first spec RFC from outside.
- Standards trajectory (independent second implementation, vendor adoption) is the horizon but earns no effort until both gates pass. Effort split until then: ~80% engine + connectors, ~20% spec/docs.

## 11. Risks

- **Agentic reliability / bot-detection arms race**: the exact failure mode that killed Dashlane's Password Changer. Mitigations: persistent enrolled sessions, headful real-browser profile, human present for 2FA/CAPTCHA, deterministic connectors as the primary path.
- **LLM data boundary scrutiny**: even with placeholder injection, page metadata leaves the machine under the cloud default. Mitigations: per-target egress policy, local-model support, redaction filter — and honesty in the docs.
- **YubiKey UX friction**: presence-gating could annoy users into disabling it. Mitigation: batch UX makes it one touch per session, not per credential.
- **Solo-maintainer bus factor**: mitigated only by reaching Gate 2.
- **pykeepass maintenance/licensing drag**: accepted consciously (D11); subprocess vault-backend quarantine remains a viable later refactor.

## 12. Prior art / positioning

HashiCorp Vault (dynamic secrets, server-side, developer/enterprise), CyberArk/Delinea/BeyondTrust (enterprise PAM, proprietary connectors), Bitwarden/1Password (vaults without real rotation), Infisical/Doppler (developer secrets). CRAKEN's unoccupied square: **an open connector *specification* plus a hardware-rooted, presence-gated rotation engine for the SOHO/prosumer tier — with the AI-agent long tail as the capability none of the incumbents' architectures anticipated.**

## 13. Open items

- Product/brand naming (CRAKEN is a working name; repo name is not the brand).
- Token connector pick: GitHub PAT vs. AWS IAM key (build-time decision; either satisfies the spec test).
- Choice of first agentic showpiece site (pick something popular, stable, and CAPTCHA-light).
