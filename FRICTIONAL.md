# FRICTIONAL — the honest log

**Project:** walker-jumpman-narasimha-v · **Student:** Narasimha Reddy Valam

This is a record of what was actually attempted, what broke, and what changed as
a result. Entries describing code and command output are drawn from real runs and
real commits. Entries marked **[author]** are my own reflections and are written
by me, not generated.

> **Status note.** Sections marked **AWAITING PLAYTEST** are deliberately empty
> until I have played the build myself. They will not be filled in from scripted
> runs, because a scripted route is not a playtest.

---

## 1. Setting up, and a decision about where to work

**Attempt.** Clone the starter and begin.

**What happened.** Godot was not installed on this machine at all, so nothing
could be run or tested initially. I installed **4.7.2** specifically, matching the
version recorded in the starter's own `BUILD-REPORT.md`, rather than the latest
release, so that no behaviour difference would need explaining later.

**A decision I made.** I asked that the checkout have no link of any kind to the
instructor's repository. `origin` was deleted immediately after cloning, and
`git remote -v` printed nothing. I kept the starter's commit `9387542` as the base
of the history, because it makes my additions provable with one diff rather than
asserted in prose.

**Check.** Ran the starter's own suites before changing anything: **25 mechanics
checks and 9 keyboard checks, 0 failures**, route completing in **325 ticks**.
The rendered screenshots came out **byte-identical** to the ones committed in the
starter, which told me the environment was reproducing the author's results
exactly and any later difference would be mine.

---

## 2. Rejecting the first character idea

**What was proposed.** Claude offered a set of themed avatars — a diver, a kite
runner, a surveyor — each a different costume on the same rectangle.

**What I decided.** I rejected that framing. A costume swap is what the
assignment's own wording invites and what I expected most submissions to do. I
asked for a character built out of the mechanic instead.

**What came of it.** The Runner's trail length is its horizontal speed, so
standing still visibly extinguishes the character. That mattered later: the level
is built around not standing still, and the avatar warns you before the floor
does. Much later, the same trail took on a second job — it changes colour to
report gravity state, which is the only readout the Feather has.

**[author]** *Write here: whether you think the trail actually reads as speed
while playing, or whether you only know it does because you were told.*

---

## 3. Three harness bugs that looked like game bugs

**Attempt.** Render the new character in every state to judge it from pixels.

**What happened, in order.**

1. The first render showed **no trail at all.** My first instinct was that the
   drawing code was broken. It was not: the harness had staged the run so the
   player collided with a step, so `velocity.x` was zero and the trail correctly
   showed nothing.
2. Restaged, the left-facing render **also** showed no trail. Same class of
   mistake: running left from x=950 crossed the finish trigger, completing the
   level, which disables the player and zeroes velocity.
3. Only after both did I find a **real** defect: the torso and sash used absolute
   coordinates, so facing left the body leaned left while its base still jutted
   right.

**What I learned.** Two of the three "bugs" were in the test, not the game. The
thing that caught the real one was rendering every state and looking at them,
rather than reasoning about the code.

---

## 4. The prediction that was wrong

**Prediction (P3, written before implementation).** Adding time-sensitive ledges
would break the deterministic route fixture, and the fix might not fit inside the
900-tick budget.

**What actually happened.** It passed on the first run — **631 ticks, 0 deaths.**

**Why.** Before writing any level geometry, Claude built `probe_reach.gd`, which
flies the real player through a jump and reports reach for each landing height.
Peak rise measured **56.00 px**, matching the starter's recorded 56.07. Every gap
was then sized against that table instead of guessed.

**What I take from it.** The prediction was wrong for a good reason, and I have
left it in `CHANGE-BRIEF.md` unedited and marked wrong. A prediction record where
everything comes true would mean nothing was actually risked.

---

## 5. A failure I could not fully explain

**What happened.** The capture harness ran the player onto a dissolving ledge,
stood still, and was supposed to record the death. It recorded the approach, then
reported that no death occurred — despite the same sequence dying reliably when
run headless, and dying when run windowed in isolation.

**What I changed.** Two things: the check now counts `deaths` instead of sampling
for the `DYING` state, because writing a PNG can take longer than the ~34-tick
retry window; and the input is held explicitly on every tick rather than set once.
It has passed every run since.

**What remains unresolved.** *I never established which of the two was the actual
cause, or whether it was something else.* It is recorded here and in
`CHANGE-BRIEF.md` as unexplained rather than quietly fixed.

---

## 6. Being told 3D was not possible

**What I asked for.** A 3D version with a selectable camera POV.

