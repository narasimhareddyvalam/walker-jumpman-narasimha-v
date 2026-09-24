# THE WORLD IS FALLING — Game Design Document

**Author:** Narasimha Reddy Valam · **Assisted by:** Claude Code (Opus 5)
**Built on:** [nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman) @ `9387542`

> **Read this first.** Only **Chapter One: The Fall** is implemented. Everything
> under "Chapters not built" is design on paper — no code, no level data, no
> assets exist for it. It is recorded here so the shipped chapter can be judged
> as the opening of something, rather than mistaken for a whole game.

---

## Premise

The laws of physics are failing. Not dramatically, at first — a rock falls the
wrong way, debris hangs where it should have landed, a skyline sits upside down
on the horizon. The player is trying to move forward and work out what happened.

Nothing is explained by a narrator. The story is carried by what the level does
and what the player finds in it.

## Design rule the whole game obeys

**Every major object serves three purposes at once:**

1. a gameplay mechanic,
2. a platforming/puzzle tool,
3. a piece of the story.

An object that only opens a door is a key, and this game does not use keys.

| Object | Mechanic | Tool | Story |
|---|---|---|---|
| 🪶 **The Feather** | reverse gravity, limited charges | reach what is above you | the failure can be *used* |
| 🧿 **The Eye** | reveal hidden geometry briefly | see paths that are not there | the world is already partly gone |
| ⏳ **The Clock** | freeze moving objects | cross what will not hold still | you have done this before |
| 🔮 **The Mirror** | swap to a reflected world | navigate two versions of a room | there is another you |

---

## Chapter One: The Fall — **BUILT**

This is the chapter that exists and runs. Full verification is in
`TEST-REPORT.md`; predictions and findings are in `CHANGE-BRIEF.md`.

### Shape of the chapter

1. **The familiar world.** The starter's original route, preserved and playable.
2. **The ground stops holding.** Ledges dissolve a short time after they are
   stood on. Signage reads `SITE 07 / GRAVITATIONAL RESEARCH`, then
   `STRUCTURAL COHESION FAILING`.
3. **A fork.** The upper gantry is quick and passes a hazard; the lower deck is
   longer and dissolving. Failing the upper line drops the player onto the lower
   one rather than killing them.
4. **The Feather.** An object falling upward in place. Touching it grants
   charges. Nothing explains it.
5. **The teaching gap.** A gap too wide to cross by jumping, under a ceiling.
   The only way on is to invert. The player learns by necessity.
6. **The ceiling run.** Inverted traversal along the underside of the facility,
   with the reversal window running down. Flip back too early and fall short;
   too late and run off the end into the sky.
7. **The observatory.** `ONLY THOSE WHO CAN FALL UPWARD MAY ENTER.` The finish
   sits inside a shaft above the floor, reachable only while inverted.
8. **The reveal.** `THE LANDSCAPE IS FLOATING. GRAVITATIONAL FAILURE / SPREADING.`
   Then two questions, unanswered: *What was the Feather? Why could you use it?*

### The Feather, as implemented

- Charges are scarce: two Feathers grant three charges total.
- Two reversals are **mandatory** (teaching gap, observatory door); one is an
  optional shortcut. Spending the shortcut leaves exactly enough.
- `F` (or Shift) spends a charge and inverts gravity for 180 ticks.
- Pressing `F` again cancels early and **does not refund**, so choosing when to
  flip back is a skill rather than a free option.
- The window also expires on its own. Being somewhere fatal when it does is the
  player's mistake, not the game's.
- Falling upward out of the level kills, exactly as the pit does.

### Decisions the chapter asks for

| Decision | Cost of getting it wrong |
|---|---|
| Spend a charge on the shortcut, or walk the dissolving route? | arriving at the door with nothing |
| When to flip back on the ceiling run? | too early: fall short. too late: the sky |
| Keep moving on dissolving ledges, or read the next jump first? | the ledge does not wait |
| Upper gantry or lower deck at the fork? | the hazard, or the timer |

---

## Chapters not built

**None of the following is implemented.** No code, level data, or assets exist.

### Chapter Two — The Forest Below
An inverted forest where some platforms hang from the ceiling. The Feather stops
being an unlock and becomes a routing tool: the player now chooses *which*
surface to travel on. Ends on **the Eye**, which reveals hidden geometry for a
few seconds — and, once, shows a figure standing exactly where the player is
standing.

### Chapter Three — The City That Doesn't Exist
Built around the Eye and the Feather together. Paths exist that cannot be seen;
revealing them costs time, and they must be *remembered* once the vision fades.
Ends on **the Clock**, which stops everything for three seconds — and displays a
line the player has no reason to understand yet: *you have used this before.*

### Chapter Four — The Gravity Engine
Three tools in combination: freeze a rotating platform, invert, cross, restore.
The chapter's real content is the turn: the objects the player has been
collecting to repair the world are components *of* the machine, and every one
recovered makes it stronger. Ends on **the Mirror**.

### Chapter Five — The Other World
Some geometry exists only in the reflection. The player navigates two versions of
the same space, switching between them mid-traversal.

**The reveal:** gravity was never breaking. Reality was ending, and the
Gravity Engine was the only thing holding it together. The protagonist built it,
understood what it would cost, and erased their own memory rather than carry it.

**The choice, left to the player and never graded by the game:**
- **Restore** — put the objects back. The world returns to normal, and everything
  seen during the game is lost with it.
- **Break** — take them out. Gravity collapses completely, and the world becomes
  something else.

---

## Tone

Abandoned research facilities, industrial structure, fog, silence, floating
debris, impossible architecture, minimal interface. The player should
consistently feel that *something went badly wrong here* without being told so.

Every section ends on a reveal or an unanswered question. Chapter Two should
answer one question and raise two more. Nothing is explained on first sight.

## Honest scope note

Chapter One was scoped to what could be built, tested, played and explained
within one assignment window. The remaining chapters are deliberately left as
design so that the built chapter is not thinned out to gesture at all five. A
convincing opening is worth more than five unfinished fragments.
