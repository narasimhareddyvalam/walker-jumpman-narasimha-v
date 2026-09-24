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

I played the build myself at revision `4415f78`. What I reported afterwards,
word for word:

> *"few things, the story line isnt clear from start. blocks and all are not
> falling from up and also its not clear where to click F and invert and play
> upside down"*

None of the three things I noticed were things we had predicted. We had written
P10–P13 before I played — whether the Betrayal would feel cheap, whether light
mode would hurt readability, whether inspecting would feel too expensive,
whether the two palettes would read as one place. **I never got far enough to
form an opinion on any of them**, because I could not work out where to press F.

That is the finding. The chapter had a hard dependency on a key it never taught,
and every automated check passed anyway, because the route fixture is *told*
where to press it. 54 machine checks and a scripted run that completes with zero
deaths could not see a defect that stopped a human in about ninety seconds.

The other two were softer but real. The opening still carried the starter's
tutorial signage (`01 / GET MOVING`), so the game began with instructions rather
than a premise. And the upward-falling debris — the single image the whole story
rests on — was drawn at 2–4 px and 20% alpha, which is to say it was not really
drawn at all.

---

## 12. Inspect-and-revise cycle

Three observations, three changes, and one of the changes was wrong the first
time. That failure is the part worth recording.

**The F affordance.** A `pads` array now marks the floor at every one of the
five reversals the chapter requires, drawn as a pulsing strip with chevrons
rising off it, and the HUD shows `PRESS F TO FALL UPWARD` when I am standing on
one with a charge in hand. It only appears when pressing F would actually do
something — a prompt that lied about this, in a chapter about unreliable
information, would be an own goal. Three checks, all watched failing first.

**The opening.** Replaced the starter's tutorial text with signage that carries
the premise and the controls at once: `SITE 07 / DAY 41`, *The debris stopped
falling down*, *Nobody left here knows why*, then the walk and jump keys. The
title card says what is wrong and what to do about it instead of *"Something is
wrong with the ground."*

**The debris, twice.** The first fix raised the count to 46, enlarged the
pieces, and gave each one a trailing line to show direction. I looked at the
recapture and it was worse than the original: forty-six squares each dragging a
vertical stick, evenly spaced, reading as pins rather than as falling matter. My
reaction was *"i dont like the debris"*, which was correct.

The second fix went the other way — **14** pieces, no trails, each one a
rotating silhouette of something from the site: a floor slab, a length of rebar,
a torn wall panel, a chair. Rotation is what communicates a free fall. A trailing
line does not; it communicates a line.

I am keeping the failed version in this log rather than describing only the
version that worked. Going from invisible to visible-and-wrong to right took
three attempts, and only the third is in the build.

**One thing led to another.** Asked for platforms that were not plain
rectangles, we split `_draw_slab` by thickness — thick blocks became building
rooftops with lit windows, thin ledges became the facility's service catwalks.
That immediately broke something else: the window grid sits behind the HUD's
bottom row and the controls line stopped being readable. Found by looking at the
capture, not by any check, and fixed with a backing band. Changing how the world
is drawn broke how the interface reads, which is not a connection I would have
predicted.

---

## 13. Writing for a player, not for myself

Second round of feedback, and it was about words rather than code. I said the
storyline was not clear and that a five-year-old should be able to follow it.

Reading the game back, the criticism was obviously right. Lines like
*"Recovery: one object. It does not fall. It is not ours."* are written to be
re-read. Nobody re-reads a sign while running right at 160 pixels per second.
Everything had been written to sound good rather than to be understood at speed.

All of it was rewritten in short, plain sentences. `SITE 07`, `SUBJECT 07`,
`EVACUATION ORDER 09` and `GRAVITATIONAL RESEARCH` are gone — they were
atmosphere pretending to be information. The observatory is now just *the
tower*. The story is: gravity broke, everything falls up, everyone ran, I
stayed, I found a feather that falls up, and at the end I find out I built this.

I also asked why the warning signs only showed up near the puzzles at the end. I
had not noticed that: by the time the game first lies to you, you have had no
practice reading its signs at all. There are signs from the first screen now.

And the screenshot I sent showed three layers of text on screen at once — a log
banner, the ability card and two world signs. A log picked up while the card is
showing now waits its turn.

---

## 14. Guessing twice, then measuring once

The sky-death capture started failing its assertion. I watched Claude guess the
cause twice — both times blaming which ceiling the route ran off — and both
times it was wrong. Worse, the second guess went into the repository as a
comment confidently explaining a reason that was false.

Then it stopped and wrote a throwaway probe instead of guessing again. One run
settled it: the original ceiling killed the player perfectly well headless. The
real cause was in the test harness. A `capture()` call costs about 33 physics
ticks while the engine keeps running, and the death count was being sampled
*after* that call — so the death happened inside the screenshot and was never
observed.

Two things I take from this. First, the fix was in a place neither guess had
looked at, and only instrumenting found it. Second, the wrong comment was
arguably the worse artifact: a failing assertion announces itself, but a
confident false explanation sitting in the source does not. It has been
corrected in place and the history notes that it was wrong.

The same measurement had a consequence we had to accept rather than solve: if a
capture takes 33 ticks and the death-and-retry window is 33 ticks, then a
photograph of the moment of death cannot be timed reliably. Rather than ship a
picture that might be of the respawn and call it a death, those shots are now
named for what they actually show, and the death is evidenced by the assertion
and by the `sky-is-fatal` check.

