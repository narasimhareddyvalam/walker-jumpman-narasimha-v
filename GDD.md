# THE WORLD IS FALLING — Game Design Document

**Project:** `walker-jumpman-narasimha-v` · extends the `walker-jumpman` starter
**Status:** Chapter One is **built and playable**. Chapters Two to Five below are
**design only** — no code, no level data, no assets. Nothing in the unbuilt
section exists in the repository, and this document says so at every heading.

---

## The story, in plain words

Gravity broke. Everything started falling **up** instead of down.

Everyone ran away. You stayed behind to find out why.

You find a **feather** that falls upward. While you hold it, you can fall upward
too. That is how you cross the places nobody else could.

At the end of the chapter you reach the tower — and learn that you are the one
who broke gravity in the first place.

That last line is the chapter's turn. It answers *why does the feather obey
you?* and immediately opens *what were you doing here?* — which is where Chapter
Two starts.

---

## The one rule the whole game obeys

> **The world shows you what you expect, not what is there.**

Everything in the game follows from that single sentence:

- A floor can be **real but not drawn** — you walk on nothing and it holds.
- A floor can be **drawn but not real** — it looks solid and you fall through.
- Spikes can be **invisible and deadly**, or **visible and completely harmless**.
- A wall can look locked and let you walk straight through it.

And there is always a way to check: **turn gravity upside down.** Inverted, the
world stops flattering you and shows what is actually there. The lie is bright
and comfortable; the truth is dark.

This is why the palette flips. Light is the lie. Dark is what is really there.

It is also why the check has to be cheap. The Feather recharges in 2.5 seconds
rather than being rationed — a game about checking cannot charge you for
checking. (An earlier build made charges scarce. Players stopped inspecting,
which broke the whole point. Recorded as P12 in `CHANGE-BRIEF.md`.)

---

## Chapter One: The Fall — **BUILT**

### What the player does, in order

| Beat | What happens | What it teaches |
|---|---|---|
| **The break** | Rubble tumbles upward past you. Signs say the world falls up. | the premise, before any mechanic |
| **Falling ground** | Ledges crumble seconds after you touch them. | keep moving |
| **The fork** | A high road and a low road, both survivable. | the level has opinions, not one path |
| **The feather** | Picking it up announces a power: you can reverse gravity. | you have a verb now |
| **The ceiling runs** | Marked pads show where to flip. You run on the underside of the world. | using the verb |
| **The Void Gap** | A chasm with nothing visible below. Walking in, a hidden floor catches you. | *things exist that you cannot see* |
| **The reveal** | Flip while standing there — the floor renders as a lattice. | *inverted sight shows the truth* |
| **The Betrayal** | An identical-looking gap. This one is genuinely empty. | **don't trust the rule — trust the tool** |
| **The Phantom** | A platform drawn exactly like real ground. It holds nothing. | the lie works both ways |
| **The locked door** | A bulkhead marked `DOOR LOCKED`. You walk straight through it. | signs are claims, not facts |
| **The spike corridor** | The floor is lethal end to end. Ceilings above crumble as you hang from them. | pressure, not trickery |
| **`SAFE`** | A clear stretch of floor with invisible spikes in it, and a mirror ledge above that only exists inverted. | the last and worst lie |
| **The tower** | The exit is above you. Only falling upward gets you in. | the chapter's thesis as a door |

### The Betrayal is fair, and here is why

It kills you using the lesson the previous screen taught. Three things keep it
honest:

1. A sign above it reads `THIS GAP IS EMPTY / Go up instead.`
2. Flipping reveals the truth before you commit, and flipping is nearly free.
3. The ceiling route across it is visible from the approach.

The punishment is for **assuming**, never for failing to read minds.

### The Feather, as implemented

| | |
|---|---|
| Acquired | one pickup, which grants the ability permanently. Before it, `F` does nothing. |
| Charges | exactly one, never stacking |
| Recharge | `RECHARGE_TICKS = 150` (2.5 s) |
| Duration | `REVERSAL_TICKS = 180` (3 s), then gravity restores on its own |
| Cancel | `F` again, early, at no refund — *when* you flip back is the skill |
| Death | falling upward out of the level is as fatal as the pit |
| Readout | the character's trail is amber upright, cyan inverted. The HUD says READY / INVERTED / RECHARGING. |

**Gravity reversal is a sign flip, not a tuning change.** Every value in
`tuning.gd` is byte-identical to the starter's; only the *direction* applied to
gravity, the jump impulse and `up_direction` changes. Measured: an inverted jump
displaces 56.05 px where a normal jump rises 56.00 px.

### How the illusions are built

The starter already iterated the level's solids twice — once to build colliders,
once to draw them. The whole mechanic is the difference between those two loops:

| Level data | In the collider loop? | In the draw loop? |
|---|---|---|
| `solids` | yes | yes |
| `hidden` | yes | only while inverted |
| `phantom` | **no** | only while upright |
| `mirror` | only while inverted | only while inverted |
| `hazards` | yes | yes |
| `hidden_hazards` | yes | only while inverted |
| `phantom_hazards` | **no** | only while upright |

No new node types. No collision check was removed — hidden geometry *adds*
colliders and phantom geometry adds none.

---

## Chapters not built — design only

**None of the following exists in code.** They are recorded so the shape of the
whole game is legible, and so Chapter One's ending has somewhere to point.

### Chapter Two — The Forest Below
The world is upside down and stays that way. Platforms hang from a ceiling that
used to be the ground. Introduces **objects that only exist while you are not
looking at them** — the camera's facing becomes a mechanic.

### Chapter Three — The City That Doesn't Exist
Perception, not gravity. Whole districts render differently depending on the
direction you approach from. Introduces **the Mirror**: a second object that
swaps what is solid with what is drawn, everywhere, at once.

### Chapter Four — The Memory
You start finding your own handwriting. Rooms you have never visited are
familiar. Introduces **the Clock**, which rewinds a room to a previous state —
including states you caused.

### Chapter Five — The Other Side
The reveal: the inversion was not an accident, and there is a second world that
has been running the same experiment in the opposite direction. Two endings —
restore gravity and erase yourself, or keep the world inverted and remain.

### Objects across the arc
Every major object is meant to be three things at once — a movement mechanic, a
puzzle tool, and a piece of the story.

| Object | Manipulates | Chapter |
|---|---|---|
| The Feather | gravity | One — **built** |
| The Eye | observation | Two |
| The Mirror | perception | Three |
| The Clock | time | Four |
| The Engine | the rule itself | Five |

---

## Tone

Dark, quiet, industrial. No enemies, no combat, no dialogue trees. The story is
found, not told: environmental signage plus six collectible log fragments, each
one line long. Nobody explains anything to the player directly.

Signs are written the way a frightened person writes them — short, practical,
sometimes wrong.

---

## Honest scope note

Chapter One is roughly five times the length of the starter's route and is the
only part that exists. The chapter list above is a design sketch: it has no
level data, no assets, no prototypes, and no schedule. It is included because
the assignment asks what the extension *is*, and Chapter One's ending only makes
sense if you can see what it opens onto — not to imply more was built than was.
