# CRAKEN — Product Requirements Document

*Groomed 2026-07-18 from the initial PRD in issue #1 via a structured design interview; extended 2026-07-19 with the credential-store coexistence model. The original issue text remains the historical seed; this document is canonical. Rationale for each architectural choice lives in [docs/adr/](docs/adr/) — this document states requirements only. Domain vocabulary is defined in [CONTEXT.md](CONTEXT.md).*

**Working name:** CRAKEN — **C**redential **R**otation, **A**udit, **K**ey-management, **E**ntitlements & **N**otifications. (Product naming is open; "crakenvibe" is the repo, not the brand.)

---

## 1. Vision

A key security control is avoiding persistent secrets: shorter lifetimes mean reduced attack surface. SSO (Kerberos, SAML, OIDC) solved this for workforce authentication, but two areas remain uncovered: **password managers** (the long tail of web/SaaS accounts) and **PAM-style privileged credentials** (SSH keys, admin passwords, API tokens). Existing PAM products rotate credentials but through proprietary connectors; password managers have historically failed at automated rotation.

CRAKEN's answer:

1. **An open, GitHub-based specification** for credential-rotation connectors and their event stream.
2. **A reference implementation**: a vault-agnostic rotation engine anchored in a hardware cryptographic trust root.
3. **A connector ecosystem** where deterministic code connectors and AI-agent-driven playbooks are peers under one protocol.

The bet that makes rotation newly tractable: LLM browser agents can handle the long tail of web UIs that killed every previous auto-rotation product — if and only if the security architecture keeps secrets out of the model's reach.

CRAKEN defends **two attack scenarios** with different mechanics: leaked long-standing copies (answered by comprehensive rotation, which time-bounds every exfiltrated copy) and in-session memory scraping (answered by per-use disclosure of high-tier secrets).

## 2. What this project is not

- Not a new password manager. The engine works against the user's existing vault (KDBX first).
- Not an enterprise PAM. Enterprise is served by the spec being adoptable, not by v1 features (no HA, RBAC, multi-tenancy, SIEM).
- Not a machine-identity system ([ADR-0013](docs/adr/0013-machine-identity-out-of-scope.md)).
- Not an IGA/entitlements product. Entitlements are explicitly out of the v1 spec.

## 3. Persona (v1)

**The technical SOHO admin**: homelab or small-business operator who is both end user and de-facto sysadmin. Runs a KeePass-class vault; administers a NAS, a router, a few Linux boxes; holds developer tokens and dozens of web accounts. Has no PAM budget; today, rotation simply never happens. Adopts open source readily and is the population from which connector contributors come.

Enterprise vendors and MSPs are future audiences addressed through spec adoption, not v1 requirements.

## 4. Key architectural properties

Requirements only; the reasoning behind each is in the linked ADR.

