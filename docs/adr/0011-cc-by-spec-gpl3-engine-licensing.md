# Licensing: CC-BY 4.0 spec, GPL-3.0 engine

pykeepass is GPL-3.0 (verified on PyPI), so an engine importing it in-process is effectively GPL-3 when distributed — a hard constraint, not a preference. Meanwhile the spec is the adoption artifact: vendors implement it, so it must be maximally unencumbered. Decision: spec + protocol schemas under CC-BY 4.0; the engine under GPL-3.0, embracing the constraint as strategy — reference code stays open and proprietary forks can't take it closed, while nobody needs to embed a reference engine anyway. The spec explicitly declares that connectors and vault backends communicating over the documented protocol are independent works (the GPL's own separate-programs doctrine, reinforced by the subprocess boundary of ADR-0005), so community connectors may carry any license.

## Considered Options

- **Apache-2.0 engine with KDBX quarantined in a subprocess vault-backend plugin**: architecturally consistent and viable as a later refactor, but v1 would pay an architecture tax for a purity no current stakeholder is asking for.
- **Replace pykeepass with a permissive KDBX library**: none is mature in Python; crypto-format parsing is the worst possible place for v1 effort.
- **Copyleft spec**: a spec commercial vendors' lawyers won't let them implement defeats its reason to exist.
