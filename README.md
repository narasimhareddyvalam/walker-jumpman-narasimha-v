# THE WORLD IS FALLING — Chapter One: The Fall

> **The world shows you what you expect, not what is there.**

A dark side-scrolling puzzle-platformer built in Godot, where the central
mechanic is not a jump but a question: *is what I am looking at real?*

Gravity has failed. Debris falls upward past a dead research site, and the
player is the one person who stayed behind instead of running. They find a
**feather** that falls up — and while they hold it, so can they.

What makes the chapter work is what that ability is *for*. This world lies.

- A floor can be **real but never drawn** — you walk out over an apparent chasm
  and something catches you.
- A floor can be **drawn but not real** — it looks like solid ground and holds
  nothing at all.
- A platform can exist **only while you are upside down**.
- Spikes can be **invisible and lethal**, or **fully rendered and harmless**.
- A bulkhead marked `DOOR LOCKED` can be something you walk straight through.

Every one of those has a rule behind it rather than being a trick, and there is
always a way to check: **turn gravity upside down.** Inverted, the world stops
flattering you and shows what is actually there.

That is also why the palette flips. Upright, the site is pale institutional
daylight — the comfortable lie. Inverted, it is near black — what is really
there. Sixteen colour values change together, the interface included, so the
screen can never disagree with which way up the player is.

The chapter teaches this in three beats and then turns its own lesson over. The
**Void Gap** catches a player who keeps walking. The **Betrayal**, a gap that
looks identical, does not — because the lesson was never *hidden floors exist*,
it was *check instead of assume*. And the way out is a tower whose door only
opens for someone who can fall upward.

**Player name:** the Runner — a leaning figure whose trail length *is* its
horizontal speed, so the character puts itself out when it stops moving, and
whose trail colour reports which way gravity is currently pulling.

---

**Project:** `walker-jumpman-narasimha-v` · **Author:** Narasimha Reddy Valam
**Engine:** Godot **4.7.2.stable.official.ed1daf0bf** · GDScript, Compatibility/OpenGL
**Built and tested on:** macOS 26.5 (Darwin 25.6.0), Apple Silicon
**Verification:** 70 mechanics checks · 9 keyboard checks · 0 failures

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
| **F** or **Shift** | **reverse gravity** — you fall upward. Press again to flip back early. Recharges in 2.5 s |
| **R** | retry |
| **Esc / P** | pause · **Enter** confirm · **M** menu |

Retries are unlimited. `F` is the only control added to the starter; every other
binding is the starter's, unchanged.

---

## The chapter, in order

The familiar route → the ground begins breaking → a fork between two roads →
**the feather** → ceiling runs → a chasm that catches you → the same chasm that
does not → a platform that isn't there → a locked door that isn't locked → a
lethal floor → a stretch marked `SAFE` that isn't → the tower, which only admits
those who can fall upward.

It ends on the line the story has been building to, and on one question it
deliberately refuses to answer.

The full design — including the four chapters that are **designed but not
built**, the environmental visual language, and the story in detail — is in
[GDD.md](GDD.md).

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

### Mechanic — the feather
One pickup grants the ability permanently; before it, `F` does nothing. You hold
exactly **one charge**, it never stacks, and it returns **2.5 seconds** after you
spend it. A reversal lasts 3 seconds and then restores itself. Cancelling early
costs the charge anyway, so *when you flip back* is the skill. Falling upward out
of the level is as fatal as the pit.

An earlier build rationed charges across three pickups. That was wrong, and I
had predicted why in P12: making inspection expensive, in a chapter whose entire
subject is checking what is real, taught players to avoid the verb the game is
about. The recharge is what makes every illusion below solvable rather than a
gamble.

**Gravity reversal does not change the jump.** Every value in `tuning.gd` is
byte-identical; only the **sign** applied to gravity, the jump impulse and
`up_direction` flips. Measured: an inverted jump displaces **56.05 px** where a
normal jump rises **56.00 px**.

### Level — 960 → 4980 px, roughly five times longer
Twenty-two new landings past the original section, crumbling ledges, a fork, an
inverted ceiling run, and the finish relocated into a shaft that cannot be
entered without the mechanic. All geometry was sized against a **measured** jump
envelope (`godot/tests/probe_reach.gd`), not arithmetic. No jump strength was
changed to make anything reachable.

### Theme — INVERSION
One law governs the chapter: **the world renders what you believe, not what is
there.** Upright vision draws *phantom* geometry and withholds *hidden*
geometry; inverted vision does the exact reverse. Collision is never consulted
by either, so the player can always check by flipping — which makes every
surprise a deduction rather than a trick.

Seven beats teach it. The **Void Gap** is an apparent chasm with a hidden floor
that catches anyone who keeps walking. The **Betrayal** is a visually identical
gap with nothing in it — the lesson you just learned is the wrong lesson. The
**Phantom** is a platform drawn exactly like real ground that holds nothing. A
**locked door** is a wall you walk straight through. **Phantom spikes** are fully
drawn and harmless; **hidden spikes** are invisible and lethal. A **mirror ledge**
is solid only while inverted.

