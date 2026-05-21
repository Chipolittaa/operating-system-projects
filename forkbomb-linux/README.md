# Fork Bomb on Linux

A small, hands-on experiment exploring how the Linux kernel reacts to a **fork
bomb** — one of the simplest denial-of-service attacks, which tries to exhaust
the system's process table by spawning processes exponentially.

This is a personal project: I wanted to measure, with my own data, what
actually happens to a Linux machine when a fork bomb is unleashed on it, and
which kernel defenses keep the attack from being fatal.

## What a fork bomb is

A fork bomb is a process that repeatedly replicates itself. Each new process
spawns more processes, so the count doubles again and again until the system
can no longer create new ones — either the per-user process limit is reached
or memory runs out. The result is a self-inflicted denial of service: the
machine becomes unresponsive because every resource is spent just managing the
explosion of processes.

The payload used here is the classic bash one-liner:

```bash
:(){ :|: &};:
```

Reading it piece by piece:

| Fragment | Meaning |
|----------|---------|
| `:()`     | define a function whose name is the character `:` |
| `{ ... }` | the function body |
| `:\|:`    | call `:`, and pipe its output into another call of `:` |
| `&`       | run that pipeline in the background |
| `;:`      | once the function is defined, call it once to start the chain |

Every call spawns two more, so the number of processes grows exponentially.

## Experiment setup

The test ran inside a disposable virtual machine so the host stayed safe:

- **OS:** Ubuntu 24.04.3 LTS
- **CPU:** 2 cores
- **RAM:** 4096 MB
- **Disk:** 30 GB
- A clean VM snapshot (`clean-before-experiment`) was taken first, so the
  machine could be reverted to a healthy state afterwards.

The method is straightforward: start a monitor that records the total number
of processes once per second, launch the fork bomb, and then plot the log.

## Files

| File | Purpose |
|------|---------|
| `forkbomb.sh` | The fork bomb payload — the `:(){ :\|: &};:` one-liner, guarded behind a `--run` flag so it cannot fire by accident |
| `monitor.sh` | Samples the total process count once per second and writes it to a CSV |
| `plot_procs.py` | Builds a time-vs-process-count chart from that CSV |
| `process-count-graph.png` | The chart produced by my run |
| `ANALYSIS.md` | What the measurements show and why |

## How to reproduce (safely)

> **Warning.** A fork bomb is a real denial-of-service payload. Run this
> **only** inside a throwaway virtual machine that you can hard-reset. Never
> run it on a host OS, a machine you care about, or shared infrastructure.

1. **Snapshot the VM** so you can revert it afterwards.
2. **Cap the blast radius** by setting a per-user process limit in the shell
   you will use:
   ```bash
   ulimit -u 5000
   ```
3. **Start the monitor** in the background:
   ```bash
   bash monitor.sh 120 process_log.csv &
   ```
4. **Launch the fork bomb:**
   ```bash
   bash forkbomb.sh --run
   ```
5. **Recover.** Once the monitor finishes (or the machine becomes unusable),
   revert the VM to the clean snapshot.
6. **Plot the result** (needs Python 3 and `matplotlib`):
   ```bash
   pip install matplotlib
   python3 plot_procs.py process_log.csv
   ```
   This writes `processes_graph.png`.

## Stopping a running fork bomb

Once a fork bomb is running it is very hard to stop, because killing one
process just frees a slot for another. The reliable option in a VM is to
**revert the snapshot**. If you want to try to recover the running session,
suspending every user process at once can buy time:

```bash
killall -STOP -u "$USER"
```

This is exactly why running it only in a disposable VM matters.

## Findings in short

The process count sat at a baseline of roughly 300, then shot up almost
vertically and flattened out around 5000, oscillating there as processes were
created and died at the same rate. The system slowed down noticeably but never
fully crashed — Linux's process limits and the OOM killer capped the damage,
and the machine stayed controllable. The full breakdown is in
[`ANALYSIS.md`](ANALYSIS.md).