| Property | ADR |
|---|---|
| Deterministic connectors are the primary rotation path; agentic browser automation covers the no-API long tail; AI assists connector authoring at dev time | [0001](docs/adr/0001-hybrid-agentic-ai-role.md) |
| The engine is standalone and vault-agnostic; vaults are pluggable backends, KDBX file first; KeePassXC stays unmodified | [0002](docs/adr/0002-standalone-vault-agnostic-engine.md) |
| A hardware trust root (YubiKey first, HSM-class later) gates secret release by user presence; vault-at-rest inherits KDBX + YubiKey challenge-response; the audit log is hash-chained and hardware-signed | [0003](docs/adr/0003-hardware-trust-root-gates-secret-release.md) |
| V1 is presence-gated only: queued batches executed on one hardware touch; no unattended mode | [0004](docs/adr/0004-no-unattended-mode-in-v1.md) |
| Connectors are subprocesses speaking versioned JSON-RPC over stdio; secrets cross via pipe only; agentic and declarative executors are interpreter-connectors under the same protocol | [0005](docs/adr/0005-subprocess-json-rpc-connector-model.md) |
| Rotation is transactional: pending secret persisted before target change, verify-then-activate, old secret retained until verified | [0006](docs/adr/0006-write-ahead-rotation-protocol.md) |
| The LLM provider is pluggable (cloud default, local supported); placeholder injection and redaction keep secrets out of model context; per-target policy can forbid cloud egress or agentic rotation | [0007](docs/adr/0007-pluggable-llm-cloud-default.md) |
| The agent drives a dedicated, persistent, headful rotation-only browser profile; per-site enrollment is one assisted login; the profile's own password saving and sync are hard-disabled | [0008](docs/adr/0008-dedicated-persistent-browser-profile.md) |
| Reference engine: typed Python 3.12+, uv, Playwright, pykeepass, fido2/ykman; distributed via uvx/pipx | [0009](docs/adr/0009-typed-python-reference-stack.md) |
| First-party connectors live in this monorepo as signed artifacts; the engine verifies signatures before execution; manifest + signature format is normative spec content from v0.1 | [0010](docs/adr/0010-monorepo-with-signed-connectors.md) |
| Spec + schemas: CC-BY 4.0; engine: GPL-3.0; connectors and vault backends over the documented protocol are independent works, any license | [0011](docs/adr/0011-cc-by-spec-gpl3-engine-licensing.md) |
| Single maintainer; spec changes via RFC-labeled PRs + ADRs; spec semver'd, v1.0-rc only after implementation validation; DCO, no CLA | [0012](docs/adr/0012-maintainer-governance-dco.md) |
| Every credential carries an assurance tier (T1 standard / T2 high / T3 privileged) determining storage form, disclosure ceremony, and replica policy; T2/T3 are per-item envelope-encrypted to a touch-policy hardware key | [0014](docs/adr/0014-credential-assurance-tiers.md) |
| Browser password stores are displaced, never written: CSV import wizard, programmatic disable of browser saving, fill served from the live authoritative vault by the ecosystem extension | [0015](docs/adr/0015-browser-stores-displacement.md) |
| OS keychains are T1-only replica stores; replica inventory, push-after-rotation, and staleness are spec content; replica adapters are subprocess plugins (Secret Service reference adapter in v1) | [0016](docs/adr/0016-os-keychains-replica-adapters.md) |
| Passkeys: coexistence, no v1 mechanics; the dormant fallback password is named rotation territory; *passkey* reserved as a future credential family | [0017](docs/adr/0017-passkeys-coexist-fallback-thesis.md) |
| T2/T3 plaintext materializes only via ceremonial disclosure paths, tier-ranked (T3: managed session only; T2: managed session preferred, hardened clipboard and env injection as fallbacks); root secrets and break-glass accounts disclose break-glass-only, always raising an alarm | [0018](docs/adr/0018-ceremonial-disclosure-paths.md) |
| TOTP seed custody is a per-target informed choice: none (user-typed codes), escrow (break-glass backup only — phone-loss resilience without factor collapse), or operational (engine-generated codes, evented) | [0019](docs/adr/0019-totp-seed-custody.md) |
| Plaintext events form a strict taxonomy — disclosure (ceremony + hygiene), export (unbounded egress, forbidden for T2/T3), exposure (runtime hygiene failure); every exposure raises an alarm and queues an out-of-cycle rotation | [0021](docs/adr/0021-exposure-queues-rotation.md) |

## 5. Coexistence with OS and browser credential stores

Every managed credential typically already exists in several stores at once (vault, browser manager, OS keychain, phone). Rotation makes unmanaged copies stale and dangerous, so coexistence is a first-class requirement, governed by the assurance tiers:

| Tier | Examples | Storage | Disclosure | Replicas & autofill |
|---|---|---|---|---|
| **T1 standard** | forums, shopping | plain KDBX entry | vault unlock, as today | replicas pushed to OS keychains where APIs exist; ecosystem autofill; rotation time-bounds leaked copies |
| **T2 high** | banking, cloud consoles | per-item envelope, hardware-wrapped | ceremonial, one touch per use: managed session preferred; hardened clipboard, env injection as fallbacks | no replicas, no silent autofill |
| **T3 privileged** | engine admin SSH/API keys; email, IdP, registrar | per-item envelope, stricter policy | managed session only (ssh-agent confirm-per-use for keys); user never handles plaintext | never |

A credential is modeled as a **credential set** of secret parts (password, TOTP seed, recovery codes, keys), each with its own policy; authority flows along *issued-by* edges, which makes T3 computable from blast radius. **Root secrets** (recovery codes, registered authenticators) and **break-glass accounts** are T3 with break-glass-only disclosure — every use raises an alarm. The normative tier×path matrix and domain model are in [docs/model/views.md](docs/model/views.md) (V3, V6); ceremony and paths are defined in [ADR-0018](docs/adr/0018-ceremonial-disclosure-paths.md).

Store-by-store requirements:

