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

---

## Revision 2 — 2026-09-23, later: the chapter pivot

The original brief above described a crumbling-ledge section with a
high-road/low-road fork. That work was built, tested and kept. It is now the
**middle** of a larger chapter rather than the whole extension.

**Why it changed.** Playing the result, the level worked but carried no idea.
The decision was made to build the extension as **Chapter One of THE WORLD IS
FALLING** — a dark sci-fi chapter in which gravity is failing — with a new
object, **the Feather**, granting scarce gravity-reversal charges. The
crumbling ledges were kept and reframed as matter losing cohesion, which is the
premise rather than a platformer device. Nothing built earlier was discarded.

Nothing above this line was edited. The predictions P1-P6 were made against the
earlier design and are left exactly as written.

### Two departures, declared here rather than discovered later

**1. Gravity direction is now world state.** `tuning.gd` is byte-identical:
gravity 960, terminal 480, jump -320, speed 160, coyote 6, buffer 6. What the
Feather changes is the **sign** applied to gravity, to the jump impulse and to
`up_direction`. The assignment forbids changing jump strength to make a jump
possible; this does not change it. **Measured proof:** an inverted jump
displaces **56.05 px** where a normal jump rises **56.00 px** — mirrored, not
strengthened. Asserted by `inverted-jump-matches-normal-rise`.

**2. One control was added: `F` (or Shift).** Move, jump, retry, pause, confirm
and menu keep the starter's bindings exactly. This is an addition to the control
set, not a change to the existing one, and the starter's nine keyboard checks
still pass untouched.

Two consequences of inverted gravity were handled rather than ignored:
- **The sky became lethal.** Falling upward out of the level now kills with its
  own reason. No existing collision check was removed to add it.
- **The collider was not touched.** Inverted, the figure is mirrored about the
  collider's centre line, so the drawing stays inside the same 18x28 box.

### New predictions for the chapter

**P7 — The charge economy will be too tight or too loose on the first attempt.**
Two Feathers grant three charges; two reversals are mandatory and one is an
optional shortcut. **Prediction:** a human will either run out and feel cheated,
or never feel the scarcity at all. **Check:** human playtest; the automated
route deliberately takes the shortcut and finishes with **0 charges left**,
which proves it is survivable but says nothing about how it feels.

**P8 — The ceiling run's flip-back moment will be unreadable.** The player must
cancel the reversal before the ceiling ends or run off it into the sky.
**Prediction:** first-time players will not know where the ceiling ends and will
die without understanding why. **Check:** human playtest. If confirmed, the fix
is a visual tell at the ceiling's end or a longer overlap — not a longer timer.

**P9 — Inverted, players will lose track of which way up they are.** The trail
colour is the only readout. **Prediction:** the cyan/amber distinction is too
subtle at 640x360 and a second cue will be needed. **Check:** human playtest and
the inverted collider captures.

### What did not change

Controls for move/jump/retry/pause, all tuning values, the 18x28 collider,
unlimited retries, focus-loss pause, completion and replay, and the original
section's route. All 25 starter mechanics checks and all 9 keyboard checks still
pass, unmodified.

### Automated coverage after the pivot

**43 mechanics checks / 0 failures** and **9 keyboard checks / 0 failures**.
The route fixture's tick budget rose from 900 to 2400 because the level is
roughly three times longer; the observed run is **1130 ticks with 0 deaths**, and
that figure is reported in the check so the margin stays visible. No assertion
was relaxed and no expected value was changed to obtain a pass.

---

## Revision 3 — 2026-09-23, night: INVERSION

The chapter had a mechanic (gravity reversal) but not yet a *theme*. This
revision supplies one, and it is a single law rather than a bag of tricks:

> **The world renders what you believe, not what is there.**

Everything below follows from it. Upright vision draws phantom geometry and
withholds hidden geometry; inverted vision does the exact reverse. Collision is
never consulted by either, which is what keeps this a deduction rather than a
gotcha — the player can always check by flipping, and the check is free apart
from the charge it costs.

### What this added

| Element | Behaviour |
|---|---|
| **Hidden geometry** | Built as a normal collider, simply not drawn. Rendered as a cyan lattice while inverted. |
| **Phantom geometry** | Drawn exactly like real ground, never built as a collider at all. Absent while inverted. |
| **The Void Gap** (x 2800–3000) | Apparent chasm; a hidden floor catches a player who keeps walking. |
| **The Betrayal** (x 3140–3360) | Visually identical gap with nothing in it. The lesson from the Void Gap is the wrong lesson. |
| **The Phantom** (x 3540–3670) | A drawn platform that holds nothing. |
| **Light / dark palette** | Upright the facility is pale daylight; inverted it is near-black. Gravity chooses, so colour can never disagree with orientation. |

