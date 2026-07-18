# Pluggable LLM provider with cloud default

Agentic browsing on today's local models is unreliable, and the showpiece connector lives or dies on reliability — yet even secret-free page payloads (site names, account identifiers) have privacy weight when they leave the machine. The model provider is therefore a configurable backend: frontier cloud API by default, local runtimes (Ollama-class) supported. Three invariants hold regardless of provider: **placeholder injection** — the browser-driving tool layer substitutes `{{NEW_SECRET}}` into form fields itself, so the model sees placeholders in both directions; a **redaction filter** scrubs known secrets from DOM/screenshot payloads before they reach model context; and a **per-target policy** can forbid cloud egress or agentic rotation entirely for sensitive entries. The privacy posture is per-credential, not global.

## Considered Options

- **Cloud only**: least engineering, but structurally requiring page-data egress with no local escape hatch hands reviewers their headline objection.
- **Local only**: cleanest boundary, but the differentiator becomes a coin-flip demo until local models catch up.
- **Pluggable with local default**: principled, but the first rotation a new user ever runs would fail at high rate — defaults should showcase the product working.