- **OS keychains** (macOS Keychain, Windows Credential Manager, FreeDesktop Secret Service): login-unlocked convenience stores with writable APIs → T1 replica targets via replica adapters; never authoritative, never above T1 ([ADR-0016](docs/adr/0016-os-keychains-replica-adapters.md)).
- **Browser built-in managers**: no supported external write path (App-Bound Encryption, Apple ACLs, no extension API) → displacement, not synchronization: CSV import with tier suggestions, programmatic disable of browser saving (`privacy.services.passwordSavingEnabled` on Chromium/Firefox; manual on Safari), T1 fill from the live vault via KeePassXC-Browser and mobile KDBX autofill apps; signup/change forms covered by preemption of the browser's suggest-password UI ([ADR-0015](docs/adr/0015-browser-stores-displacement.md)).
- **Passkeys**: live in these same platform stores; CRAKEN coexists rather than competes — v1 keeps rotating the shared secrets that remain, including the dormant password fallbacks passkeys leave behind ([ADR-0017](docs/adr/0017-passkeys-coexist-fallback-thesis.md)).

Documented honest limit: rotation does not protect the current secret from live in-session malware; for T2/T3 the per-item envelope narrows exposure to per-use windows — and any detected exposure queues an out-of-cycle rotation of the affected credential ([ADR-0021](docs/adr/0021-exposure-queues-rotation.md)).

## 6. Specification scope (v1)

Two documents:

1. **Connector interface**: target enrollment, rotation lifecycle (create–verify–activate–revoke) with write-ahead transactional semantics ([ADR-0006](docs/adr/0006-write-ahead-rotation-protocol.md)), health check, rollback, manifest + signature format, credential-type taxonomy (password, keypair, API token; extensible — *passkey* reserved), and the **replica adapter interface** (push, verify, staleness report). The credential record carries its assurance tier and replica inventory.
2. **Event schema**: mandatory for every connector and adapter action. The persisted event stream **is** the audit trail; notification (the kraken that wakes up when something goes wrong) is an event consumer. Events carry an `attestation` field recording what authorized the run; replica pushes, staleness, disclosures, exports, exposures, and break-glass alarms are first-class event types.

