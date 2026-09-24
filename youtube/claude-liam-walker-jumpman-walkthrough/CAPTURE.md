# CAPTURE — how the gameplay footage was made

**Game:** `walker-jumpman-narasimha-v` · **game-source commit:** `8041bc0`
**Engine:** Godot **4.7.2.stable.official.ed1daf0bf**
**Host:** macOS (Darwin 25.6.0), Apple silicon
**Capture date:** 2026-09-24

---

## build_id

```
b7ad71839f87ad99a5c34abc88f3ba87c66000ae74eac53442d1f10f07e76a30
```

**Method.** SHA-256 of the concatenated per-file SHA-256 listing of every game
source file, sorted byte-wise:

```bash
find godot -type f \( -name '*.gd' -o -name '*.json' -o -name '*.tscn' -o -name '*.godot' \) \
  ! -name '*.uid' | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256
```

**Source list** — 15 files: `project.godot`, `game/main.tscn`, `game/session.gd`,
`ui/hud.gd`, `features/player/player.gd`, `features/player/tuning.gd`,
`levels/first_steps.json`, and the eight scripts in `tests/`. `.uid` files are
excluded because Godot regenerates them and they carry no game behaviour.

---

## Capture method

**Godot Movie Maker**, driven by an input-only script. This is offline
rendering: it is **not** evidence of real-time frame rate on any machine.

```bash
godot --path "$CAPTURE_PROJECT/godot" --resolution 3840x2160 \
      --write-movie "$RAW/run-01.avi" --fixed-fps 60 \
      --script res://capture_driver.gd -- --run=run-01 --out="$REEL/capture"
```

### Native 4K, not an upscale

The game's logical canvas is **640×360**. The capture project's window override
is set to **3840×2160**, an exact **6×** integer scale, with the starter's
`canvas_items` stretch mode and `keep` aspect unchanged. Every pixel is rendered
at 4K by the engine; no recording was enlarged. The logical resolution is
disclosed here separately from the output resolution, as the reference requires.

### Why 60 fps and not 30

A first probe at `--fixed-fps 30` produced one physics tick per movie frame, so
6.57 s of gameplay became 11.22 s of video — **half speed**, which would have
broken the normal-simulation-speed rule. At `--fixed-fps 60` one physics tick is
one frame and `run-03` measured 395 frames / 6.583 s against the driver's
reported 6.57 s of gameplay. The MP4s are then resampled 60 → 30 fps by frame
selection, which preserves duration and speed exactly and matches the film's
frame rate.

### Isolation

Captures run against a **copy** of the project outside the repository. The only
difference from the shipped game is the window-size override above. The original
project, its saves and any open editor instance are untouched.

---

## The driver

`capture_driver.gd` lives only in the capture copy. It:

- instantiates the **real** `game/main.tscn`;
- drives the game with `Input.parse_input_event(InputEventKey)` **and**
  `Input.action_press` / `action_release`;
- **never** teleports the player, writes position or velocity, forces
  completion, disables collision, or uses the `test_*` fields the unit tests use
  to seed coyote/buffer state;
- reads position and state only to decide *when* to press a key, which is what a
  person does with their eyes;
- logs every press, release and periodic position sample against the physics
  tick to `capture/<run>-inputs.jsonl`;
- asserts its expected outcome and **exits nonzero** if the run does not reach
  it. Exhausting the tick budget is a failure, not a pass.

### One game flag is set, and it is disclosed

The driver sets `game.test_mode = true`. In `session.gd` that flag gates exactly
one thing — `_on_focus_lost`, which auto-pauses when the window loses focus.
That behaviour is correct for a person and fatal for an unattended multi-minute
recording: anything that steals focus silently pauses the game and the capture
records a frozen world. It changes no gameplay rule, and `run-03` still
exercises pause and resume through real `Escape` and `Enter` presses.

---

## Runs

| Run | Ticks | Duration | Frames @60 | Outcome |
|---|---|---|---|---|
| `run-01` | 1883 | 31.38 s | 1884 | chapter completed, **0 deaths** |
| `run-02` | 1338 | 22.30 s | 1339 | genuine death at the Betrayal, then automatic retry |
| `run-03` | 394 | 6.57 s | 395 | pause, resume, manual retry |

---

## Failures encountered, and what they were

Recorded because two of them produced footage that looked fine and was wrong.

1. **`Input.action_press` alone did not start the game.** It sets polling state
   but synthesizes no event, so `session.gd`'s `_unhandled_input` — which
   handles Enter, Escape, R and M — never saw it. Fixed by sending real
   `InputEventKey` objects.

2. **The player froze for 2.5 s after every flip.** A driver bug: it kept
   `move_right` released until `feather_charges > 0`, which is never true
   immediately after spending the charge. On a ceiling that was long enough for
   the 3 s reversal to expire underneath the player, and they fell. The game was
   correct; the driver was wrong.

3. **A held key stopped arriving when the window lost focus.** One run recorded
   the player standing at x=213 for 97 seconds. Synthesized key events depend on
   OS focus; `Input.action_press` does not. The driver now drives both paths, so
   an unattended capture cannot be ruined by another window taking focus.

All three were caught by the driver's own assertions rather than by watching the
footage, which is the reason the assertions exist.
