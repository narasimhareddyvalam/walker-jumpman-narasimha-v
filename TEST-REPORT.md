# TEST-REPORT — walker-jumpman-narasimha-v

**Project:** `walker-jumpman-narasimha-v` — THE WORLD IS FALLING, Chapter One: The Fall
**Engine:** Godot **4.7.2.stable.official** (ed1daf0bf)
**OS:** macOS (Darwin 25.6.0), Apple silicon
**Tester:** Narasimha Reddy Valam (human playtest) · scripted checks by Claude Code

Results are recorded in the order they were obtained. Earlier results are kept
even where a later change superseded them.

---

## 1. Automated checks

Run from the repository root:

```bash
G=/Applications/Godot.app/Contents/MacOS/Godot
"$G" --headless --path godot --script res://tests/test_game.gd      # mechanics
"$G" --headless --path godot --script res://tests/test_keyboard.gd  # keyboard
"$G" --headless --path godot --script res://tests/probe_reach.gd    # jump envelope
"$G" --headless --path godot --script res://tests/probe_gravity.gd  # sign flip
"$G" --path godot --fixed-fps 60 --script res://tests/capture_game.gd
"$G" --path godot --fixed-fps 60 --script res://tests/capture_extension.gd
```

> On macOS the two capture scripts need `--fixed-fps 60`. Without it the
> background window is throttled to roughly four ticks per second and the
> scripted route desynchronises.

| Suite | Result | Revision |
|---|---|---|
| Baseline, unmodified starter | 25 mechanics + 9 keyboard, **0 failures**, route 325 ticks | `2f46177` |
| After character + extension | 43 mechanics + 9 keyboard, **0 failures** | `4ceafb0` |
| After the Feather + Chapter One | 43 mechanics + 9 keyboard, **0 failures**, route 1130 ticks | `d4ffd22` |
| After INVERSION | 49 mechanics + 9 keyboard, **0 failures**, route 1434 ticks | `83685d3` |
| After the light/dark palette | 51 mechanics + 9 keyboard, **0 failures** | `a6e24d4` |
| After the playtest fixes | 54 mechanics + 9 keyboard, **0 failures** | `ba24a9c` |
| After the rechargeable feather and the lying-world section | 65 mechanics + 9 keyboard, **0 failures**, route 1867 ticks | `d8e2336` |
| After plain-language rewrite and the unlock card | **66 mechanics + 9 keyboard, 0 failures** | `1aff6b4` + |

All **25 of the starter's original mechanics checks are retained and still
pass.** None was deleted, relaxed, or had an expected value changed.

Two fixture updates were made, neither of them a weakening:

- `route_driver.gd` lost its jump mark at `x=2780`, so the route now **walks**
  the Void Gap instead of jumping over the question the gap is asking.
- `finish-unreachable-without-feather` moved its probe from `x=2950` to
  `x=3800`, because the old coordinate now sits on the Void Gap's hidden floor.
  The assertion itself is unchanged.

Every check added for the Feather, for INVERSION and for the reversal pads was
written and **watched failing before** the implementing code existed. The RED
runs reported `hidden_entries: 0, has_rendered_slabs: false`, then
`has_pal: false`, then `pads: 0, has_pad_prompt: false`.

### Key measurements

| Measurement | Value |
|---|---|
| Jump rise, normal gravity | 56.00 px |
| Jump displacement, inverted | 56.05 px |
| Full route | 1867 ticks, **0 deaths** |
| Landings past the original section | 22 available, 12 stood on by the route |
| Level width | 4980 px, roughly five times the starter's route |

The inverted jump matching the normal jump to 0.05 px is the evidence that
gravity reversal is a **sign flip** and not a tuning change. `tuning.gd` is
byte-identical to the starter's.

---

## 2. Scripted capture coverage

`evidence/extension/` is produced by `route_driver.gd` driving the real game
through real inputs. The driver observes position and state to choose when to
press a key; it does **not** teleport, force completion, disable collision, or
call test-only shortcuts.

**These are not human playtest evidence** and are labelled as such wherever
they appear.

