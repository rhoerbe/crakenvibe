# Reference engine in typed Python

Because connectors are language-agnostic by protocol (ADR-0005), the engine's language is not an ecosystem decision — contributors never touch it. A *reference* implementation's job is to make the spec legible and iterate fast while the spec is still wet, and every library this project needs is first-class in Python: pykeepass (KDBX), fido2/ykman (token), Playwright (browser), the LLM SDKs. So: Python 3.12+, strict typing (pyright), uv for env/packaging, distribution via uvx/pipx — acceptable for the technical-SOHO persona. A Rust production engine remains a legitimate post-stability successor; the spec, not the engine, is the durable artifact.

## Considered Options

- **Rust**: memory safety, single binary, strong optics — but triple friction (iteration speed, thinner agentic/browser ecosystem, not the maintainer's daily language) during exactly the phase where the spec changes weekly.
- **Go**: a reasonable middle, best-in-class at neither.
- **TypeScript/Node**: Playwright's home, but weak KDBX/YubiKey libraries and the npm runtime story.
