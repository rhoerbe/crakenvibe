# Dedicated persistent browser profile for the agent

Web rotation happens inside a logged-in session, and how the agent gets one decides whether the showpiece works: a fresh automation profile pays the full login + 2FA + bot-detection toll on every run (the reliability profile that killed every previous auto-rotation product), while attaching to the user's daily browser is invasive and an open CDP port is its own attack surface. The engine therefore owns a browser profile used only for rotations — headful and visible. Enrolling a site means one assisted login (the user handles 2FA once); the session persists, so later rotations skip most friction. A real-browser fingerprint beats headless bot detection, daily browsing stays isolated, and the user watching every action builds exactly the trust a credential tool needs — which fits presence-gated batches (ADR-0004), where a human is already there for surprise CAPTCHAs.

## Considered Options

- **Fresh profile per run**: purest isolation, fatal friction.
- **Drive the user's daily browser (CDP attach)**: zero enrollment friction, but the agent operates amid all open sessions and "the AI drives my real browser" is a hard trust sell.
- **WebExtension hybrid** (KeePassXC-Browser-style native messaging): the honest long-term path for session sharing; deferred — it adds a whole extension codebase to v1.
