# Connectors are subprocesses speaking JSON-RPC

The plugin mechanism determines who can write connectors, in what language, and what a malicious connector can reach. Every connector is an executable speaking a versioned JSON-RPC protocol over stdio (the Terraform/LSP pattern): language-agnostic for contributors, process-isolated now with sandboxing (bwrap/systemd) as an upgrade path, and secrets cross the boundary through the pipe only — never argv or env. The agentic executor and a declarative-HTTP executor are themselves just interpreter-connectors under the same protocol, so playbooks and YAML descriptors need no second mechanism. Process overhead is irrelevant at rotation timescales.

## Considered Options

- **In-process Python plugins**: fastest to build, but every third-party connector would run with full engine privileges including vault access — a supply-chain liability baked into the spec's DNA — and language-locked.
- **WASM components**: sandboxed by construction, but WASI can't realistically drive SSH or a browser today; revisit as an execution profile when it can.
- **Declarative-only**: lowest contribution bar, but expressiveness dies at the first nontrivial flow; lives on as one interpreter-connector instead.