The observatory moved right to make room; level width 3120 → 3980. A third
Feather at x=3060 funds the corridor's three mandatory reversals, and the route
now finishes with **0 charges spare** — the economy is exactly tight.

### Why this is not a gotcha

The Betrayal kills a player using the rule the previous screen taught them.
That is deliberate, and three things keep it fair: a sign over the gap reads
`IT IS NOT THE SAME GAP`; flipping reveals the truth before committing; and the
ceiling above the gap is visible from the approach, so the alternative route is
never hidden. The punishment is for assuming, not for failing to read minds.
**Whether that distinction survives contact with a real player is exactly what
the playtest has to answer** — see P10.

### New predictions

**P10 — The Betrayal will read as cheap rather than clever.** *Prediction:* the
first death there will feel unfair, and the sign will turn out to be too easy to
run past at full speed. *Check:* human playtest. If confirmed, the fix is to
slow the approach or make the sign impossible to miss — **not** to put a floor
in the gap, which would destroy the lesson.

**P11 — Light mode will hurt readability.** The starter and the whole chapter
were designed against a near-black background. *Prediction:* the parallax
strata and fog bands will wash out at low contrast, and something that mattered
will become hard to see. *Check:* the recaptured evidence and the playtest.

**P12 — Flipping purely to inspect will feel wasteful.** A charge spent checking
is a charge not spent travelling. *Prediction:* players will avoid checking
precisely when checking matters most. *Check:* human playtest; if confirmed,
consider a free inspection that does not move the player.

**P13 — The two worlds will not read as one place.** *Prediction:* the palette
flip will feel like a different game rather than the same room seen truthfully.
*Check:* compare captures 30 and 31, which frame the same geometry in both
schemes.

### What still did not change

`tuning.gd` is byte-identical. The 18x28 collider is untouched. Move, jump,
retry, pause, confirm, menu keep the starter's bindings; `F` remains the single
added key. No collision check was removed — hidden geometry *adds* colliders and
phantom geometry adds none.

### Automated coverage after INVERSION

**51 mechanics checks / 0 failures** and **9 keyboard checks / 0 failures**, on
Godot 4.7.2.stable. All 25 starter checks and all 43 pre-INVERSION checks are
retained unmodified. The eight new checks were each written and **watched
failing** before the implementing code existed; the RED run reported
`hidden_entries: 0, has_rendered_slabs: false` and `has_pal: false`.

Two fixture updates, neither of them a weakening: the route's jump at x=2780 was
removed so it *walks* the Void Gap rather than jumping the question, and
`finish-unreachable-without-feather` moved from x=2950 to x=3800 because its old
coordinate now sits on the hidden floor. Both assertions are unchanged.

---

## Revision 4 — 2026-09-23, late: the playtest rewrites the economy

The human playtest (§3 of `TEST-REPORT.md`) found three comprehension defects
and, on the second pass, rejected one of the fixes. This revision records what
changed as a result, including a design reversal.

### The Feather stops being scarce

**The original design was wrong, and P12 predicted why.** Scarce charges made
*inspecting* expensive, in a chapter whose entire subject is checking whether
what you see is real. Players avoid the verb the game is about.

| | Before | After |
|---|---|---|
| Supply | 5 charges across 3 pickups | one charge, `RECHARGE_TICKS = 150` (2.5 s) |
| First pickup | grants 2 charges | grants the **ability**; `F` does nothing before it |
| Cancelling | costs the charge, no refund | unchanged — but waiting gets it back |
| Stacking | up to 5 | never above 1 |

**What this costs:** the route fork's resource decision. "Spend a charge on the
ceiling or walk the long way free" is no longer a real question. That was a good
decision and it is gone. **What it buys:** flipping becomes a verb you use
freely, which is what makes every illusion below solvable rather than a gamble.

`tuning.gd` is still byte-identical. The change is to the ability's supply, not
to movement.

### The world lies in four new ways

Each has a rule, and the rule is always the same one: **appearance and substance
are independent, and inversion shows substance.**