| Capture | Shows |
|---|---|
| `19-the-premise` | opening signage and upward-falling debris |
| `20-ground-dissolving` … `22-raised-hazard` | the breaking section and the fork |
| `23-the-feather` | the object, before pickup |
| `23a-the-power-unlocked` | the ability card naming the power |
| `23b-press-f-here` | a reversal pad with the keycap prompt |
| `24-inverted-ceiling` … `26-second-feather` | inverted traversal |
| `27-void-gap-holding` | standing on a floor that is not drawn |
| `28-you-were-never-falling` | the landing past the Void Gap |
| `29-truth-vision` | inverted, with hidden geometry rendered |
| `30-the-phantom` / `31-phantom-omitted` | the same stretch upright then inverted — the lie, then its absence |
| `32-the-locked-door` | a wall marked `DOOR LOCKED` that is not solid |
| `33-the-hazard-was-a-lie` | walking through fully-drawn harmless spikes |
| `34-inverted-over-the-spikes` | the lethal corridor crossed on the ceiling |
| `35-the-gantry-gave-way` | ceilings collapsed behind an inverted player |
| `36-section-clear-was-a-lie` | invisible spikes revealed under a sign reading `SAFE` |
| `37-the-mirror-ledge` | a platform solid only while inverted |
| `38-the-tower-door` / `39-chapter-ends` | the relocated finish and the ending card |
| `40-rising-off-the-ceiling` | inverted, at the end of a ceiling with open sky beyond |
| `41-leaving-the-level-upward` | still rising, still alive, about to exit the level |
| `42-ground-gave-way` | mid-fall through a ledge fragmenting underfoot |
| `43` / `44` | the same spot one tick apart — the reveal |

`40`–`42` are the setup for two genuine deaths, not photographs of them; see
§6 for why the instant of death cannot be captured reliably. The deaths
themselves are asserted by the capture script and by `sky-is-fatal` and
`crumble-stall-is-fatal` in the mechanics suite.

---

## 3. Human playtest — round 1

**Revision played:** `4415f78` · **Played by:** Narasimha, at the keyboard, with
a real window and real input.

### What worked

Startup, movement, jump, pause/resume and restart all behaved. The character
reads correctly facing both directions, standing, jumping and inverted. The
extended route is completable and the relocated finish requires the mechanic.

### What did not — reported verbatim

> *"few things, the story line isnt clear from start. blocks and all are not
> falling from up and also its not clear where to click F and invert and play
> upside down"*

Three distinct defects, none of which any automated check could have caught,
because all three are about what a human understands rather than what the
program does.

| # | Observation | Cause found in source |
|---|---|---|
| **O1** | Story unclear at the start | The first two signs were still the **starter's tutorial text** — `01 / GET MOVING`, `Read the landing. Then jump.` The chapter opened on instructions and never stated a premise. |
| **O2** | Debris not visibly falling upward | `_draw_debris` drew 34 pieces at 2–4 px and ~20% alpha. The motion was correct; it was simply too faint to notice, and worse in the new light palette. |
| **O3** | No idea where to press `F` | **There was no affordance of any kind.** Nothing in the world marked where inversion was the intended move. A player who did not guess `F` could not finish the chapter. |

**O3 is the serious one.** It is not a polish issue: the chapter had a hard
dependency on a key the game never taught, and the automated route passed
anyway because the fixture is *told* where to press it. This is precisely the
class of defect a scripted route cannot find and a human finds in ninety
seconds — the reason the assignment requires a human playtest at all.

None of P10–P13 (the predictions written before this session) were what the
player actually noticed first. P11 predicted light mode would hurt readability;
it was not raised. The real failure was an affordance gap nobody predicted.

---

## 4. Inspect and revise

### O3 → reversal pads

A `pads` array was added to the level data, marking the floor at **every one of
the five reversals the chapter requires**. Each pad draws a pulsing strip with
three chevrons rising off it, and when the player stands on one **holding a
charge**, the HUD shows `PRESS F TO FALL UPWARD`.

The prompt is deliberately conditional. `pad_prompt()` is true only when the
player is on a pad, has a charge, and is not already inverted — a prompt shown
when pressing `F` would do nothing would be the game lying to the player, which
is the one thing a chapter about unreliable information cannot afford to do by
accident.

Three checks, watched failing first:

| Check | Asserts |
|---|---|
| `pads-mark-every-mandatory-reversal` | all five spend points the route uses are covered by a pad |
| `pad-prompts-only-with-a-charge` | prompt appears with a charge, not without |
| `pad-prompt-clears-once-inverted` | prompt disappears once the player has acted |

### O2 → debris

Pieces raised from 34 to 46, sizes from 2–4 px to 3–12 px, alpha raised roughly
2.8×, and **each piece now drags a trail beneath it** so the direction of travel
is stated rather than inferred. Distance fade retained so the shaft still reads
as deep.

### O1 → opening

> **Superseded.** The signage quoted below was itself replaced in round 3 (O6)
> for being jargon. It is kept here because it is what the O1 fix actually
> looked like, and because the record is more useful than a tidy one.

The starter's tutorial signage was replaced with signage that does both jobs at
once:

```
SITE 07  /  DAY 41
The debris stopped falling down.
Nobody left here knows why.
A D  walk      SPACE  jump

EVACUATION ORDER 09
Reach the observatory.
It is the last thing still anchored.
```

The title card now reads *"The debris is falling upward. Nobody knows why."*
and states the objective, where before it said only *"Something is wrong with
the ground."*

---

## 4b. Second round of feedback — the first fix was rejected

Shown the revised build, the player reported:

