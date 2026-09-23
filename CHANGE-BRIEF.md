# CHANGE-BRIEF — walker-jumpman-narasimha-v

**Author:** Narasimha Reddy Valam · **Assisted by:** Claude Code (Opus 5)
**Written:** 2026-09-23, **before** any source edit. Original predictions are never rewritten;
later findings are appended under "Revisions" with their own dates.

**Starter:** [nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman) @ `9387542`
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf · macOS 26.5 (Darwin 25.6.0), Apple Silicon

---

## 0. Baseline measured before changing anything

Everything below is a prediction *against* this recorded starting point.

| Measurement | Value |
|---|---|
| `test_game.gd` | **25 checks / 0 failures** |
| `test_keyboard.gd` | **9 checks / 0 failures** |
| `complete-real-route` | COMPLETE, 0 deaths, **325 ticks**, 5 jump marks |
| Observed jump rise | 56.07 px |
| Largest auto-retry | 34 physics ticks (~0.567 s) |
| Baseline screenshots | byte-identical to the starter's committed PNGs |

Derived from `tuning.gd` and confirmed against the engine, these govern every geometry decision:

- **Max jump rise ≈ 56 px** (summing discrete 60 Hz ticks; matches the measured 56.07)
- **Max horizontal reach ≈ 107 px** on a flat jump at full speed
- **A jump that must also rise 32 px has only ≈ 69 px of horizontal reach** — this is the number
  most likely to make a good-looking staircase physically impossible.

---

## 1. Character concept

**The Runner** — a character whose visible state is a readout of their own speed.

The starter's player is four stacked rectangles (`player.gd:70-80`): a navy body, a blue shirt,
an orange belt, and a one-pixel eye that flips with `facing`. It is a box.

Replacing it with a *different* box would satisfy nobody. The new character is built from the
level's core demand — **you cannot stand still** — so that the avatar reports on the mechanic:

| Feature | Distinguishes it from the starter how |
|---|---|
| **Speed trail** — a `draw_polyline` behind the character whose length scales with `abs(velocity.x)` | The starter has no element that responds to velocity at all. Standing still visibly extinguishes the character; sprinting streams it. |
| **Forward-leaning parallelogram torso** | Breaks the rectangle language entirely. Reads as momentum even in a still frame. |
| **Rounded head** (`draw_circle`), offset toward `facing` | The starter is 100% axis-aligned rectangles. A curve is an immediate silhouette change. |
| **Amber accent `#ef875f`** on a deep navy body | One warm point in a pale world. |

**Deliberate exclusion:** the trail is **not** red. `#d24e42` is the spike colour — in this world red
means death, and putting it on the player would corrupt the hazard language.

**Collider discipline:** the **body stays strictly inside the 18×28 collider**; only the **trail**
extends past it. Players read trailing soft elements as non-solid, but a rigid body part overhanging
the hitbox reads as a bug. Movement parameters and the collider are unchanged.

## 2. New level section and the decision it asks for

