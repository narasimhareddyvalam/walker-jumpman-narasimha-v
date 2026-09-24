# SUBMISSION

**Assignment:** Assignment 1 — Extend Walker Jumpman
**Student:** Narasimha Reddy Valam
**Project name:** `walker-jumpman-narasimha-v`
**GitHub repository:** https://github.com/narasimhareddyvalam/walker-jumpman-narasimha-v

| | |
|---|---|
| **Submitted commit SHA** | `<FINAL — the commit this note is submitted against>` |
| **Game-source revision shown in the film** | `c898a4b` |
| **Godot version** | 4.7.2.stable.official.ed1daf0bf |
| **Operating system** | macOS 26.5 (Darwin 25.6.0), Apple silicon |
| **Final film filename** | `claude-liam-walker-jumpman-walkthrough.mp4` |
| **Final film URL** | `<PENDING — course media storage>` |
| **Final film SHA-256** | `ad3cb5aaf265373eef34cd8a98ad3a3e454ec2e44e690ec1417fdd90221e779d` |

The film shows game source `c898a4b`. Any commit after that adds submission
documentation only and does not change the demonstrated game source; the diff
between them touches no file under `godot/`.

---

## Summary of my changes

**Character — the Runner.** The starter drew four stacked rectangles. The Runner
has a rounded head and a forward-leaning torso, and **its trail length is its
horizontal speed**, so standing still visibly puts it out. The trail also
reports gravity state: amber upright, cyan inverted. The 18×28 collider and
every value in `tuning.gd` are unchanged; inverted, the figure mirrors about the
collider's centre so the drawing stays inside the same box.

**Mechanic — the feather.** One pickup grants a permanent ability with a single
charge that returns 2.5 s after it is spent. Pressing `F` inverts gravity for
3 s; pressing it again cancels early at no refund. Falling upward out of the
level is as fatal as the pit.

**Gravity reversal is a sign flip, not a tuning change.** `tuning.gd` is
byte-identical to the starter's — `git diff 9387542..HEAD -- godot/features/player/tuning.gd`
is empty. Only the *direction* applied to gravity, the jump impulse and
`up_direction` changes. Measured: an inverted jump displaces 56.05 px where a
normal jump rises 56.00 px.

**Theme — INVERSION.** One law: *the world renders what you believe, not what is
there.* Hidden geometry collides but is never drawn. Phantom geometry is drawn
and holds nothing. Mirror ledges are solid only while inverted. Hidden spikes
are invisible and lethal; phantom spikes are fully drawn and harmless. A
bulkhead marked `DOOR LOCKED` is not solid. Inverting shows which is which, and
the palette flips with it — light is the comfortable lie, dark is what is
actually there.

Mechanically this is the difference between **two loops that already existed**
in the starter: one in `_ready()` building colliders from level data, one in
`_draw()` painting from it. Hidden geometry joins only the first; phantom joins
neither. No new node types, no physics change, no collision check removed.

**Level.** 960 → 4980 px, roughly five times the starter's route. Twenty-two
landings past the original section. The finish moved from x=916 into a tower
shaft above the floor that a normal jump cannot reach — asserted by
`finish-unreachable-without-feather`. The original section remains playable and
retry, pause and completion are the starter's.

**Presentation.** The starter drew hazards and the finish marker at hard-coded
coordinates while building their triggers from level data, so anything above
ground level rendered detached from what actually kills or completes. All
drawing is now data-driven. Platforms are building rooftops or service catwalks
depending on thickness; six collectible log fragments carry the story.

**Verification.** 70 mechanics checks and 9 keyboard checks, 0 failures. All 25
of the starter's original checks are retained and pass; none was deleted,
relaxed, or had an expected value changed. Every added check was written and
watched failing before the code that satisfies it existed.

---

## Known limitations

- **The human playtest is incomplete.** Narasimha played the build twice and
  found five real defects, all recorded and acted on. Three rows of the required
  table remain unverified by a person: the extended route reaching both new
  landings and the relocated finish, failure and recovery plus replay, and
  camera/presentation readability. `TEST-REPORT.md` §7 records this as
  unverified rather than claiming it. The automated route covers all three, but
  a scripted route is not a playtest.
- **Narration intelligibility is unconfirmed by ear.** The film's audio was
  verified present and at sane levels by measurement (mean −27 dB, max −4 dB, no
  silence over 3 s), not by listening.
- **One chapter.** Chapters Two to Five in `GDD.md` are design text only — no
  code, no level data, no assets. The Eye, the Mirror and the Clock do not exist.
- **No audio in the game.** It is silent; no sound was written and none is
  claimed.
