# Gate V — visual QC report

Frames sampled: 30  ·  BLOCKER: 0  ·  MAJOR: 0

Regional text-contrast checks (all declared regions required): B02, B03, B04, B05, B06, B07, B08, B10, B11. Whole-frame dimming/scene color is not text contrast; empty-frame, fill and declared safe-area checks remain active. Visual content review remains required.

Clean — no BLOCKER/MAJOR defects. ✓
---

# Manual review — required, and not certified by any of the above

Gate V checks pixels against heuristics. It cannot tell whether a described
action happens, whether an input log is truthful, or whether the explanation is
correct. Those were reviewed by hand, and this is that record.

**Reviewer:** Claude Code, by frame inspection of the final export at 3840×2160.
**Export:** `exports/claude-liam-walker-jumpman-walkthrough.mp4`
**SHA-256:** `c6bfa3802a204e7f37277ae4e49082a07e0c232383cb383c1385e57bed3eacec`

## Technical

| Property | Measured |
|---|---|
| Resolution | 3840 × 2160 |
| Frame rate | 30/1 |
| Duration | 218.40 s |
| Video | H.264 |
| Audio | AAC, 48 kHz, stereo, mean −27 dB, max −4 dB |
| Long silences (> 3 s under −45 dB) | none |
| Gate V | BLOCKER 0 · MAJOR 0 |

## Inspected by eye

- **B00** carries `RECONSTRUCTION — THE DESIGN ASK, NOT A TRANSCRIPT` above the
  card and `illustrative reconstruction — no historical prompt log is claimed`
  below it. Both are legible at 4K. No fabricated build output appears.
- **B01 / B09 / B12** cards are readable; line lengths fit inside the plate.
- **Gameplay beats** are the game, unretinted and unrecreated. The HUD is legible
  in both palettes after the contrast fix described below.
- **The death in B07/B10 is real** — the `Missed the landing` card appears over
  the Betrayal, with the `THIS GAP IS EMPTY` sign visible in the same frame.
- **B11** shows completion and then a replay with the timer at `00 / 00.3s` and
  the log counter reset to `0 / 6`.
- **The outro** is `ClaudeTitleOutro` with the exact episode title and the
  handle. Liam speaks the title and "At Nik Bear Brown" over it; no jingle, no
  gameplay audio, no invented character voice on that card.

## What the gate found that was a real defect

Gate V measured the HUD's text at 0.03–0.30 luminance separation against a 0.3
floor. That was not a false positive. "Minimal HUD" had been a deliberate design
goal, but minimal had drifted into faint, and the readout is the one thing on
screen a player cannot deduce by looking at the world.

The fix was to the game, not to the measurement: both HUD bands became opaque
strips and the text tones in both palettes were pushed clear of their own
backing plate. The gameplay was then recaptured from the corrected build.

## What was declared, and why that is not suppression

- `qc.full_bleed` on the nine gameplay beats. The game renders edge to edge;
  crossing title-safe is the composition, not overflow.
- `qc.contrast_regions` naming the four **persistent** HUD elements. The
  whole-frame average is genuinely low because the upright palette is
  deliberately pale — that is the chapter's mechanic.
- An earlier revision also declared the feather readout as a region. The gate
  correctly reported nine `empty-contrast-region` defects, because that element
  does not exist until the player picks the feather up. The declaration was
  removed rather than worked around: claiming a conditional element as
  persistent text would have been a false statement about the frame.

## Known limits of this review

- Narration was verified as present and at sane levels by measurement, not by
  listening. Intelligibility of the synthesized voice has not been confirmed by
  a human ear.
- Frame inspection sampled beats, not every frame.
- The film depicts one build. It cannot demonstrate that the environmental
  clues are readable to a first-time player; that remains open in the verdict.
