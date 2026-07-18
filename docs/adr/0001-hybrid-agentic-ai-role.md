# Hybrid role for agentic AI

Automated password rotation has historically died on the long tail of web UIs — every change-password flow is different, and scripted connectors rot (Dashlane's Password Changer being the famous casualty). LLM browser agents are the first technology that plausibly cracks that long tail, but a model with cleartext credentials in its context is an indefensible posture for a credential tool. We therefore use a hierarchy: deterministic, spec-driven connectors are the primary path wherever an API/CLI exists; agentic browser automation is the fallback for web UIs without one; AI additionally assists at dev time by generating connectors and playbooks from documentation. Secrets never enter model context (see ADR-0007).

## Considered Options

- **AI as the core engine** (connectors are just playbooks): maximum coverage, but the model touches secrets — unsellable to the security-conscious audience this is for.
- **Dev-time AI only**: cleanest posture, but leaves the web long tail — the differentiator — unsolved.
- **No AI**: a classic connector framework; nothing existing tools don't already do.