---

## 15. Teaching the world to speak without words

**What I asked for.** I said the game should stop telling the player what to do
and let the environment communicate through visual language — a chair resting
on a ceiling, rubble pooled on the wrong side, objects that only one gravity
could have put there.

**First attempt, rejected.** Claude built nineteen scattered props and I said
they looked like decorative items, not gameplay, and that the whole thing felt
clumsy. I was right, and the diagnosis that came back was sharper than my
complaint: objects sitting *on* a surface are scenery, because they mark
nothing you can stand on and have no edges. At 640×360 nineteen of them are
just noise.

**What I had also missed.** The glowing pads were still at every reversal point
with animated chevrons. So the props were decoration layered on top of a system
that was still doing all the telling — the player never had to read anything.

**Where it landed.** Props kept, but the pads lost their text everywhere except
the **first** one. That first prompt stays deliberately. My own round-one
playtest ended with me unable to find `F`, so removing every prompt would have
reintroduced the exact failure we already hit. The verb is taught once, in
words, then the environment carries it.

**Unresolved.** A stricter version with no pads at all is the better expression
of the idea and is not built. I am not confident it would be playable, and
there was no time left to find out.

---

## 16. A tool found a defect I had defended as a design choice

**What happened.** The Brutalist render pipeline has a visual QC gate. It
refused the film and reported the HUD text at 0.03–0.30 luminance separation
against a 0.3 minimum.

**My first instinct was that it was wrong** — a minimal HUD was a deliberate
choice, and the gate was applying card heuristics to full-frame gameplay.

**Two of the three complaints really were mis-fires**, and the skill has a
sanctioned way to say so: declaring the beat full-bleed, because the game does
render edge to edge, and declaring which regions carry the essential text,
because the pale palette is the mechanic rather than a rendering fault.

**The third was real.** Minimal had drifted into faint. The HUD is the one thing
on screen a player cannot work out by looking at the world, and in light mode
the controls row was grey on grey. That got fixed in the game — opaque bands,
stronger text tones in both palettes — and every capture was re-made from the
corrected build.

**And I got one of my own declarations wrong.** I had named the feather readout
as essential text. The gate returned nine "empty region" defects, correctly,
because that element does not exist until the player picks the feather up. I
removed the declaration rather than working around it. Claiming a conditional
element as persistent text would have been a false statement about the frame,
which is exactly the kind of thing the gate exists to stop.

**What I take from it.** The gate cannot judge whether an explanation is true.
But on the one thing it *can* measure it was right, and my instinct to defend
the design was wrong.

---

## 17. Four capture bugs, and two pieces of evidence that lied

Recording these because two of them produced footage that looked completely
fine and was wrong, which is worse than a crash.

1. **The game would not start.** `Input.action_press` sets polling state but
   synthesizes no event, so `_unhandled_input` — which handles Enter, Escape and
   R — never saw it. Real `InputEventKey` objects fixed it.
2. **The player froze for 2.5 s after every flip.** The driver held the walk key
   released until a charge was available, which is never true immediately after
   spending one. On a ceiling that was long enough for the reversal to expire
   underneath them. The game was correct; the driver was wrong.
3. **A held key stopped arriving.** Godot flushes pressed input when the window
   loses focus, so an unattended capture recorded the player standing still at
   x=213 for ninety-seven seconds. Held keys are now re-asserted every tick.
4. **Every clip ran past its own window.** I passed `-t` twice as an ffmpeg
   output option and the second silently won, so each clip played about twelve
   seconds of continuous footage instead of its intended span. One beat ended on
   the spawn screen while the narration described the endgame. The "held frames"
   the build script had been reporting were never produced at all.

The first three were caught by assertions the driver makes about its own run.
The fourth was caught by looking at a frame — no assertion covered it, because
the clip was valid video of real gameplay, just the wrong part of it.

**The lesson I actually take from this:** a green check and a correct artifact
are different claims. Three of these four passed every automated gate.

---

## 18. Making the film say what the work was

**What I noticed.** I watched the first finished cut and my name was nowhere in
it, and it spent far more time on limitations than on what the game actually
does. Both were wrong in different directions — one omits a stated requirement,
the other misrepresents the work by undersell.

**What changed.** A credit on the "what was built" card and a dedicated credits
beat naming the design calls, alongside what Claude contributed and what it got
wrong. The verdict reordered to lead with four things that demonstrably work
before the two open questions. A new beat on where the design goes next.

**What deliberately did not change.** The open questions stayed in. "What
remains uncertain" is a required element of the film and the honest answer is
that whether the Betrayal is fair and whether the clues are legible are things
only a player can settle. Leading with the achievement and being straight about
the limits is not a compromise between the two — it is just the accurate order.

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
| Enclosed tower | commit `953fc21` |
| Environmental props, first-pad-only prompt | commit `c55bb9b` |
| Plain-language rewrite | commit `dc93f27` |
| HUD contrast defect found by Gate V | commit `c898a4b`, `_qc/REPORT.md` |
| Clip-trim bug; author credit and verdict | commit `fc5d2ac` |
| Fresh-clone verification | commit `6154f56`, `SUBMISSION.md` |
| INVERSION rule and the Betrayal | commit `83685d3` |
| Evidence that photographed the wrong moment | commit `3233366` |
| Two wrong diagnoses, then a probe | `CHANGE-BRIEF.md` Revision 5 |

