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
