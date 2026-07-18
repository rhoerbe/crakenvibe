# Rotation is transactional: write-ahead protocol

The nightmare failure of rotation is lockout: the new password is live on the target but the vault write was lost (or vice versa). The spec therefore mandates a write-ahead sequence: durably persist the pending new secret (vault entry history / journal) → apply on the target → verify by actually authenticating with the new secret → mark active; the old secret is retained until verification passes. The connector API is shaped around these phases — token-class credentials (create-verify-revoke) force the two-phase shape anyway.