Out of the v1 spec: entitlements (declared future extension), trust-root key hierarchy (documented in the reference implementation's security architecture instead).

## 7. V1 connector set (the breadth sampler)

Connectors are chosen as spec test vectors — to stress every credential shape and channel once — not by user value:

| Connector | Credential type | Channel | What it proves |
|---|---|---|---|
| SSH keypair rotation on a Linux host | keypair | CLI/SSH | key staging, authorized_keys push |
| Linux account password via SSH | password | CLI/SSH | password over CLI channel |
| GitHub PAT **or** AWS IAM access key (choose at build time) | API token | REST | two-phase create-verify-revoke |
| One web-UI rotation via agentic executor | password | browser | the differentiator, placeholder injection, enrollment UX |

Plus one **replica adapter** as spec test vector: FreeDesktop Secret Service (Linux).

## 8. Post-v1 roadmap

- **Launch pad = connection launcher** (v2): click a vault entry → SSH/RDP/browser session opens with the credential injected, never shown. Reuses the rotation engine's target registry; turns the vault into the admin's daily cockpit — the retention feature that makes rotation ambient.
- **Unattended mode** (v1.1+): TPM/software operator key, weaker attestation recorded per event.
- **macOS Keychain and Windows Credential Manager replica adapters** (v1.1) — well-shaped first community contributions.
- **Passkey upgrade** connector operation: agentically enroll a passkey, then rotate or neutralize the password fallback ([ADR-0017](docs/adr/0017-passkeys-coexist-fallback-thesis.md)).
- **X.509/certificate renewal** connector family (SCEP/EST/ACME) — the defensible slice of machine-adjacent territory ([ADR-0013](docs/adr/0013-machine-identity-out-of-scope.md)).
- **Further vault backends**: Bitwarden/Vaultwarden, pass, HashiCorp Vault.
- **Federated connector registry** once the first external connector exists.
- **Sandboxed connector execution** (bwrap/systemd, possibly WASM when WASI matures).

**Parked ideas** (discussed, deliberately not committed): AI-agent credential broker (the vault issues scoped short-lived credentials to AI agents instead of agents holding passwords) as an alternative reading of "launch pad"; CRAKEN itself serving the Secret Service API (provider mode); a stale-fill-detecting browser extension; Rust production engine; foundation governance.

## 9. Out of scope

- **Machine-to-directory identity** (workstation/server auth to AD/EntraID, TPM device join) — out for the project, not just v1 ([ADR-0013](docs/adr/0013-machine-identity-out-of-scope.md)).
- **Entitlements/IGA** — out of the spec; future extension at most.
- **Enterprise deployment features** (HA, RBAC, multi-tenancy, SIEM) — not v1; enterprise enters via spec adoption.
- **Writing into browser password stores** — permanently, by platform reality ([ADR-0015](docs/adr/0015-browser-stores-displacement.md)).

## 10. Milestones

- **M0 — walking skeleton + spec v0.1**: repo scaffold; spec drafts (connector protocol, event schema, manifest/signing, replica + tier model); engine runs *one* deterministic connector (Linux password via SSH) end-to-end against a test container with the write-ahead protocol; KDBX round-trip; YubiKey-touch gating in the very first demo — engine admin credentials stored as T3 envelope entries from the start.
- **M1 — breadth**: all four sampler connectors including the agentic showpiece; queued-batch UX with single-touch execution; signed, hash-chained audit log; ceremonial disclosure v1 paths (managed session, hardened clipboard, environment injection); Secret Service replica adapter.
- **M2 — public launch**: documentation, uvx packaging, demo video; browser import wizard + guided displacement; spec tagged v1.0-rc only after all four connectors and the reference adapter have validated it.

## 11. Success criteria (12 months): dogfood → community

- **Gate 1 (existence proof)**: the maintainer's own vault and machines rotate on schedule for six consecutive months.
- **Gate 2 (community proof)**: at least one connector or vault backend contributed by an unaffiliated contributor, and the first spec RFC from outside.
- Standards trajectory (independent second implementation, vendor adoption) is the horizon but earns no effort until both gates pass. Effort split until then: ~80% engine + connectors, ~20% spec/docs.

## 12. Risks

- **Agentic reliability / bot-detection arms race**: the exact failure mode that killed Dashlane's Password Changer. Mitigations: persistent enrolled sessions, headful real-browser profile, human present for 2FA/CAPTCHA, deterministic connectors as the primary path.
- **LLM data boundary scrutiny**: even with placeholder injection, page metadata leaves the machine under the cloud default. Mitigations: per-target egress policy, local-model support, redaction filter — and honesty in the docs.
- **YubiKey UX friction**: presence-gating could annoy users into disabling it. Mitigation: batch UX makes it one touch per session, not per credential.
- **Tier ceremony friction**: touch-per-disclosure could push users to mis-tier secrets down to T1. Mitigations: sane defaults, tier suggestions in the import wizard, T2 reserved for genuinely high-value accounts.
- **Browser egress could narrow**: displacement depends on user-driven CSV export remaining available; vendors are tightening even that. Mitigation: import early in onboarding; agentic re-entry via the rotation profile remains the fallback for individual sites.
- **Solo-maintainer bus factor**: mitigated only by reaching Gate 2.
- **pykeepass maintenance/licensing drag**: accepted consciously ([ADR-0011](docs/adr/0011-cc-by-spec-gpl3-engine-licensing.md)); subprocess vault-backend quarantine remains a viable later refactor.

## 13. Prior art / positioning

HashiCorp Vault (dynamic secrets, server-side, developer/enterprise), CyberArk/Delinea/BeyondTrust (enterprise PAM, proprietary connectors), Bitwarden/1Password (vaults without real rotation), Infisical/Doppler (developer secrets). Platform stores are both consumption layer and emerging competitors: Chrome is rolling out Gemini-driven automated password change, Windows Hello normalizes verify-before-fill (precedent for the T2 ceremony), and the passkey platforms absorb the simplest web accounts. CRAKEN's unoccupied square: **an open connector *specification* plus a hardware-rooted, presence-gated, tier-aware rotation engine for the SOHO/prosumer tier — vault-authoritative where the platforms are silo-authoritative, and covering the infrastructure credentials no platform store touches.**

## 14. Open items

- Product/brand naming (CRAKEN is a working name; repo name is not the brand).
- Token connector pick: GitHub PAT vs. AWS IAM key (build-time decision; either satisfies the spec test).
- Choice of first agentic showpiece site (pick something popular, stable, and CAPTCHA-light).
- Default tier-assignment heuristics for the import wizard (which account categories suggest T2/T3).
