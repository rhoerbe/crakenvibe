# Machine-to-directory identity is out of scope

Workstation/server authentication to central management (AD/EntraID device join, TPM-backed machine accounts) is a platform-owned domain: the OS and directory rotate those credentials natively, and an external tool has no safe seat at that table. It is out of scope for the project — not just for v1 — under the principle: **rotate credentials the user administers, never credentials the platform administers.** The credential-type taxonomy stays extensible, and X.509/certificate renewal (SCEP/EST/ACME-style) is named as the adjacent, defensible slice that may become a future connector family.

## Considered Options

- **Roadmap item (v3+)**: keeps the original PRD's breadth, but commits the project to a domain where platform vendors hold all the levers.
- **Unimplemented taxonomy type in v1**: violates the implementation-validated principle (ADR-0012).
- **Core pillar**: a different product, sold to a different buyer, against Microsoft.
