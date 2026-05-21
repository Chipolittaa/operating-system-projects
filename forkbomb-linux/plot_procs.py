#!/usr/bin/env python3
"""
plot_procs.py - builds a "time vs. process count" line chart from the CSV
that monitor.sh produces.

Usage:
    python3 plot_procs.py [CSV_FILE]

Default CSV_FILE is process_log.csv. The chart is saved as
processes_graph.png in the current directory.
"""

import csv
import os
import sys

import matplotlib.pyplot as plt

CSV_FILE = sys.argv[1] if len(sys.argv) > 1 else "process_log.csv"

if not os.path.exists(CSV_FILE):
    print(f"File not found: {CSV_FILE}")
    print("Run `ls -l` and check the CSV file name.")
    sys.exit(1)

times = []
procs = []

with open(CSV_FILE, newline="") as f:
    reader = csv.reader(f)
    next(reader, None)  # skip the header row
    for row in reader:
        if not row:
            continue
        # Expected format: time,processes
        try:
            t = float(row[0])
            p = int(row[1])
        except (ValueError, IndexError):
            # Fall back to cleaning up rows with stray spaces.
            parts = ",".join(row).strip().split(",")
            if len(parts) >= 2:
                t = float(parts[0])
                p = int(parts[1])
            else:
                continue
        times.append(t)
        procs.append(p)

if not times:
    print("No data found in the CSV (check its contents).")
    sys.exit(1)

plt.figure(figsize=(10, 5))
plt.plot(times, procs, marker="o", markersize=3, linewidth=1.5)
plt.title("Number of processes on the system")
plt.xlabel("Time (s)")
plt.ylabel("Process count")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()

out = "processes_graph.png"
plt.savefig(out, dpi=150)
print(f"Done. Chart saved to {out}")

# Show the window too, if a display is available.
try:
    plt.show()
except Exception:
    pass