Beyond the starter's `x = 960`, labelled `03 / DON'T STOP`:

**Crumbling ledges.** Ledges in the new section collapse a short time after first contact. The
starter's own sign reads *"Read the landing. Then jump."* — it is a contemplative game where standing
still is free. In this section standing still is what kills you. Same controls, same physics,
opposite posture.

**The decision:** partway across, the player chooses between
- **sprinting the upper line** while it is still intact — faster, but it is gone behind them, or
- **deliberately collapsing it** and taking the lower line formed by the fallen debris — slower and
  passing nearer a hazard, but it does not time out.

This is a choice about *what the level becomes*, not merely which of two static corridors to enter.
At least two new landings require jumps. The finish moves past both routes so the new section must
be completed to win. The original section stays playable and unchanged.

**Severability (scope control):** crumbling alone delivers the mechanic. Debris-becomes-floor is the
ambitious half and is designed to be **cut without redesigning anything** if time runs short.

## 3. What must remain unchanged

- **Controls:** A/D and arrows, Space, R, Esc/P, Enter, M.
- **Movement and jump tuning:** every value in `tuning.gd`. No speed, gravity, jump-velocity,
  coyote or buffer change. If a jump in the new section proves impossible, **the geometry is
  revised, never the tuning.**
- **Collision behaviour:** the 18×28 collider at offset `(0,-14)`; layers and masks.
- **Retry:** unlimited, automatic ~0.55 s respawn at spawn, `deaths` increments, manual `R`.
- **Pause:** Esc/P and focus-loss pause; resume consumes no buffered jump.
- **Completion:** reach the goal `Area2D` → COMPLETE → Enter replays.
- **The original section:** still fully playable on its original route.

**Anticipated necessary change, flagged in advance:** the HUD progress bar divides by a literal
`852` (`hud.gd:24`) and the camera clamps to `level.width`. Widening the level *requires* touching
these or the presentation becomes wrong. These are presentation fixes, not behaviour changes, and
each will be tested.

## 4. Predicted failure cases

Genuine predictions recorded in advance. Some are expected to be wrong.

### P1 — Spikes and the finish flag will draw in the wrong place
`session.gd:198-204` draws hazards at a hard-coded `y = 320/304` and the finish pole at a hard-coded
`y = 320→250`, reading only the `x` from level data, while `_add_area()` builds the actual colliders
from the full rect. **Prediction:** any hazard or finish not at ground level will be drawn detached
from its own trigger.
**Check:** place a hazard above ground level, screenshot it, compare drawn position against the
`CollisionPolygon2D` coordinates. Confidence: high — this is read directly from the source.

### P2 — The world will stop being drawn at x = 960
Background rect, grid loops (`range(0,961,32)`), and three fixed-position mountains are hard-coded.
**Prediction:** past x=960 the player walks onto blank clear-colour with no grid or scenery.
**Check:** widen the level, capture a screenshot at x > 1000. Confidence: high.

### P3 — The crumble timer will break `complete-real-route`
`route_driver.gd` uses fixed jump marks `[138,292,424,548,712]` authored for the old layout. Adding
time-sensitive ledges means the deterministic route can arrive after a ledge has already collapsed.
**Prediction:** the route test fails on the first attempt and needs retimed marks — possibly more
than the 900-tick budget.
**Check:** run `test_game.gd`, read `complete-real-route` ticks/deaths. Confidence: high that it
breaks; **uncertain** whether the tick budget is the binding constraint.

### P4 — The trail will look like a collision mismatch facing left
The trail extends past the collider. **Prediction:** at some speeds, facing left, the trail will
overlap geometry and read as if the player should have collided.
**Check:** render standing / running / jumping captures in both facings, with the collider outline
overlaid in a debug capture. **This is the prediction I am least sure of** — it may read as
obviously non-solid and be a non-issue.

### P5 — The first crumble timing will feel unfair
**Prediction:** the first timing chosen will be too short, and a human playtester will report not
understanding what happened rather than feeling challenged.
**Check:** human playtest. This one cannot be settled by any automated check, and the fix is a
timing/telegraph change, not a physics change.

### P6 — The camera's forward-only lookahead will hide something
`session.gd:153` uses `player.position.x + 100`, which assumes rightward travel.
**Prediction:** near the new finish, or if any route moves leftward, the camera will show where the
player has been instead of where they are going.
**Check:** play to the finish and watch whether the flag and final landing are on screen in time.

---

## Revisions

*(Appended as findings arrive. Nothing above this line is edited.)*

### 2026-09-23 — after implementing the character and the extension

**Measured jump envelope.** Before designing any geometry I added
`godot/tests/probe_reach.gd`, which flies the real player through a full jump and
reports reach per landing height. Peak rise measured **56.00 px**, matching the
starter's recorded 56.07. Every jump in the new section was then designed against
this table with **≥23 px of margin**, so no jump tuning was touched.

| Landing height vs takeoff | Measured reach |
|---|---|
| 32 px above | 88.0 px |
| 24 px above | 96.0 px |
| level | 109.3 px |
| 40 px below | 82.7 px |

**P1 — CONFIRMED, fixed.** Hazards and the finish pole were drawn from literal
`y` values while their triggers came from level data. The new section's second
hazard sits on the upper platform at `y=200`; under the starter's code it would
have drawn at `y=304`, 104 px below what actually kills you. Both now derive
from the rect. Evidence: `evidence/extension/24-raised-hazard.png`.

**P2 — CONFIRMED, fixed.** Background, grid and scenery were capped at x=960.
All now derive from `level.width` (1840). Scenery was additionally rebuilt as two
parallax ridge layers. Evidence: `evidence/extension/22-the-fork.png`.

**P3 — WRONG.** I predicted the crumble timer would break `complete-real-route`
and might exceed the 900-tick budget. It did not. The route passed on the first
run in **631 ticks with 0 deaths**, crossing both crumbling ledges under their
live collapse timer. The reason is that the fixture's new marks were placed using
the measured envelope rather than guessed. **The 900-tick budget was not raised
and no assertion was weakened.**

**P4 — partly settled, still open for the human playtest.** The collider-overlay
captures (`evidence/character/*-collider.png`) show the body sitting entirely
inside the 18×28 box, with only the trail outside it. No misleading overlap was
observed in scripted captures, but whether the trail *reads* as non-solid during
real play is a human judgement and is not yet answered.

**P5 — still open.** Crumble delay is **36 ticks (0.6 s)**, chosen generously on
the principle that a crumbling platform's danger must be readable before it is
punishing. Untested by a human. No automated check can settle it.

**P6 — still open.** The camera's forward-only `+100` lookahead is unchanged. It
was not observed to hide the finish in scripted play, but it has not been judged
by a human on the lower branch.

### Geometry revisions made during the build

- **The lower-route hazard was moved, not removed.** As first drawn, spikes on
  the lower platform left only a 36 px landing zone after them — at full run
  speed a jump covers ~109 px, so the "safe" route demanded a short hop the
  controls cannot reliably produce. Rather than slow the player down, the hazard
  was moved onto the upper platform, where it forces a committed leap to the
  finish and suits the fast branch. This is a geometry revision, as required; no
  physics value was altered to make a bad layout work.
- **Crumbling ledges now demote rather than only kill.** The high-branch ledge
  sits directly above the low branch, so a player who stalls falls onto the safe
  route instead of dying. Missing a ledge entirely is still fatal.

### Harness defects found (test code, not game code)

Recorded because they cost real time and none were faults in the game:

1. The character preview first rendered with no trail — the harness ran the
   player into a step, so `velocity.x` was 0 and the trail *correctly* vanished.
2. The same preview facing left crossed the old finish trigger, completing the
   level and zeroing velocity.
3. The extension capture missed the stall death: a PNG write can outlast the
   ~34-tick retry window. The check now counts `deaths` instead of sampling for
   `DYING`. **The original intermittent cause was not fully isolated.**
4. Two new crumble checks failed at first because `is_on_floor()` still reported
   the spawn platform immediately after teleporting the player.
5. Windowed capture runs were being throttled by macOS to roughly 4 ticks/second
   until `--fixed-fps 60` was passed.

### Automated coverage after the change

**32 mechanics checks / 0 failures** (25 starter checks, all retained and passing,
plus 7 new) and **9 keyboard checks / 0 failures**. New checks:
`route-reaches-new-landings`, `finish-past-original-section`,
`crumble-supports-then-triggers`, `crumble-collapses-after-timer`,
`crumble-stall-is-fatal`, `crumble-resets-on-retry`,
`crumble-untouched-stays-solid`.