| Element | Upright | Inverted | Solid? |
|---|---|---|---|
| `hidden` | not drawn | drawn as lattice | always |
| `phantom` | drawn as slab | not drawn | never |
| `mirror` | not drawn | drawn as slab | **only inverted** |
| `hidden_hazards` | not drawn | drawn | always lethal |
| `phantom_hazards` | drawn | not drawn | never lethal |

Plus a **sealed door** that is a tall phantom (walk straight through
`SECTOR SEALED`), a **spike corridor** that must be crossed inverted, and
**ceilings that crumble** while you hang from them.

Four of the section's signs are lying: `SECTOR SEALED`, `HAZARD / DO NOT CROSS`,
`SECTION CLEAR`, and — the only honest one — `FLOOR COMPROMISED`. By this point
the player has been taught to check.

### Story delivery, not more signage

Six **log fragments** are collectible like the Feather and deliver one line
each, escalating from institutional notices to something addressed to the
player. The closing line is the chapter's turn: the observatory was never an
exit, and `SUBJECT 07` has been here before. This answers *why can you use the
Feather* while opening *what did you do here*.

### New predictions

**P14 — the recharge will feel too slow at the spike corridor.** 2.5 s is a long
time to stand still over lethal ground. *Check:* playtest; the route fixture
already has to wait for a charge at two marks.

**P15 — hidden spikes will feel unfair even with the `SECTION CLEAR` sign.**
Unlike the Betrayal, there is no visible alternative route until you flip.
*Check:* playtest. If confirmed, the mirror ledge above needs a visible tell
while upright.

**P16 — mirror ledges will be mistaken for hidden floors.** Both appear on
inversion; only one is solid there. *Check:* playtest.

### Automated coverage after Revision 4

**65 mechanics checks / 0 failures** and **9 keyboard checks / 0 failures**.
Route: **1867 ticks, 0 deaths**, finishing inside the observatory at x≈4841.
Level width 3980 → **4980**.

Thirteen checks were added and each was watched failing first. Four existing
Feather checks were **rewritten** rather than deleted, because the contract they
asserted genuinely changed; the rewrite is recorded above so the original
expectation is not silently lost.

### A real bug the new geometry exposed

`_add_area` divided **any** hazard rect into exactly three 8 px triangles. At
the starter's 24 px hazards that tiles perfectly, so nothing ever showed it. The
260 px spike corridor would have been roughly 90% gap — lethal-looking and
almost entirely safe to walk. Spikes now tile at a fixed 8 px pitch in both the
trigger and the drawing. Found by a failing check, not by inspection.

---

## Revision 5 — 2026-09-24: plain language, and warnings from the first screen

Second round of playtest feedback, verbatim:

> *"remove this day wise journey in the game and also make this clear - Feather
> like superpower or something. PRESS F TO FALL UPWARD. - make it more clear"*

> *"the story line wordings are not clear. make sure the story line is clear and
> people who are playing will understand the storyline - even a 5 year old
> should be able to understand storyline. and whatever riddles you added like do
> not jump, do not cross here should be present for the end user gamer from
> starting of the level. not only at the end of the game. the text is too much
> here and is confusing for user"*

### O6 — the writing was literary, not legible

Every line in the game was written to be *evocative*. `Recovery: one object. It
does not fall. It is not ours.` is a sentence that rewards a second reading, and
a player running right at 160 px/s does not get one.

All signage and all six logs were rewritten in plain words, short sentences,
concrete nouns. `SITE 07`, `SUBJECT 07`, `GRAVITATIONAL RESEARCH`, `EVACUATION
ORDER 09`, `STRUCTURAL COHESION FAILING` and `OBSERVATORY` are gone. The
observatory is now **the tower**.

The story is now: *gravity broke, everything falls up, everyone ran away, you
stayed, you find a feather that falls up, and at the end you learn you built
this.* Six one-line fragments carry it.

### O7 — warnings arrived too late

The instructional signs (`WALK. DO NOT JUMP.`) only existed around the puzzles
in the second half. A player met the first trick with no training in reading
signs at all. There are now signs from the opening screen — `THE WORLD FALLS UP
/ Run right. Reach the tower.`, `SPIKES HURT / Jump over them.`, `THE GROUND IS
BREAKING / Keep moving.` — so by the time a sign starts lying, the player has
been reading them for two thousand pixels.

### O8 — three text layers at once

Screenshot showed the log banner, the ability-unlock card and two world signs
competing in one frame. A log fragment collected while the unlock card is up now
waits its turn rather than stacking, and the redundant `THE FEATHER / RECOVERED
HERE` world sign was deleted — the card already says it.

