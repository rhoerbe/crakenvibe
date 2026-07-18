# Monorepo now; connector signing spec'd from day one

V1 ships four first-party connectors — standing up a Terraform-style federated registry for an ecosystem of one would be infrastructure cosplay. The opposite failure is worse: if the spec ships without a connector manifest + signature format, the first third-party connector arrives unsigned and sideloading becomes the culture, hollowing out the "possession ≠ operation" trust story (ADR-0003). So: first-party connectors live in the monorepo and are released as signed artifacts (minisign/ssh-sig); the engine verifies signatures before executing any connector not built from local source; the manifest + signature format is normative spec content from v0.1. A federated index repo is chartered but only built when the first external connector appears.

## Considered Options

- **Federated registry now**: correct end-state, weeks of infrastructure designed with zero real-world input.
- **Sideloading only**: zero friction, and a culture that doesn't unset.
- **Foundation-first governance**: credibility theater before traction.
