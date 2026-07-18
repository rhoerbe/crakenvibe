# CRAKEN — Product Requirements Document

*Groomed 2026-07-18 from the initial PRD in issue #1, via a structured design interview. The original issue text remains the historical seed; this document is canonical. Rationale for each architectural choice lives in [docs/adr/](docs/adr/) — this document states requirements only.*

**Working name:** CRAKEN — **C**redential **R**otation, **A**udit, **K**ey-management, **E**ntitlements & **N**otifications. (Product naming is open; "crakenvibe" is the repo, not the brand.)

---

## 1. Vision

A key security control is avoiding persistent secrets: shorter lifetimes mean reduced attack surface. SSO (Kerberos, SAML, OIDC) solved this for workforce authentication, but two areas remain uncovered: **password managers** (the long tail of web/SaaS accounts) and **PAM-style privileged credentials** (SSH keys, admin passwords, API tokens). Existing PAM products rotate credentials but through proprietary connectors; password managers have historically failed at automated rotation.

CRAKEN's answer:

1. **An open, GitHub-based specification** for credential-rotation connectors and their event stream.
2. **A reference implementation**: a vault-agnostic rotation engine anchored in a hardware cryptographic trust root.
3. **A connector ecosystem** where deterministic code connectors and AI-agent-driven playbooks are peers under one protocol.

The bet that makes rotation newly tractable: LLM browser agents can handle the long tail of web UIs that killed every previous auto-rotation product — if and only if the security architecture keeps secrets out of the model's reach.

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
| The agent drives a dedicated, persistent, headful rotation-only browser profile; per-site enrollment is one assisted login | [0008](docs/adr/0008-dedicated-persistent-browser-profile.md) |
| Reference engine: typed Python 3.12+, uv, Playwright, pykeepass, fido2/ykman; distributed via uvx/pipx | [0009](docs/adr/0009-typed-python-reference-stack.md) |
| First-party connectors live in this monorepo as signed artifacts; the engine verifies signatures before execution; manifest + signature format is normative spec content from v0.1 | [0010](docs/adr/0010-monorepo-with-signed-connectors.md) |
| Spec + schemas: CC-BY 4.0; engine: GPL-3.0; connectors and vault backends over the documented protocol are independent works, any license | [0011](docs/adr/0011-cc-by-spec-gpl3-engine-licensing.md) |
| Single maintainer; spec changes via RFC-labeled PRs + ADRs; spec semver'd, v1.0-rc only after implementation validation; DCO, no CLA | [0012](docs/adr/0012-maintainer-governance-dco.md) |

## 5. Specification scope (v1)

Two documents:

1. **Connector interface**: target enrollment, rotation lifecycle (create–verify–activate–revoke) with write-ahead transactional semantics ([ADR-0006](docs/adr/0006-write-ahead-rotation-protocol.md)), health check, rollback, manifest + signature format, credential-type taxonomy (password, keypair, API token; extensible).
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
- **X.509/certificate renewal** connector family (SCEP/EST/ACME) — the defensible slice of machine-adjacent territory ([ADR-0013](docs/adr/0013-machine-identity-out-of-scope.md)).
- **Further vault backends**: Bitwarden/Vaultwarden, pass, HashiCorp Vault.
- **Federated connector registry** once the first external connector exists.
- **Sandboxed connector execution** (bwrap/systemd, possibly WASM when WASI matures).

**Parked ideas** (discussed, deliberately not committed): AI-agent credential broker (the vault issues scoped short-lived credentials to AI agents instead of agents holding passwords) as an alternative reading of "launch pad"; Rust production engine; foundation governance.

## 8. Out of scope

- **Machine-to-directory identity** (workstation/server auth to AD/EntraID, TPM device join) — out for the project, not just v1 ([ADR-0013](docs/adr/0013-machine-identity-out-of-scope.md)).
- **Entitlements/IGA** — out of the spec; future extension at most.
- **Enterprise deployment features** (HA, RBAC, multi-tenancy, SIEM) — not v1; enterprise enters via spec adoption.

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
- **pykeepass maintenance/licensing drag**: accepted consciously ([ADR-0011](docs/adr/0011-cc-by-spec-gpl3-engine-licensing.md)); subprocess vault-backend quarantine remains a viable later refactor.

## 12. Prior art / positioning

HashiCorp Vault (dynamic secrets, server-side, developer/enterprise), CyberArk/Delinea/BeyondTrust (enterprise PAM, proprietary connectors), Bitwarden/1Password (vaults without real rotation), Infisical/Doppler (developer secrets). CRAKEN's unoccupied square: **an open connector *specification* plus a hardware-rooted, presence-gated rotation engine for the SOHO/prosumer tier — with the AI-agent long tail as the capability none of the incumbents' architectures anticipated.**

## 13. Open items

- Product/brand naming (CRAKEN is a working name; repo name is not the brand).
- Token connector pick: GitHub PAT vs. AWS IAM key (build-time decision; either satisfies the spec test).
- Choice of first agentic showpiece site (pick something popular, stable, and CAPTCHA-light).