### O9 — the power did not announce itself

Picking up the feather now raises a card naming it and stating what it does. The
HUD reads `FEATHER` with `READY / INVERTED / RECHARGING` instead of four pips
counting something invisible, and the pad prompt is a drawn keycap plus
`REVERSE GRAVITY` / *you will fall upward onto the ceiling*.

### A harness bug, and two wrong diagnoses

The sky-death capture began failing its assertion. **I guessed the cause twice
and was wrong both times**, blaming the choice of ceiling, and committed a
comment confidently explaining a reason that was false.

A throwaway probe settled it in one run: the original ceiling killed the player
perfectly well. The harness sampled `game.deaths` *after* a blocking
`capture()`, and a PNG write costs about 33 physics ticks — the same length as
the death-and-retry window — so the death happened inside the screenshot and the
count never saw it.

The false comment has been corrected in place. A consequence of the same
measurement: **a photograph of the instant of death cannot be timed reliably**,
so those captures are now named for what they can actually show
(`41-leaving-the-level-upward`), and the death is evidenced by the assertion and
by the `sky-is-fatal` check instead of by a picture that might be of the respawn.

### Automated coverage after Revision 5

**66 mechanics checks / 0 failures** and **9 keyboard checks / 0 failures**.
No assertion was weakened; the only check added this revision extends
`feather-grants-the-ability-and-one-charge` to cover the unlock announcement,
and is labelled in the source as written after the state existed rather than
staged as its own red-green cycle.

---

## Revision 6 — 2026-09-24: the environment speaks, and a tool finds a defect

### The environmental visual language

The brief changed: stop telling the player what to do, let the world
communicate. Objects now carry an **allegiance** — they fell under normal
gravity or under inverted gravity — and where an object rests says which.

Nineteen props across the chapter: seven obeying normal gravity to establish
what "correct" looks like before anything contradicts it, and twelve obeying
inverted gravity, covering **all seven ceilings** the route uses. Two of them
hang at the mirror ledge's height, where nothing is drawn while upright — a
chair and a heap of rubble resting against apparently nothing, which is the only
warning that an invisible platform is above.

`PRESS F` now appears on the **first pad only**. The rest lose their text. The
two signs that gave the answer away were deleted, because the objects say it
better.

**This is a compromise and it is recorded as one.** The brief asked for no
prompts. Round-one playtest ended with the player unable to find `F`, so the
chapter had a hard dependency on a key it never taught. The verb is taught once,
in words, on safe ground.

Four checks, watched failing first (`props: 0, has_prop_agrees: false`): both
allegiances present, meaning inverts with gravity, every ceiling marked, and the
prompt on pad 0 but not pad 3.

### A real defect found by the film's QC gate

Gate V measured the HUD text at **0.03–0.30 luminance separation** against a 0.3
floor. Two of its three complaints were card heuristics mis-firing on full-frame
gameplay, and the skill has sanctioned declarations for exactly that. **The
third was a genuine readability defect** — "minimal HUD" had drifted into faint,
and in light mode the controls row was grey on grey.

Fixed in the game, not in the measurement: both HUD bands became opaque strips
and the text tones in both palettes were pushed clear of their backing plate.
Every capture was re-made from the corrected build.

**And one of my own declarations was wrong.** I named the feather readout as
essential text; the gate correctly returned nine empty-region defects because
that element does not exist before the pickup. Removed rather than worked
around.

### New predictions

**P17 — the props will read as decoration rather than instruction.** *Prediction:*
a player will notice the chair on the ceiling and not connect it to "enter here
inverted". *Check:* human playtest. The first version of this was already
rejected for exactly this reason and rebuilt larger; whether the rebuild is
enough is unverified.

**P18 — the first-pad prompt will be enough to teach the verb.** *Prediction:* one
worded prompt on safe ground transfers to six unworded reversal points. *Check:*
human playtest. If it fails the fix is a second worded prompt, not returning
text to all seven.

**P19 — the opaque HUD bands will feel heavier than the "minimal HUD" intent.**
*Check:* playtest and the recaptured evidence. The readability gain is measured;
the aesthetic cost is not.

### Automated coverage after Revision 6

**70 mechanics checks / 0 failures** and **9 keyboard checks / 0 failures**, on
Godot 4.7.2.stable. All 25 starter checks retained unmodified. Verified again
from a **fresh clone** of the published repository, not the working folder.
