#!/usr/bin/env bash
#
# monitor.sh - samples the total number of processes on the system once per
# second and writes the result to a CSV file. Start this BEFORE launching
# the fork bomb so the log captures the baseline, the spike, and the plateau.
#
# Usage:
#   bash monitor.sh [DURATION_SECONDS] [LOG_FILE]
#
# Defaults: 120 seconds, process_log.csv
#
# Output CSV columns:
#   time       - seconds elapsed since the monitor started
#   processes  - total processes on the system at that moment (ps -e)

DURATION="${1:-120}"
LOG_FILE="${2:-process_log.csv}"

# Reset the log and write the header.
: > "$LOG_FILE"
echo "time,processes" >> "$LOG_FILE"

START=$(date +%s)

for _ in $(seq 0 "$DURATION"); do
    NOW=$(date +%s)
    ELAPSED=$((NOW - START))
    # Count every process on the system (headerless ps, one line each).
    PROCS=$(ps -e --no-headers | wc -l)
    echo "$ELAPSED,$PROCS" >> "$LOG_FILE"
    sleep 1
done

echo "[monitor] done - $((DURATION + 1)) samples written to $LOG_FILE"
