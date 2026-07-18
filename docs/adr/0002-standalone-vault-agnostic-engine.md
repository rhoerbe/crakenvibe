# Standalone, vault-agnostic engine

KeePassXC deliberately has no plugin system — the maintainers have refused plugin architectures on security grounds for years, so "extend KeePassXC" was never actually on the menu. The reference implementation is therefore a separate rotation engine (CLI + daemon) that treats the vault as a pluggable backend; backend #1 is the KDBX file itself via mature libraries, leaving KeePassXC untouched and working on the same file. The vault-backend interface is spec surface, which turns Bitwarden/pass/Vault users into potential adopters instead of bystanders.

## Considered Options

- **Fork KeePassXC**: tightest UX, but inherits a large C++/Qt codebase, a permanent upstream-merge burden, and welds the spec to one vault.
- **Upstream the feature into KeePassXC**: huge distribution if accepted, but the timeline belongs to a deliberately conservative project.
- **Build our own vault**: "switch your vault" is the highest-friction ask in this market.
