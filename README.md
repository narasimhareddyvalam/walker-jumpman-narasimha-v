# THE WORLD IS FALLING — Chapter One: The Fall

**Project name:** `walker-jumpman-narasimha-v`
**Student:** Narasimha Reddy Valam · CSYE 7270
**Engine:** Godot **4.7.2.stable.official.ed1daf0bf** · GDScript, Compatibility/OpenGL renderer
**Platform built and tested on:** macOS 26.5 (Darwin 25.6.0), Apple Silicon

---

## Starter credit

This is an **extension of**, not a replacement for,
**[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**
by Nik Bear Brown, at commit **`9387542`**.

That commit is the first commit in this repository, so every later commit is
mine and the diff is exact:

```bash
git diff 9387542..HEAD --stat
```

Full attribution, including what was kept from the starter and what I added,
is in [SOURCES.md](SOURCES.md).

---

## Run it

Requires Godot 4.7.x. No .NET runtime, no plugins, no downloaded assets.

```bash
git clone <this repository>
cd walker-jumpman-narasimha-v
godot --path godot
```

Or open `godot/project.godot` in the Godot editor and press Play.
On macOS, double-clicking [`walker-jumpman.command`](walker-jumpman.command)
also works when Godot is installed in `/Applications`.

### Controls

| Key | Action |
|---|---|
| **A / D** or **← / →** | move |
| **Space** | jump (fixed height, no double jump) |
| **F** or **Shift** | **spend a Feather charge — reverse gravity.** Press again to flip back early |
| **R** | retry |
| **Esc / P** | pause · **Enter** confirm · **M** menu |

Retries are unlimited. `F` is the only control added to the starter; every other
binding is the starter's, unchanged.

---

## What this is

The laws of physics are failing. Debris drifts upward, the skyline hangs the
wrong way, and the ground stops holding. You find an object that should not
exist and learn what it does by needing it.

**The chapter, in order:** the familiar route → the ground begins dissolving →
a fork between a quick gantry and a longer collapsing deck → **the Feather** →
a gap that can only be crossed by falling upward → an inverted run along the
ceiling → an observatory door that admits only those who can fall upward → a
reveal, and two questions it does not answer.

The full design, including the four chapters that are **designed but not built**,
is in [GDD.md](GDD.md).

---

## What I changed

### Character — the Runner
The starter drew four stacked rectangles. The Runner has a rounded head and a
forward-leaning parallelogram torso, and **its trail length is its speed** — so
standing still visibly extinguishes it. The trail also **reports gravity state**:
warm while normal, cold while inverted. That is the only readout of the Feather's
effect; there is no UI for it.

Movement parameters and the 18×28 collider are unchanged. Inverted, the figure
is mirrored about the collider's centre line, so the drawing stays inside the
same box.

### Mechanic — the Feather
Scarce gravity-reversal charges. Two Feathers grant three charges; two reversals
are mandatory and one is an optional shortcut, so spending the shortcut leaves
exactly enough. Cancelling early does not refund, which makes *when you flip
back* a skill. Falling upward out of the level is as fatal as the pit.

**Gravity reversal does not change the jump.** Every value in `tuning.gd` is
byte-identical; only the **sign** applied to gravity, the jump impulse and
`up_direction` flips. Measured: an inverted jump displaces **56.05 px** where a
normal jump rises **56.00 px**.

### Level — roughly three times longer
Eight new landings past the original section, crumbling ledges, a route fork, an
inverted ceiling run, and the finish relocated into a shaft that cannot be
entered without the mechanic. All geometry was sized against a **measured** jump
envelope (`godot/tests/probe_reach.gd`), not arithmetic. No jump strength was
changed to make anything reachable.

### Presentation
The starter drew hazards and the finish marker at hard-coded coordinates while
building their triggers from level data — so anything above ground level
rendered detached from the thing that actually kills or completes. All drawing
is now data-driven. The cream-and-teal palette was replaced with a dark facility
palette, parallax strata, drifting debris and a minimal HUD.

---

## Verification

**43 mechanics checks and 9 keyboard checks, 0 failures.** All 25 of the
starter's original mechanics checks are retained and still pass; none were
deleted, relaxed, or had an expected value changed.

```bash
godot --headless --path godot --script res://tests/test_game.gd
godot --headless --path godot --script res://tests/test_keyboard.gd
godot --path godot --fixed-fps 60 --script res://tests/capture_game.gd
godot --path godot --fixed-fps 60 --script res://tests/capture_extension.gd
godot --headless --path godot --script res://tests/probe_reach.gd
godot --headless --path godot --script res://tests/probe_gravity.gd
```

> On macOS the windowed capture scripts need `--fixed-fps 60`; without it the
> background window is throttled to roughly four ticks per second.

Predictions made **before** implementation, and what actually happened —
including a prediction that was **wrong** — are in
[CHANGE-BRIEF.md](CHANGE-BRIEF.md).
Human playtest results are in [TEST-REPORT.md](TEST-REPORT.md).
The honest working log is in [FRICTIONAL.md](FRICTIONAL.md).

---

## Known limitations

- **One chapter.** Chapters Two to Five in [GDD.md](GDD.md) are design only —
  no code, no level data, no assets. The Eye, Clock and Mirror do not exist.
- **No audio.** The game is silent.
- **No export build.** Source only; run it from the editor or the CLI.
- The camera's forward-only lookahead (`player.x + 100`) is the starter's and
  was not changed; it assumes rightward travel.
- The `evidence/extension/` and `evidence/character/` captures are produced by a
  **scripted input route**, not by a human playing. They are labelled as such
  and do not substitute for the playtest in `TEST-REPORT.md`.
- Charge-economy tuning, the ceiling run's readability, and whether the
  cyan/amber trail is a sufficient gravity cue are open questions recorded as
  P7–P9 in `CHANGE-BRIEF.md`.

---

## Final film

<!-- TODO before submission: replace with the real values. Do not submit with placeholders. -->
**Not yet produced.** When rendered, this section will carry the film's URL,
exact filename and SHA-256 checksum, and the game-source commit it depicts.
Media files are kept out of this repository per the assignment.

---

## Documents

| File | What it holds |
|---|---|
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) | predictions written before implementation, and findings appended after |
| [GDD.md](GDD.md) | the full design; clearly separates built from unbuilt |
| [TEST-REPORT.md](TEST-REPORT.md) | baseline, automated results, and the human playtest |
| [FRICTIONAL.md](FRICTIONAL.md) | what was actually tried, what broke, what was learned |
| [SOURCES.md](SOURCES.md) | starter credit, assets, tools, and human vs AI contributions |
