# Capability as a normative model element kind

The architecture description structures behavior by actor (use-case catalog) and — deferred — by sequence (process landscape). CRAKEN's spec chapters, connector families, and roadmap staging are function-shaped, so the metamodel adds the third lens: a `capability` element kind — hierarchical, status-tagged, with `realizes` edges from components — under the same index/detail split, iron naming rule, and sync discipline as use cases. Boundary rule to prevent lens drift: capabilities state *what the system can do* (function, actor-free, stable); use cases state *who does what with it* (actor value); a use case may reference capabilities, never the reverse.

## Considered Options

- **Informal diagram only**: no new sync rules, but capability names in prose go unprotected by the iron naming rule and the roadmap has no model home.
- **No capabilities**: cross-cutting engine functions (replication, attestation, displacement) are not use cases and end up homeless in the model.
- **BIZBOK-grade capability planning** (maturity/heat-maps): consulting-engagement value, ceremony without payoff for a single-maintainer project at zero code.
