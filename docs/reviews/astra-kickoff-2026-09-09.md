# Astra kickoff — AA presentation pass

**Date:** 2026-09-09
**From:** Kevin
**Purpose:** the prompt handed to Astra to plan and deliver against `docs/reviews/critique-2026-09-09.md`.

---

Astra — an external critic reviewed the v1.0.0-rc2 build. The review is at
`docs/reviews/critique-2026-09-09.md` on branch `claude/astra-game-critique-i9s5dm`.
Read it in full before doing anything else.

Its headline finding is that RING ZERO is feature-complete and presentation-incomplete: the
game renders a correct picture of its own state and never performs. It traces that to five
root causes — no lighting model (`gl_compatibility` makes glow unavailable; zero `Light2D`
or `WorldEnvironment` nodes), no transient layer (zero tweens, particles or
`AnimationPlayer`s anywhere in `src/presentation/`), no sound design or music (seven
synthesised sine cues, no audio assets in the repo), a 73-line theme with an unstyled
`CheckButton` and hard-coded 1440p pixel layout, and a failed T-079 art gate that RC2
shipped on top of.

## 1. Verify before you plan

Do not take the critique on trust. It cites specific files, lines and evidence images —
check them yourself and tell me plainly where it is wrong, overstated, or missing
something. I would rather have a correction now than a plan built on a bad premise. In
particular satisfy yourself about the renderer claim, the zero-animation claim, the
`CheckButton` theme gap, and the `T-079-crowd-03.png` result, because the plan's priorities
rest on those four.

## 2. Decisions — my answers, so you are not blocked

The critique raises three that it says are mine. Here they are, so you can plan straight
through them. Record each as a proper DECISIONS.md entry with my resolution.

**D-129 — Run structure.** The critique is right that `RunRules.OPERATION_SECONDS := 900.0`
turned the spec's endless run into a timed win, and that nobody recorded it. **My call: keep
the bounded 15-minute Containment run as v1.0's shipping mode.** It is the right scope for a
first release. Record it as a deliberate decision that supersedes §1's endless framing *for
v1.0 only*, note that §2's "watch it climb, then watch it fall" arc is consciously deferred,
and log an endless/survival mode as post-v1 scope. Do not edit the spec.

**D-130 — Audio.** Music and a real SFX bank are in scope. **My call: license a curated
commercial pack rather than commissioning original work**, so this does not gate on a
composer's schedule. Come back to me with two or three specific candidate packs, their
licence terms, and a cost, and I will approve the spend before anything is purchased. Design
the audio system, the bus layout, the event taxonomy and the positional-by-bearing routing
now — that work does not depend on which pack we buy, and `game_audio.gd` should be
retained as a headless/test fallback.

**D-131 — Elite art constraints.** **Granted.** Drop the no-glow / one-cold-accent rule for
elites and the Assembler. Silhouette-first, form-follows-mechanic, self-illuminated accents
allowed, minimum on-screen size floor. Standard machines keep the existing restrained
treatment so the elites read as exceptions. This does not reopen the wider art direction
(D-120 stands).

Beyond those three, **D-033 numeric-tuning authority applies as normal**, and I am extending
it for this pass: you may set presentation values — light radii and falloff, bloom
thresholds, shake magnitude and decay, effect durations, LOD zoom thresholds, spacing and
type-scale tokens — on your own authority, recorded as provisional. Come back to me for
anything that is a *rule* or *creative* choice, not a number.

## 3. What I want from you

Plan it properly first, in the discipline you already run:

1. **DECISIONS.md** — D-129/D-130/D-131 entries with my resolutions above, in the standard
   format, plus the two process findings in §8 of the critique. I want the "a failed
   acceptance gate blocks the release-candidate label" rule recorded as a standing Tier 1
   decision.
2. **BUILD-PLAN.md** — a new phase for this pass, with the six workstreams, ownership across
   Sol/Terra/Luna, dependencies, and exit checks. The critique's §7 sequencing is a
   recommendation, not an instruction; if you have a better order, take it and say why.
3. **TASKS.md** — the task table starting at T-081, with `### T-0NN — Done condition`
   sub-sections carrying the concrete acceptance bar for each of the larger ones.
4. **`docs/contracts/`** — a written contract per delegated task before any of it is
   delegated, same as every previous phase.

Then show me the plan before you start building. That is the one stop I want.

## 4. Then deliver it

After I sign off the plan, orchestrate the work with subagents, one per workstream, briefed
from its contract. You review every delivery against its exit check and integrate it — you
do not implement.

Constraints on the orchestration:

- **Sequence around file collisions.** Workstream A (renderer/lighting) and Workstream D
  (theme and layout) both touch the presentation layer broadly, and D's layout task rewrites
  `application.gd`, `live_view.gd` and `release_view.gd` wholesale. Do not run those two in
  parallel against the same files. Fan out where the work is genuinely disjoint — audio
  system, elite art briefs, swarm LOD — and serialise where it is not.
- **Retire the performance risk first.** The renderer switch is the only change that could
  regress the frame budget. Do it early, re-run the performance suite against
  `docs/reviews/presentation-v2/native-performance.txt`, and stop and tell me if it is worse
  than 10%.
- **The 39 suites stay green.** Any delivery that regresses them comes back to its agent.
- **Evidence, not assertion.** Every workstream lands with before/after captures in
  `docs/reviews/`, taken the same way the existing release evidence was. For ring collapse
  (T-083) I want video or a frame sequence, not a still.
- **Do not ship through a failed gate.** If an acceptance check fails, it fails — bring it
  to me rather than deferring it and continuing, which is exactly what happened with T-079.

Start with the cheap high-visibility fixes so I can see movement early: the `CheckButton`
styling is roughly an hour and fixes the single most visible amateur tell in the build.

## 5. Reporting

Check in when the plan is ready for sign-off, when a workstream lands, when a gate fails,
and when you need a decision. Do not check in to tell me a subagent started. If you hit
something the critique did not anticipate, say so rather than absorbing it silently.

The bar is the critique's own framing: the five quick wins take this from amateur to
credible indie. I want the rest of the distance too.