> *"i dont like the debris. also intead of just plain platforms. give me ideas
> for them to be something else? like buildings etc?"*

| # | Observation | Response |
|---|---|---|
| **O4** | The debris fix was worse than the problem | Confirmed by inspection of `19-the-premise`: 46 squares each dragging a vertical line rendered as **pins on sticks**, not as motion. Uniform spacing made it read as a repeating pattern rather than falling matter. |
| **O5** | Platforms are plain rectangles | Fair. Every solid was the same flat slab regardless of what it was meant to be. |

### O4 → objects, not particles

Count cut from 46 to **14**, trails removed entirely, and each piece is now a
**rotating silhouette** of something from the site: a floor slab, a length of
rebar, a torn wall panel, a chair. Rotation is what communicates free fall; a
trailing line does not. Fewer pieces means each one is legible instead of
contributing to a texture.

This is recorded as a **failed first attempt**, not quietly replaced. The
original debris was too faint to see; the first fix was visible and wrong. Only
the third version works.

### O5 → two materials, chosen by thickness

The level already contains exactly two classes of solid — thick blocks
(`h = 64`) and thin ledges (`h = 14–16`) — so `_draw_slab` now branches on
height and the material itself carries information:

| Solid | Drawn as | Says |
|---|---|---|
| `h ≥ 30` | **Rooftop** — parapet lip, deeper facade, grid of windows with some still lit | a building of the district Site 07 was built through; permanent |
| `h < 30` | **Service catwalk** — grating deck, support struts beneath, bolt plate at each anchor | the facility's own structure; temporary, added later |

Ceilings are detailed on their underside via the same `dir` term already used
for edge lighting, so an inverted surface still reads as a surface.

One regression this caused, found by inspecting the capture rather than by any
check: the window grid sits directly behind the HUD's bottom row and the
controls line stopped being readable. A backing band was added behind it.

### Round 2 re-test

**PENDING.** The three fixes are verified by automated checks and by inspection
of the recaptured evidence, but a fix for a comprehension defect is only proven
by a human who did not previously understand it. Round 2 records whether the
premise now lands, whether the debris reads as falling upward, and whether the
`F` prompt is findable without being told.

---

## 5. Open, and honestly unresolved

- **P10 — does the Betrayal read as cheap?** Not reached in round 1; the player
  stopped at the affordance gap before getting there.
- **P12 — is flipping purely to inspect too expensive?** Untested.
- **P13 — do the two palettes read as one place?** Untested.
- No audio. No exported build. Source only.
- Chapters Two to Five in `GDD.md` are **design only** — no code, no level data.

---

## 6. Third round of feedback — writing and legibility

> *"remove this day wise journey in the game"* · *"Feather like superpower or
> something… make it more clear"* · *"the story line wordings are not clear…
> even a 5 year old should be able to understand"* · *"whatever riddles you
> added like do not jump, do not cross here should be present… from starting of
> the level"* · *"the text is too much here and is confusing for user"*

| # | Observation | Change |
|---|---|---|
| **O6** | Story unreadable at speed | All signage and six logs rewritten in short, plain sentences. `SITE 07`, `SUBJECT 07`, `EVACUATION ORDER 09`, `GRAVITATIONAL RESEARCH` removed; the observatory is now **the tower**. |
| **O7** | Warnings only appeared near the late puzzles | Signs now start on the opening screen, so the player has been reading them for ~2000 px before one starts lying. |
| **O8** | Three text layers competing in one frame | A log collected while the unlock card is showing waits its turn; the redundant `THE FEATHER / RECOVERED HERE` sign deleted. |
| **O9** | The power never announced itself | Pickup raises a card naming it; HUD reads `FEATHER` + `READY / INVERTED / RECHARGING`; the pad prompt is a keycap plus `REVERSE GRAVITY`. |

### A harness defect worth recording separately

The sky-death capture began failing its assertion. **Two diagnoses were wrong**
before a throwaway probe found the cause: the harness sampled `game.deaths`
*after* a blocking `capture()`, and a PNG write costs ~33 physics ticks — the
same length as the death-and-retry window — so the death occurred inside the
screenshot and was never observed.

A consequence we accepted rather than solved: **an instant-of-death photograph
cannot be timed reliably** at that cost. Those captures are now named for what
they can actually show (`41-leaving-the-level-upward`), and the death is
evidenced by the capture script's assertion plus the `sky-is-fatal` mechanics
check — not by a picture that might be of the respawn.

---

## 7. Still outstanding

**The human playthrough.** Three rows of the required table remain unverified by
a person: the extended route reaching both new landings and the relocated
finish, failure and recovery plus replay, and camera/presentation readability.
The first playtest stopped at an affordance gap before reaching them; the fixes
for that are in, but a fix for a comprehension defect is only proven by someone
who did not previously understand it.

This is recorded as unverified rather than claimed.
