# CRAKEN Architecture Description — Metamodel

Adapted from the lobotom-y metamodel (`docs/architecture/metamodel.md` there), extended with the capability lens per [ADR-0020](../adr/0020-capability-element-kind.md). This document is normative for what kinds of things the AD contains and which artifact owns which fact.

## Notation status

Target state is the two-layer principle: a LikeC4 semantic model (elements, relationships — zero geometry) plus per-view layout snapshots, with PlantUML for behavior below the C4 floor. Adoption is **pending the lobotom-y ADR-0042 pilot verdict**. Until then, [views.md](views.md) holds Mermaid drafts that are temporarily authoritative for both semantics and layout — an accepted violation, written to port 1:1.

## Authority boundaries

Each fact has exactly one home:

- **PRD.md** — requirements (the *what*).
- **docs/adr/** — rationale and rejected alternatives (the *why*).
- **CONTEXT.md** — the ubiquitous language; glossary only, no structure, no implementation.
- **The model** (today: views.md drafts) — structure and inventory: elements, kinds, status, relationships, traceability edges.
- **Behavioral artifacts** — sequence, state, and class diagrams; linked from the model, never duplicated in it.

Prose may reference model elements by their exact name (iron naming rule); it never redefines structure. Model element names for domain concepts must match CONTEXT.md terms exactly.

## Element and relationship kinds

- **Element kinds:** `actor`, `usecase`, `capability`, `system` (external), `node` (deployment), `component`, `datastore`.
- **Relationship kinds:** `uses` (default), `realizes` (two sanctioned directions: use case → component, component → capability), `uc-include`, `uc-extend`.

**Capability/use-case boundary rule:** capabilities state what the system can do — function, actor-free, stable; use cases state who does what with it — actor value. A use case may reference capabilities; never the reverse.

## Status tags

Element status: `built | partial | proposed | deferred`, plus `third-party`. Roadmap tags on capabilities and views: `v1 | v1.1+ | v2 | parked`, matching PRD milestones.

## Domain-model idiom: policy-typed associations

Storage, replication, and transit are modeled as three association families — `rests-in`, `replicated-as`, `disclosed-via` — each constrained by the Tier policy object. The class model (views V3) and the tier policy matrix (V6) are a normative pair: V3 defines the structure, V6 the permitted instances. Changes to one require changing both.

## Sync rules

Direction always presentation ← model:

1. Every element or term name in AD prose exists in the model or CONTEXT.md with that exact string.
2. V3 (class model) and V6 (tier matrix) must agree.
3. Capability names in PRD roadmap/milestones exist as `capability` elements.
4. CI lint for these rules: deferred until the repo has code and a toolchain.