- **No exported build.** Source only, run from the editor or the CLI.
- **The camera's forward-only lookahead** (`player.x + 100`) is the starter's and
  assumes rightward travel. Unchanged.
- **Open design questions**, recorded as predictions rather than resolved: does
  the Betrayal read as fair or cheap (P10), are the environmental clues legible
  at speed (P15, P16), is the recharge too slow over the spike corridor (P14).
- **The `evidence/` captures are scripted-input**, labelled as such throughout,
  and do not substitute for the human playtest.
- **Film media is not in the repository.** The 37 MB master exceeds GitHub's
  limit and lives in course media storage, identified above by filename and
  SHA-256. The beat sheet, coverage contract, capture notes, shot list, riffs,
  factcheck, prompts and input logs are all committed under `youtube/`.

---

## Fresh-copy verification

Run against a **clean clone from GitHub**, not the working folder, as the
assignment requires.

```bash
git clone https://github.com/narasimhareddyvalam/walker-jumpman-narasimha-v.git
cd walker-jumpman-narasimha-v
godot --headless --path godot --script res://tests/test_game.gd
godot --headless --path godot --script res://tests/test_keyboard.gd
```

| Check | Result |
|---|---|
| Clone succeeds, all required files present | ✅ README, CHANGE-BRIEF, TEST-REPORT, FRICTIONAL, SOURCES, GDD, SUBMISSION, full `godot/` project, full reel evidence |
| No caches, credentials or keys committed | ✅ no `.godot/`, `.env`, `credentials/`, `*.p12` |
| Nothing over 25 MB | ✅ largest tracked file is well under |
| Mechanics checks **from the clone** | ✅ **70 checks / 0 failures** |
| Keyboard checks **from the clone** | ✅ **9 checks / 0 failures** |
| **The film depicts this source** | ✅ see below |

### The film depicts the submitted source, proven rather than asserted

`coverage.json` records a `build_id` — a SHA-256 over the sorted per-file
hashes of every game source file — captured at the moment the footage was
recorded. Recomputing that same hash from the fresh clone gives:

```
clone   f17c2a5485f3ee0dd73803dc711c59b5dbf2390aa1e53ece178c4da0a7617f72
film    f17c2a5485f3ee0dd73803dc711c59b5dbf2390aa1e53ece178c4da0a7617f72
```

Identical. The source a reviewer downloads is byte-for-byte the source the film
shows. The method is in `youtube/.../CAPTURE.md` and can be re-run.

### Source ZIP

Produced with `git archive` from the verified clone, so it contains exactly the
tracked tree and nothing else — no `.git`, no caches, no credentials, no media.

| | |
|---|---|
| Filename | `walker-jumpman-narasimha-v-fc5d2ac.zip` |
| Size | 3.0 MB · 139 files |
| SHA-256 | `39afae7dd146f3192dc437afb3e5261a9641c26f13e342d3eefb05b44b20abdd` |

> The ZIP above is built from commit `fc5d2ac`. If a later commit adds the film
> URL, rebuild the ZIP from that commit and use its SHA in the Canvas note —
> the final submitted SHA cannot be embedded in the commit it names.

---

## How to run it

```bash
git clone https://github.com/narasimhareddyvalam/walker-jumpman-narasimha-v.git
cd walker-jumpman-narasimha-v
godot --path godot
```

Requires Godot 4.7.x. No plugins, no .NET, no downloaded assets.

**Controls:** `A`/`D` move · `Space` jump · **`F` reverse gravity** · `R` retry ·
`Esc` pause · `Enter` confirm · `M` menu. `F` is the only control added; every
other binding is the starter's.

**Checks:**

```bash
godot --headless --path godot --script res://tests/test_game.gd      # 70 checks
godot --headless --path godot --script res://tests/test_keyboard.gd  # 9 checks
```

---

## Documents

| File | What it holds |
|---|---|
| `README.md` | project, starter credit, run instructions, controls, changes, limitations |
| `CHANGE-BRIEF.md` | predictions written before implementation, five revisions appended — including one that was wrong |
| `TEST-REPORT.md` | baseline, automated results, the human playtest, and what remains unverified |
| `FRICTIONAL.md` | what was actually tried, what broke, what was learned |
| `SOURCES.md` | starter credit, tools, and the human/AI split |
| `GDD.md` | the full design, separating what is built from what is not |
| `youtube/.../` | beat sheet, coverage contract, capture notes, shot list, riffs, factcheck, prompts, QC report |

---

## Credit

Extends **[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**
by Nik Bear Brown, at commit `9387542`. That commit is the first in this
repository, so the diff is exact: `git diff 9387542..HEAD --stat`.

Human and AI contributions are itemised in `SOURCES.md`, including what the AI
proposed that was rejected and what it got wrong.
