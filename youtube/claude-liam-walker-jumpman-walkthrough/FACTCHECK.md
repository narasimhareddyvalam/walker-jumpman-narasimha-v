# FACTCHECK — every claim the narration makes, and where to check it

Each row is a statement spoken in the film. "How to check" is a command, a file
and line, or a named test — not a reference to this document.

| Beat | Claim | How to check |
|---|---|---|
| B00 | The prompt shown is a reconstruction, not a transcript | Labelled on screen and in `beat_sheet.json` as `reconstruction: true`. No historical prompt log is claimed to exist. |
| B01 | The starter is `nikbearbrown/walker-jumpman` at `9387542` | `git log --oneline` — that commit is the first in this repository |
| B01 | The starter drew the character as four stacked rectangles | `git show 9387542:godot/features/player/player.gd`, `_draw()` |
| B01 | The level is about five times longer | starter `width` 960 → current 4980 in `godot/levels/first_steps.json` |
| B01 | Four chapters are designed and not built | `GDD.md` "Chapters not built — design only"; no level data or scripts exist for them |
| B02 | Controls are the starter's, unchanged | `_setup_input()` in `session.gd`; only `feather` was added |
| B02 | The trail's length is horizontal speed | `player.gd` `_draw()` — trail length derives from `velocity.x` |
| B03 | Ledges give way after contact, not on a timer | `crumble-untouched-stays-solid` in `tests/test_game.gd` |
| B04 | One charge, returning 2.5 s after it is spent | `RECHARGE_TICKS = 150` at 60 ticks/s; `feather-recharges-after-spending` |
| B04 | The charge never stacks above one | `feather-never-stacks-above-one` |
| B05 | Gravity reversal does not change the jump | `tuning.gd` is byte-identical to the starter's: `git diff 9387542..HEAD -- godot/features/player/tuning.gd` is empty. `inverted-jump-matches-normal-rise` measures 56.05 px against 56.00 px |
| B05 | The palette switches with gravity | `palette-inverts-with-gravity` and `palette-upright-is-the-lighter-one` (upright void luminance 0.92, inverted 0.045) |
| B06 | The hidden floor is solid but never drawn upright | `hidden-supports-but-is-not-drawn` |
| B06 | Inverting renders it | `hidden-revealed-when-inverted` |
| B07 | The second gap is genuinely empty | `betrayal-gap-is-fatal` — death reason "Missed the landing" |
| B08 | A drawn platform holds nothing | `phantom-is-drawn` and `phantom-is-drawn-but-not-solid` |
| B08 | Fully drawn spikes are harmless | `phantom-hazard-is-drawn-but-harmless` |
| B08 | Invisible spikes are lethal | `hidden-hazard-is-invisible-but-lethal` |
| B09 | The starter already walked its level data twice | `session.gd` — build loop in `_ready()`, draw loop in `_draw()`. Both predate this work; see `git show 9387542:godot/game/session.gd` |
| B09 | Hidden joins only the build loop; phantom joins neither | `_ready()` iterates `level.hidden`; nothing iterates `level.phantom` outside `_draw()` |
| B09 | No collision check was removed | `git diff 9387542..HEAD -- godot/game/session.gd` — hidden geometry *adds* colliders |
| B10 | The death shown is real | `capture/run-02-inputs.jsonl` logs the input and the resulting `state=3`; the run asserts it and exits nonzero otherwise |
| B10 | Retries are unlimited | `twenty-retries` performs 21 and passes |
| B11 | The finish moved from x=916 to x=4750 | starter `finish` vs current in `first_steps.json` |
| B11 | A normal jump cannot reach it | `finish-unreachable-without-feather` |
| B12 | 70 mechanics + 9 keyboard checks, 0 failures | `godot --headless --path godot --script res://tests/test_game.gd` and `test_keyboard.gd` |
| B12 | All 25 starter checks retained, none weakened | `TEST-REPORT.md` §1; the starter's assertions are unchanged in `test_game.gd` |
| B12 | 22 landings past the original section | `route-reaches-new-landings` reports `new_landings_available: 22` |
| B12 | The playtest found defects the checks passed over | `TEST-REPORT.md` §3 and §6, `FRICTIONAL.md` §11–14 |
| B12 | Debris took three attempts | `FRICTIONAL.md` §12; commits `ba24a9c` and `d8e2336` |

## Claims deliberately **not** made

- No claim about real-time frame rate. The capture is offline rendering
  (`CAPTURE.md`).
- No claim that the environmental clues are readable — that is listed in the
  verdict as unsettled, because only a player can answer it.
- No claim that the Betrayal is fair. The design argument is given; the verdict
  says the question is open.
- No claim that Chapters Two to Five exist in any form beyond design text.
- No claim that the human playtest covered every required row. Three rows of
  `TEST-REPORT.md` are recorded as unverified.
