# CRAKEN — Model Views (draft)

*Draft views for the design grilling, 2026-07-19. Notation: Mermaid throughout (renders natively on GitHub, zero toolchain). The durable architecture-description tooling (LikeC4 semantic model + layout snapshots, PlantUML for behavior — per the lobotom-y metamodel) is a pending adoption decision; these drafts are written to port 1:1 when that lands. Status tags follow the lobotom-y vocabulary: `v1` (committed), `v1.1+`, `v2`, `parked`.*

Terms are used per [CONTEXT.md](../../CONTEXT.md); decisions per [docs/adr/](../adr/).

---

## V1 — Capability map

Capabilities structure the spec and roadmap; each maps to spec chapters and engine components. (Whether the capability layer becomes a normative model element kind is an open grilling question.)

```mermaid
flowchart TD
    subgraph CL["Credential Lifecycle [v1]"]
        ENR[Enroll target]
        ROT[Rotate - write-ahead]
        VER[Verify and activate]
        RET[Retire old secret]
    end
    subgraph AS["Assurance [v1]"]
        PG[Presence gate]
        ENV[Envelope T2 and T3]
        ATT[Attestation]
    end
    subgraph DI["Disclosure [v1 partial]"]
        MS["Managed session [v1]"]
        HC["Hardened clipboard [v1]"]
        EI["Env injection [v1.1]"]
        EF["Extension fill [v1.1+]"]
        AT["Auto-type [v1.1+]"]
    end
    subgraph RE["Replication [v1 partial]"]
        PUSH["Push to OS keychain [v1: Secret Service]"]
        STAL[Staleness tracking]
    end
    subgraph DP["Displacement [M2]"]
        IMP[Import from browser]
        DIS[Disable browser saving]
        PRE[Preempt new-password forms]
    end
    subgraph OB["Observability [v1]"]
        AUD[Signed audit trail]
        NOT[Notification - the kraken]
    end
    LP["Launch pad [v2]"]
    CL --> AS
    DI --> AS
    RE --> CL
    OB --> CL
    LP -.reuses.-> MS
```

## V2 — Container view (C4 level 2, simplified)

```mermaid
flowchart LR
    USER([SOHO admin])
    YK[/YubiKey - PIV touch policy/]
    subgraph ENGINE["CRAKEN engine [v1, Python]"]
        CORE[Batch planner and rotation core]
        CER[Ceremony service - presence gate, disclosure]
        EVT[Event log - hash chain]
    end
    KDBX[(Authoritative vault - KDBX, T1 plain)]
    ENVS[(Envelope store - T2 T3 wrapped)]
    PROF[Rotation browser profile - headful, saving disabled]
    CONN[Connectors - subprocess JSON-RPC]
    AGX[Agentic executor - interpreter-connector]
    RADP["Replica adapter - Secret Service [v1]"]
    OSK[(OS keychain - T1 replicas)]
    LLM[LLM backend - pluggable, cloud default]
    TGT[Targets - SSH, API, web UI]
    ECO["KeePassXC + browser extension [third-party]"]

    USER --> CER
    CER --> YK
    CORE --> KDBX
    CER --> ENVS
    CORE --> CONN
    CONN --> TGT
    AGX --> PROF
    PROF --> TGT
    AGX --> LLM
    CORE --> RADP
    RADP --> OSK
    CORE --> EVT
    ECO --> KDBX
    CER --> PROF
```

Trust-boundary notes: secrets cross engine↔connector via stdio pipe only; the LLM backend receives placeholders and redacted DOM, never secrets; the ecosystem (KeePassXC + extension) reads T1 only — envelope entries are opaque to it.

## V3 — Domain class model (below the C4 floor)

The three policy-typed relationship families — **rest** (SecretPart→Store), **replication** (SecretPart→Replica), **transit** (Disclosure→DisclosurePath) — are each constrained by the credential set's Tier. That is the modeling answer to "how do we model storage, replication policy and transit path": tier as a policy object typing three association families, enforced at runtime and asserted in the spec.

