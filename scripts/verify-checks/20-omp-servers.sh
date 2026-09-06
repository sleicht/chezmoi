# shellcheck shell=bash
# =============================================================================
# 20-omp-servers.sh — omp helper servers (hindsight + searxng) health
# =============================================================================
# Sourced by verify-configs.sh; do not execute directly.
# Returns 77 when the stack is not deployed or not running (client
# machines, intentionally stopped). Fails when the stack runs but an
# endpoint is unhealthy — e.g. searxng missing the json format.
# =============================================================================

OMP_SERVERS_DIR="$HOME/.config/omp-servers"

[ -f "$OMP_SERVERS_DIR/docker-compose.yml" ] || return 77
command -v docker >/dev/null 2>&1 || return 77
docker compose version >/dev/null 2>&1 || return 77
running_services=$(docker compose -f "$OMP_SERVERS_DIR/docker-compose.yml" ps --status running --services) || return 1
[ -n "$running_services" ] || return 77

curl -fsm2 http://localhost:8888/health >/dev/null || return 1
curl -fsm2 'http://localhost:3939/search?q=ping&format=json' >/dev/null || return 1

return 0
