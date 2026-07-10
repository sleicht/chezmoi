# shellcheck shell=bash
# =============================================================================
# 20-omp-servers.sh — omp helper servers (hindsight + searxng) health
# =============================================================================
# Sourced by verify-configs.sh; do not execute directly.
# Passes silently when the stack is not deployed or not running (client
# machines, intentionally stopped). Fails when the stack runs but an
# endpoint is unhealthy — e.g. searxng missing the json format.
# =============================================================================

OMP_SERVERS_DIR="$HOME/.config/omp-servers"

[ -f "$OMP_SERVERS_DIR/docker-compose.yml" ] || return 0
command -v docker >/dev/null 2>&1 || return 0
docker compose -f "$OMP_SERVERS_DIR/docker-compose.yml" ps --status running 2>/dev/null | grep -q hindsight || return 0

curl -fsm2 http://localhost:8888/health >/dev/null || return 1
curl -fsm2 'http://localhost:3939/search?q=ping&format=json' >/dev/null || return 1

return 0
