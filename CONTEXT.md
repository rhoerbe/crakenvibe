# CRAKEN

Credential rotation for the gaps SSO doesn't cover: an open connector specification plus a hardware-rooted reference engine that rotates the credentials a user administers. This glossary is the ubiquitous language for the spec, the engine, and the PRD.

Entry style (ISO 27002 pattern): a terse authoritative definition, optionally followed by a _Guidance_ line — plain-language explanation and examples for general IT-security readers. The definition is normative; guidance never contradicts it.

## Language

### Credentials & authority

**Credential set**:
The full set of secrets belonging to one account — password, TOTP seed, recovery codes, keys — each a secret part with its own policy.
_Avoid_: login, entry (that's the KDBX artifact)

**Secret part**:
One secret within a credential set, carrying its own rest form and disclosure policy.
_Avoid_: field, attribute

**Root secret**:
A registration-time secret part that anchors an account's recovery chain (recovery codes, registered authenticator). Always T3; break-glass disclosure only.
_Avoid_: recovery keys, master key

**Break-glass account**:
An account held exclusively for emergencies and never used in routine operation (local admin for SSO outage, cloud emergency-access admin). Always T3.
_Avoid_: emergency account, backup admin, root account (unless literally root)

**TOTP escrow**:
The custody mode where a TOTP seed is stored as a root-secret-style part with break-glass disclosure only — a second-factor backup that survives phone loss; routine codes still come from the user's authenticator.
_Avoid_: seed backup, 2FA export

**Issued-by**:
The authority-chain relationship from a credential set to the parent authority able to re-issue it. Blast radius flows along these edges; T3 status is computable from them.
_Avoid_: parent account, derived from

**Privileged credential (T3)**:
A credential that can control other credentials or accounts: engine admin keys, email, IdP, registrar.
_Avoid_: admin password, root credential

**Assurance tier**:
The per-credential classification — T1 standard, T2 high, T3 privileged — that determines storage form, disclosure ceremony, and replica policy.
_Avoid_: security level, sensitivity, class

### Stores

**Authoritative store**:
The single store holding the current truth of every managed credential — the hardware-rooted KDBX vault.
_Avoid_: master vault, primary store, database

**Envelope entry**:
A T2/T3 secret part individually encrypted to a touch-policy hardware key; opaque to plain KeePassXC.
_Avoid_: wrapped blob, sealed secret

**Replica**:
A convenience copy of a T1 credential in a login-unlocked OS store, created and updated only by a replica adapter.
_Avoid_: copy, cache, mirror, sync target

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
The requirement of physical user presence (hardware touch/PIN) before the engine may decrypt envelope entries for a batch.
_Guidance_: The touch alone is not an authentication factor — anyone's finger satisfies it. It proves a human is at this machine right now, which is an authorization condition; identity comes from the vault unlock and optional PIN.
_Avoid_: 2FA, approval

**Attestation**:
The recorded authorization level of a rotation or disclosure event; v1 events always attest user presence.
_Avoid_: approval level

### Disclosure

**Ceremony**:
The human-facing steps of a disclosure: explicit request naming the credential, fresh presence proof, logged event.
_Guidance_: In the security-ceremony sense (Ellison): the human is a protocol participant, not an externality. Machine-side duties (decryption timing, erasure) are hygiene, not ceremony.
_Avoid_: ritual, approval flow

**Disclosure**:
The controlled use of a T2/T3 secret, combining ceremony with hygiene: decryption only after the presence proof, short-lived plaintext erased (zeroized) after use, conveyed only through a permitted disclosure path.
_Guidance_: Example: "show my Hetzner password" → touch the YubiKey → CRAKEN decrypts the entry, places it on the hardened clipboard for 20 seconds, wipes it, writes an audit event. Missing any part makes it something else: no bounded lifetime by design = export; hygiene failed at runtime = exposure. (Key-management readers: the decryption step is a key unwrap.)
_Avoid_: unlock (vault-level), reveal, materialization

**Export**:
Plaintext egress of a secret with no bounded lifetime — written to a file, printed, or placed on an unmanaged clipboard. Forbidden for T2/T3.
_Guidance_: Export is a policy violation for high tiers, not a failure: the path never promised erasure. T1 secrets may be exported deliberately (e.g., CSV for a migration), always with an event.
_Avoid_: backup (that's vault-level), copy

**Exposure**:
Any occurrence of secret plaintext outside a completed disclosure — a runtime hygiene failure such as a crash before erasure or a captured clipboard. Every exposure raises an alarm event and queues an out-of-cycle rotation of the affected credential.
_Guidance_: Example: a clipboard manager grabbed the password during the paste window → exposure event → the kraken wakes → rotation of that credential is queued immediately. Rotation is the antidote to the system's own failures.
_Avoid_: leak (colloquial), breach (org-level)

**Disclosure path**:
The channel through which disclosed plaintext reaches its consumer: managed session, hardened clipboard, environment injection, extension fill, auto-type, ssh-agent. Tier policy permits paths per tier.
_Avoid_: fill method, output channel

**Managed session**:
The disclosure path where the engine logs into a target inside its isolated browser profile and hands the user the authenticated window; the user never handles the secret.
_Avoid_: auto-login, session injection

**Hardened clipboard**:
The clipboard disclosure path with sensitive-flagging, history/cloud-sync exclusion, timed auto-clear, and per-copy audit.
_Avoid_: copy-paste

**Environment injection**:
The disclosure path that delivers a secret as an environment variable of exactly one child process.
_Avoid_: env export

**Break-glass disclosure**:
The disclosure variant for root secrets and break-glass accounts: full ceremony plus reason capture, always raising an alarm event — the kraken wakes even on success.
_Avoid_: emergency unlock

### Coexistence

**Displacement**:
The browser strategy: import existing browser credentials, disable the browser's own store, and serve fill from the authoritative store — eliminating copies instead of synchronizing them.
_Avoid_: cascade, browser sync, migration (import step only)

**Preemption**:
The ecosystem extension offering generation/fill on `new-password` forms before the browser's own UI does, so new credentials are born in the vault.
_Avoid_: interception, hooking