A sign over the Betrayal reads `THIS GAP IS EMPTY / Go up instead.`, and the
ceiling route past it is visible from the approach: the punishment is for
assuming, never for failing to read minds.

Mechanically this is the difference between two loops that already existed —
one building colliders from level data, one drawing from it. Hidden geometry
joins only the first; phantom geometry joins neither; mirror geometry joins both
but only while gravity is reversed.

Story arrives as **six collectible log fragments**, one line each, written in
plain words and escalating to the chapter's turn: you built this.

### The environment tells you which way up to be

Objects carry an allegiance to one gravity or the other, readable from where
they rest. A chair standing on a floor fell normally. A chair pressed against
the underside of a gantry could only have got there under inverted gravity — so
a space full of those is saying *come in here inverted*. Flip, and the meaning
reverses: the objects that looked impossible read as ordinary, and the upright
ones start looking wrong.

Nineteen props cover all seven ceilings the route uses. Two hang at the mirror
ledge's height, where nothing is drawn while upright — a chair and a heap of
rubble resting against apparently nothing, which is the only warning that an
invisible platform is above.

The worded `F` prompt survives on the **first** reversal only. That is a
deliberate compromise: the first playtest ended with the player unable to find
`F` at all, so the verb is taught once on safe ground and the environment
carries it after that. A stricter version with no prompts is designed and not
built — see [GDD.md](GDD.md).

### Presentation
The starter drew hazards and the finish marker at hard-coded coordinates while
building their triggers from level data — so anything above ground level
rendered detached from the thing that actually kills or completes. All drawing
is now data-driven.

The cream-and-teal palette is gone. In its place are **two** schemes chosen by
gravity: upright, the world is pale daylight — the comfortable
lie; inverted, it is near-black — what is actually there. Sixteen colour keys
flip together, the HUD included, so the interface can never contradict which
world the player is standing in. Parallax strata, drifting debris and a minimal
HUD throughout.

---

## Credit

Built on the **[walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**
starter by Nik Bear Brown, at commit **`9387542`** — a short first level with a
few gaps, a spike, a finish flag, and a character drawn as four stacked
rectangles.

That commit is the first in this repository, so the diff between it and HEAD is
exactly my work and can be read in one command:

```bash
git diff 9387542..HEAD --stat
```

What was kept, what was added, and the split between my decisions and AI
implementation is itemised in [SOURCES.md](SOURCES.md).

---

## Verification

**70 mechanics checks and 9 keyboard checks, 0 failures**, verified again from a fresh clone of this repository. All 25 of the
starter's original mechanics checks are retained and still pass; none were
deleted, relaxed, or had an expected value changed. Every check added for the
Feather and for INVERSION was written and **watched failing** before the code
that satisfies it existed.

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

**THE WORLD IS FALLING — Extending Walker Jumpman**
Made with the Brutalist `godot-waikthrough` skill, walker modifier.

| | |
|---|---|
| Filename | `narasimha-reddy-valam-walker-jumpman-walkthrough.mp4` |
| Format | 3840 × 2160 · H.264 · 30 fps · AAC stereo |
| Runtime | 5:11 (311.3 s) |
| SHA-256 | `ad3cb5aaf265373eef34cd8a98ad3a3e454ec2e44e690ec1417fdd90221e779d` |
| Game source shown | commit `c898a4b` |
| URL | **[Watch on Northeastern OneDrive](https://northeastern-my.sharepoint.com/personal/valam_n_northeastern_edu/_layouts/15/stream.aspx?id=%2Fpersonal%2Fvalam_n_northeastern_edu%2FDocuments%2FVirtual%20Environments%2Fnarasimha-reddy-valam-walker-jumpman-walkthrough%2Emp4)** |

The 34 MB master is kept out of this repository and hosted on Northeastern OneDrive. Everything
else about the film is committed under
[`youtube/claude-liam-walker-jumpman-walkthrough/`](youtube/claude-liam-walker-jumpman-walkthrough/):
the beat sheet with the full narration, the `coverage.json` evidence contract,
capture notes, shot list, riffs, a factcheck indexing every spoken claim to the
command or test that proves it, and the QC report.

All gameplay in the film is **native 3840 × 2160 captured from the running
game** by an input-only driver that presses keys and never teleports, forces
completion, or disables collision. The input logs are committed alongside. The
opening prompt card is **labelled on screen as a reconstruction**, because it is
one.

---

## Documents

| File | What it holds |
|---|---|
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) | predictions written before implementation, and findings appended after |
| [GDD.md](GDD.md) | the full design; clearly separates built from unbuilt |
| [TEST-REPORT.md](TEST-REPORT.md) | baseline, automated results, and the human playtest |
| [FRICTIONAL.md](FRICTIONAL.md) | what was actually tried, what broke, what was learned |
| [SOURCES.md](SOURCES.md) | starter credit, assets, tools, and human vs AI contributions |
