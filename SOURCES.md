# SOURCES

**Project:** walker-jumpman-narasimha-v — *THE WORLD IS FALLING, Chapter One: The Fall*
**Student:** Narasimha Reddy Valam · CSYE 7270

---

## The starter

This project is an **extension of**, not a replacement for:

> **[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**
> by Nik Bear Brown, commit `9387542` — *"Add Walker Jumpman playable First Steps prototype"*

That commit is the first commit in this repository's history, so the starter's
authorship is preserved in the log rather than asserted in prose. Everything I
added can be listed exactly:

```bash
git diff 9387542..HEAD --stat
```

The repository was cloned from the instructor's public repo and its `origin`
remote was removed immediately, so no work was ever done against the
instructor's source.

### What came from the starter and was kept

- The Godot 4 project skeleton, `main.tscn`, and the session/player/HUD split.
- `tuning.gd` — **every value unchanged**: speed 160, acceleration 1280,
  deceleration 1920, jump velocity −320, gravity 960, terminal 480, coyote 6,
  buffer 6.
- The 18×28 collider, its offset, and the collision layers.
- Coyote time, jump buffering, retry/pause/completion, and the focus-loss pause.
- The contact-settle fix that prevents a phantom second death after respawn.
- The original level's first two zones, still playable on their original route.
- `test_game.gd`'s 25 mechanics checks and `test_keyboard.gd`'s 9 keyboard
  checks — all retained, none weakened, all still passing.
- `capture_game.gd`'s approach of saving the real rendered viewport.

### What I added

- The Runner character (`player.gd::_draw`), replacing the starter's four
  stacked rectangles.
- Gravity reversal as a **sign flip** (`gravity_sign`) — no tuning value altered.
- The feather: one pickup granting a permanent ability, a single recharging
  charge, the `F` control, the reversal window, and the lethal sky bound.
- Crumbling ledges: contact-triggered collapse, debris, and retry reset — and
  ceilings that give way under an inverted player.
- **The INVERSION rule and everything built on it:** hidden geometry, phantom
  geometry, mirror ledges, hidden and phantom hazards, and a phantom wall used
  as a door that is not locked.
- Reversal pads and the `PRESS F` affordance, added after a playtest showed the
  chapter depended on a key it never taught.
- Six collectible story-log fragments and the ability-unlock card.
- Chapter One's level data, roughly five times the original length.
- Data-driven drawing to fix hazards and the finish marker rendering at
  hard-coded coordinates, and an 8px spike pitch replacing a divide-by-three
  that only tiled correctly at the starter's hazard width.
- **Two palettes chosen by gravity** — light upright, dark inverted — plus
  building-rooftop and service-catwalk platform art, parallax strata, tumbling
  debris and a minimal HUD.
- 41 new automated checks, the extended route fixture, and four new harnesses:
  `probe_reach.gd`, `probe_gravity.gd`, `capture_character.gd`,
  `capture_extension.gd`.

---

## Assets

**No imported, purchased, downloaded or AI-generated art, audio or fonts are
used anywhere in this project.**

Every visual is original vector drawing executed in Godot's `_draw()` with
`draw_rect`, `draw_circle`, `draw_line`, `draw_colored_polygon` and
`draw_polyline`. Text uses `ThemeDB.fallback_font`, Godot's built-in default.
There is no audio.

No paid service, no API credits, and no asset-generation service was used.

---

## Tools

| Tool | Used for |
|---|---|
| Godot 4.7.2.stable.official.ed1daf0bf | engine, editor, headless test runs, viewport capture |
| Claude Code (Opus 5) | pair programming, measurement harnesses, documentation drafting |
| git / GitHub CLI | version control |
| macOS 26.5 (Darwin 25.6.0), Apple Silicon | development machine |

---

## Human and AI contributions

The assignment requires this to be specific, so it is.

### What I decided

- **To reject a costume-swap character.** Claude's first framing was a set of
  themed avatars; I pushed back and asked for a character built out of the
  mechanic instead, which produced the speed-reporting trail.
- **To reject a branching-path level.** Claude noted two classmates had already
  published branching extensions. I chose crumbling ledges instead so the
  section would *feel* different rather than merely be longer.
- **The whole premise.** THE WORLD IS FALLING, the failing-gravity world, the
  Feather as an anomalous technological object rather than a magic item,
  environmental storytelling over dialogue, the tower, the door line
  *"ONLY THOSE WHO CAN FALL UPWARD MAY ENTER"*, and the chapter ending on an
  unanswered question.
- **That the Feather must be scarce** and that cancelling it early must not
  refund, so the mechanic creates decisions instead of being a free ability.
- **That the game must stop looking like the instructor's template**, which
  drove the dark palette and the minimal HUD.
- **Scope.** I specified one polished chapter rather than five levels, and that
  the rest be documented as design instead of half-built.
- **That the record must show what was predicted wrongly**, not only what was
  predicted correctly.

### What I rejected or overruled

- **A 3D version with selectable camera POV.** I asked for it; Claude showed
  that the pixel-space tuning could not survive the unit change and that the
  rubric awards nothing for 3D. I accepted that and chose parallax depth in 2D.
- **An earlier "inheritance" storyline** Claude pitched (a level about someone
  who went before you). I judged it too close to an ordinary jumper game and
  asked for something that changed how the game *plays*.
- **Committing everything in three commits.** I asked for finer-grained history.

### What Claude did

- Read the starter and identified the hard-coded drawing coordinates, the
  camera's forward-only lookahead, and the HUD's literal `852` divisor before
  any edit.
- Wrote `probe_reach.gd`, which measured the real jump envelope (peak rise
  56.00 px) so level geometry was sized against evidence rather than arithmetic.
- Implemented the character drawing, the crumbling-ledge state machine, gravity
  reversal as a sign flip, the Feather, the level data, the dark visual pass and
  the minimal HUD.
- Wrote the automated checks and the capture harnesses, and fixed its own faulty
  tests when they failed for the wrong reasons.
- Drafted `CHANGE-BRIEF.md`, `GDD.md`, this file, `TEST-REPORT.md` and
  `README.md` from real run output.

### What Claude got wrong, and how it was caught

Recorded because the assignment asks for honesty about verification, and because
these were caught by checking rather than by inspection:

- Predicted (P3) that the route fixture would break and need a larger tick
  budget. It did not. The prediction is left in the record, marked wrong.
- Wrote a character preview harness that ran the player into a step, so the
  speed trail correctly showed nothing and looked like a drawing bug.
- Wrote a capture harness whose PNG write outlasted the ~34-tick retry window,
  so a real death went unobserved. **The original intermittent cause was never
  fully isolated**; the check was made robust instead.
- Wrote two crumble checks that sampled `is_on_floor()` before the player had
  begun to fall, so they failed for a reason that had nothing to do with the
  game.
- Built the tower as an open ledge, so the automated route drifted past
  the doorway while rising and died in the sky. The room was enclosed.

### What has not been verified by a human yet

The human playtest and its findings are recorded in `TEST-REPORT.md`. Anything
in this project that has only been exercised by a scripted input route is
labelled as such there and in the film. A scripted route is not a playtest.

---

## Collaborators

None. No other person contributed code, art, design or playtesting to this
submission. If a playtester other than the author is recorded in
`TEST-REPORT.md`, they are named there.