```mermaid
classDiagram
    class CredentialSet {
        account
        tier
    }
    class SecretPart {
        kind: password, totp-seed, recovery-codes, keypair, api-token
        restForm: plain or envelope
    }
    class Tier {
        restForm policy
        replication policy
        allowed transit paths
    }
    class Store
    class AuthoritativeVault
    class EnvelopeStore
    class OSKeychain
    class BrowserStore
    class Replica {
        state: in-sync or stale
    }
    class DisclosurePath {
        kind: managed-session, clipboard, env-inject, ext-fill, auto-type, ssh-agent
    }
    class Disclosure {
        attestation
        ttl
    }
    class Target
    class RotationEvent

    CredentialSet "1" *-- "1..*" SecretPart : consists of
    CredentialSet --> Tier : classified as
    CredentialSet --> Target : authenticates to
    CredentialSet --> CredentialSet : issued-by
    SecretPart --> Store : rests in
    Store <|-- AuthoritativeVault
    Store <|-- EnvelopeStore
    Store <|-- OSKeychain
    Store <|-- BrowserStore
    SecretPart "1" --> "0..*" Replica : replicated as
    Replica --> OSKeychain : lives in
    Disclosure --> SecretPart : materializes
    Disclosure --> DisclosurePath : via
    Tier ..> DisclosurePath : permits
    Tier ..> Replica : forbids above T1
    Disclosure --> RotationEvent : emits
```

Notes:
- **BrowserStore** appears only as a displacement source (import) — never a rest or replica store (ADR-0015).
- **`issued-by`** models the authority chain: self-provisioned sets root in registration-time secrets (recovery codes, registered authenticator — the true T3 of the set); delegated credentials (enterprise-provisioned accounts, PATs) point to the parent credential that can re-issue them. Blast radius flows along `issued-by` edges; T3 = a node with inbound `issued-by` edges from other sets.
- **MFA artifacts are SecretParts**, not separate credentials: a TOTP seed or recovery-code block belongs to the set, with its own restForm and (potentially stricter) disclosure policy.

## V4 — Secret rotation lifecycle (state machine)

```mermaid
stateDiagram-v2
    [*] --> Active
    Active --> PendingStaged : batch planned, new secret persisted write-ahead
    PendingStaged --> Applied : connector set on target
    PendingStaged --> Active : abort before apply, discard pending
    Applied --> Verified : authenticated with new secret
    Applied --> RollbackAttempt : verify failed
    RollbackAttempt --> Active : old secret restored or still valid
    RollbackAttempt --> Conflicted : manual intervention, both secrets uncertain
    Verified --> Active : new secret active, old retained
    Active --> Retired : old secret revoked after grace
    note right of PendingStaged : lockout-safe, vault holds both values
    note right of Conflicted : alarm event, the kraken wakes
```

Replica sub-lifecycle (per replica, T1 only): `in-sync → stale` on rotation commit; `stale → in-sync` on adapter push; staleness emits events consumed by notification.

## V5 — Ceremonial disclosure via managed session (sequence, T3 example: Proxmox)

```mermaid
sequenceDiagram
    actor U as SOHO admin
    participant E as Engine (ceremony svc)
    participant Y as YubiKey
    participant P as Rotation profile (browser)
    participant T as Proxmox web UI
    U->>E: open proxmox (launch request)
    E->>U: request presence
    U->>Y: touch
    Y-->>E: unwrap envelope entry (PIV decrypt)
    E->>P: launch profile, navigate to target
    E->>P: inject username and password (CDP recipe, no LLM)
    opt TOTP second factor
        E->>P: inject code (engine-held seed)
        Note over U,P: or user types code from own authenticator
    end
    P->>T: submit login
    T-->>P: authenticated session
    E->>E: zeroize plaintext, emit disclosure event (attestation: presence)
    E-->>U: hand over authenticated window
    Note over P: profile has saving and sync hard-disabled, session cookie stays isolated
```

## V6 — Tier policy matrix (the normative table behind V3)

| Tier | Rest form | Replication | Permitted transit paths | Fill visibility |
|---|---|---|---|---|
| T1 standard | plain KDBX entry | OS keychains via adapters | ecosystem autofill, all disclosure paths | silent fill allowed |
| T2 high | envelope entry | none | managed session (preferred), hardened clipboard, env injection, extension fill (v1.1+), auto-type (KVM/RDP) | explicit ceremony per use |
| T3 privileged | envelope entry | none | managed session only; ssh-agent with confirm-per-use for keys | user never sees or handles plaintext |

Recovery codes and other registration-time root secrets: T3, disclosure = break-glass ceremony only (proposed; pending grilling).
