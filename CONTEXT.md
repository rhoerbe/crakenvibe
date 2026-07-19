# CRAKEN

Credential rotation for the gaps SSO doesn't cover: an open connector specification plus a hardware-rooted reference engine that rotates the credentials a user administers. This glossary is the ubiquitous language for the spec, the engine, and the PRD.

## Language

### Stores & tiers

**Authoritative store**:
The single store holding the current truth of every managed credential — the hardware-rooted KDBX vault.
_Avoid_: master vault, primary store, database

**Replica**:
A convenience copy of a T1 credential in a login-unlocked OS store, created and updated only by a replica adapter.
_Avoid_: copy, cache, mirror, sync target

**Assurance tier**:
The per-credential classification — T1 standard, T2 high, T3 privileged — that determines storage form, disclosure ceremony, and replica policy.
_Avoid_: security level, sensitivity, class

**Privileged credential (T3)**:
A credential that can control other credentials or accounts: engine admin keys, email, IdP, registrar.
_Avoid_: admin password, root credential

**Envelope entry**:
A T2/T3 secret individually encrypted to a touch-policy hardware key; opaque to plain KeePassXC.
_Avoid_: wrapped blob, sealed secret

**Staleness**:
The state of a replica or external copy that still holds a pre-rotation value.
_Avoid_: drift, desync

### Rotation

**Target**:
A system holding an account whose credential CRAKEN manages and rotates.
_Avoid_: endpoint, host, integration

**Connector**:
A subprocess speaking the versioned JSON-RPC protocol that rotates credentials on targets.
_Avoid_: plugin, driver, integration

**Interpreter-connector**:
A connector whose executable interprets artifacts rather than hard-coding one target: the agentic executor (playbooks) and the declarative HTTP executor (descriptors).
_Avoid_: meta-connector

**Replica adapter**:
A subprocess plugin that pushes rotated T1 credentials into an OS keychain and reports staleness.
_Avoid_: sync connector, keychain plugin

**Rotation batch**:
A queued set of planned rotations executed under a single presence gate.
_Avoid_: job, run, schedule

**Enrollment**:
Bringing a target under management; for web targets, includes the one assisted login into the rotation browser profile.
_Avoid_: onboarding, registration

**Presence gate**:
The requirement of physical user presence (hardware touch/PIN) before the engine may unwrap secrets for a batch.
_Avoid_: 2FA, approval

**Disclosure**:
The transient, per-use decryption of a T2/T3 secret, authorized by one hardware touch.
_Avoid_: unlock (vault-level), reveal, export

**Attestation**:
The recorded authorization level of a rotation event; v1 events always attest user presence.
_Avoid_: approval level

### Coexistence

**Displacement**:
The browser strategy: import existing browser credentials, disable the browser's own store, and serve fill from the authoritative store — eliminating copies instead of synchronizing them.
_Avoid_: cascade, browser sync, migration (import step only)

**Preemption**:
The ecosystem extension offering generation/fill on `new-password` forms before the browser's own UI does, so new credentials are born in the vault.
_Avoid_: interception, hooking