**What I was told.** That the starter's tuning is in pixels — gravity 960 px/s²,
jump −320 px/s, an 18×28 px collider — and that these cannot survive the unit
change to a 3D world. Preserving the movement tuning is a graded requirement, so
3D would have meant failing it. Claude also pointed out the rubric awards nothing
for 3D.

**What I decided.** I accepted the reasoning and asked for visual depth within 2D
instead, which became the parallax strata. **[author]** *Add your own view: was
this the right call, or would you rather have tried 3D and accepted the cost?*

---

## 7. The pivot: "I don't see any creativity or storyline"

**What happened.** With the crumbling-ledge section built and all checks passing,
I looked at it and said plainly that it had no idea in it — it was a competent
platformer level and nothing more.

**That was accurate.** The story had been dropped earlier when the focus moved to
making the level *feel* different, and it was never picked back up.

**What I decided.** I wrote the premise for **THE WORLD IS FALLING** — failing
gravity, environmental storytelling over dialogue, the Feather as an anomalous
technological object rather than a magic item, the observatory, the door line, and
a chapter ending on questions it refuses to answer. I also specified the scope:
**one polished chapter**, with the remaining four documented as design rather than
half-built, because five thin levels would have cost the parts that are graded.

**What did not get thrown away.** The crumbling ledges were kept and reframed.
They are no longer a platformer device; they are matter losing cohesion, which is
the premise. Nothing built before the pivot was discarded.

---

## 8. Gravity reversal without changing the jump

**The problem.** The assignment forbids changing jump strength. The Feather
inverts gravity. Those look like they conflict.

**What was done.** Gravity direction was made **world state** rather than a tuning
value. `tuning.gd` is byte-identical — gravity 960, terminal 480, jump −320. What
flips is the **sign** applied to gravity, to the jump impulse and to
`up_direction`.

**The check that settles it.** `probe_gravity.gd` measured an inverted jump
displacing **56.05 px** where a normal jump rises **56.00 px**. The jump is
mirrored, not strengthened. This is asserted permanently by
`inverted-jump-matches-normal-rise`.

**[author]** *If a TA asks why this is not "changing the jump", the answer is the
number above — say it in your own words.*

---

## 9. Two tests that failed for the wrong reason

**What happened.** The first crumble checks failed. The reported cause looked like
the mechanic was broken.

**What it actually was.** `is_on_floor()` still reported the spawn platform
immediately after the player was teleported, so the test sampled before the fall
had begun. The game was correct; the tests were wrong.

**What I insisted on.** No assertion was deleted or relaxed to get a green
report. The tests were fixed to wait for the landing.

**The one budget that did change,** and why it is not the same thing: the route
fixture's tick limit went from 900 to 2400 because the level is roughly three
times longer. The observed run is 1130 ticks, and that number is printed in the
check so the margin stays visible rather than hidden behind a pass.

---

## 10. The observatory that could not be entered

**What happened.** The automated route reached the end of the chapter and died in
the sky at the level's right edge.

**Diagnosis.** The player reverses gravity and keeps their horizontal speed while
rising, so they drifted *past* the doorway on the way up, landed on the ceiling
beyond it, and ran off the end still inverted.

**Fix.** The observatory was enclosed — a wall added so the player cannot overrun
the shaft. This is a geometry revision, not a physics one, which is the rule I set
at the start: revise the level, never the tuning.

---

## 11. Human playtest

**AWAITING PLAYTEST.**

This section will record what I observed playing the build myself: whether the
charge economy feels scarce or stingy, whether the ceiling run's flip-back moment
is readable, whether the cyan/amber trail is enough to tell me which way up I am,
and whether any death felt unfair rather than earned. Open predictions P4–P9 in
`CHANGE-BRIEF.md` are the specific questions.

Results go in `TEST-REPORT.md`; my reactions go here.

---

## 12. Inspect-and-revise cycle

**AWAITING PLAYTEST.**

The required cycle will be driven by something I actually notice while playing,
not by a scripted run.

---

## Traceability

| Entry | Where to check it |
|---|---|
| Baseline before any edit | commit `2f46177`, `evidence/baseline-starter/` |
| Measured jump envelope | commit `8f91c63`, `godot/tests/probe_reach.gd` |
| Character built from the mechanic | commit `9897723` |
| Harness bugs 1 and 2 | commit `ff2a425` message |
| P3 predicted wrong | commit `be7c35a`, `CHANGE-BRIEF.md` Revisions |
| Unexplained capture failure | commit `60a226a` message |
| Gravity as a sign flip | commit `6c7c210`, `probe_gravity.gd` |
| Tests fixed, not weakened | commit `5cd69aa` |
| Enclosed observatory | commit `953fc21` |

