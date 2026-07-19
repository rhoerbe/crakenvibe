# Passkeys: coexist; the fallback password is our territory

Passkeys are the industry's answer to shared secrets, homed in the same OS/browser keychains CRAKEN coexists with — so the PRD must answer "why build password rotation in 2026?". The stance: no passkey mechanics in v1. The web long tail converts slowly; the SOHO admin's core inventory (SSH, API tokens, DBs, routers, NAS, legacy web) stays shared-secret for years; and on most sites a passkey is added *alongside* the password, leaving a dormant fallback that remains a live attack surface — rotating that fallback is territory passkeys create, not destroy. The chosen ecosystem is already passkey-capable (KeePassXC stores passkeys in KDBX since 2.7.7), so the authoritative store doesn't lose the passkey race and CRAKEN duplicates nothing. The credential-type taxonomy reserves *passkey* as a future family; the roadmap names the post-v1 **passkey upgrade** connector operation: agentically enroll a passkey, then rotate or neutralize the password fallback — the ultimate rotation.

## Considered Options

- **Passkey support in v1**: duplicates KeePassXC's existing storage for zero rotation value.
- **Ignore passkeys**: leaves the first objection every reviewer will raise unanswered.
- **Passkey-first pivot**: a defensible different product that abandons the PAM-gap inventory where rotation is unavoidable and competition thinnest.
