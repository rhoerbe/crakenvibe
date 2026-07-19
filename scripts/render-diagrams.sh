#!/usr/bin/env bash
# Render the CRAKEN architecture diagrams (lobotom-y ADR-0042 pattern):
#   1. PlantUML (behavioral/detail: class, state, sequence) -> sibling SVGs,
#      via containerized PlantUML (podman) — no host install required.
#   2. LikeC4 structural views -> PNGs under docs/model/likec4/export/,
#      honoring committed .likec4/ layout snapshots.
# Idempotent: safe to re-run any time.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL_DIR="$ROOT/docs/model"
LIKEC4_DIR="$MODEL_DIR/likec4"
IMAGE="docker.io/plantuml/plantuml"
NODE22="$HOME/.local/node22/bin"

# --- PlantUML ---
if ! command -v podman >/dev/null 2>&1; then
    echo "ERROR: podman not found — required for containerized PlantUML" >&2
    exit 1
fi
echo "Rendering PlantUML diagrams under $MODEL_DIR ..."
# One container invocation so relative !include style.iuml resolves.
# --cgroup-manager=cgroupfs works around missing systemd session bus; a stray
# "oom" file may be dropped by crun — clean it up.
podman run --rm --cgroup-manager=cgroupfs -v "$MODEL_DIR:/data:Z" "$IMAGE" -tsvg /data
rm -f "$ROOT/oom"

# --- LikeC4 ---
if [ ! -x "$NODE22/node" ]; then
    echo "ERROR: Node >= 22.22.3 required at $NODE22 (likec4 constraint, lobotom-y ADR-0042)" >&2
    exit 1
fi
echo "Exporting LikeC4 views to $LIKEC4_DIR/export ..."
# env -u OPENROUTER_API_KEY: lobotom-y pilot finding 5.
( cd "$LIKEC4_DIR" && \
  env -u OPENROUTER_API_KEY PATH="$NODE22:$PATH" \
    npx likec4 export png -o ./export . )

echo "Done."
