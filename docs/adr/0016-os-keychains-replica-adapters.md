# OS keychains are T1 replica stores, synced via adapters

macOS Keychain, Windows Credential Manager, and FreeDesktop Secret Service are login-unlocked convenience stores with writable APIs. They are never authoritative — their unlock model (session possession = disclosure) is incompatible with the possession-≠-operation trust root (ADR-0003) — and they never hold T2/T3 (ADR-0014). For T1 they are first-class **replicas**: the spec models a per-credential replica inventory, push-after-rotation semantics, and staleness events. Replica adapters are subprocess plugins under the same JSON-RPC protocol as connectors (ADR-0005). V1 ships one reference adapter, Secret Service — cheapest to build and headless-test on the dev platform — proving the interface; macOS and Windows adapters follow as well-shaped community contributions. KeePassXC's Secret Service provider mode is documented as the zero-copy alternative on Linux for consumers that can use it.

## Considered Options

- **All three OS adapters in v1**: honors "sync where APIs exist" on day one, at the price of two extra platform test rigs in an already-grown v1.
- **Spec only, no adapter**: an interface no implementation exercised — the spec-validation sin the breadth sampler exists to prevent.
- **Provider mode instead of push**: deepest coexistence but Linux-only, contends with gnome-keyring for the bus name, and duplicates what KeePassXC already offers.
