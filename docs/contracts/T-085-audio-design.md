# T-085 — Free online AI audio, score and event mix

**Date:** 2026-09-09. **Status:** Approved under D-135; assignment follows dependency gates. **Workstream:** C. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. Kevin approved D-135 on 2026-09-09. This contract is authorized subject to its dependency gates and Astra's explicit file lease.

## Dependencies

D-135; D-130 source strategy resolved. Generation source admission must pass before using outputs. B's event contract for final wiring; exclusive integration lease for application/view hooks.

## Editable scope

src/presentation/game_audio.gd; new src/audio/ helpers; assets/audio/; data/audio/; default_bus_layout.tres if introduced; scripts/audio/; docs/audio-generation-plan.md; task-specific audio tests and provenance. C does not edit application.gd/live_view.gd/release_view.gd while A/B/D/E holds them; final hook lease is scheduled separately.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Follow docs/audio-generation-plan.md: generate music through the free ACE-Step online demo; generate SFX through a qualifying free Stable Audio online demo after exact-model/host rights are checked. Curate, trim, layer and master downloadable audio locally, preserve originals/prompts/seeds/terms, and spend nothing. Build a quiet menu piece, an evolving run bed with low/pressure/climax states, a distinct boss treatment and outcome stingers. Mechanical low-frequency mass, dry metal transients and electrical texture carry the fiction; no vocals or artist imitation. Give five weapons separate fire/impact identities, machine destruction variety, elite/Assembler arrivals and mechanics, relay/brownout/core warnings and UI/action outcomes. Add Master/Music/SFX/UI/Ambience routing, voice priorities, limited pitch/sample variation, screen-bearing panning and music ducking for critical events. Preserve pause/settings/clean teardown and a quiet deterministic headless fallback; shipping audio cannot silently fall back to seven old cues.

## Done condition

Source register verifies $0 spend, generation/download availability, exact applicable commercial-use terms and any license eligibility; unresolved rights block asset admission. Five-minute headphones review and a fifteen-minute mixed-game recording show no obvious loop seam, clipping, repeated short stock-like cue fatigue or masked critical warning. A blind left/right danger test scores at least 9/10; five weapon identities score 9/10 after a reference. Different north/south threats have visual support because stereo alone cannot prove full 360-degree localization. Mute/bus sliders, saved levels, pause, rapid scene changes and quit pass; 42+ suites and native performance remain green. Human listening acceptance is recorded, not asserted by code.

## Evidence

Before/after native audio loopback on identical action traces, indexed cue audition reel, 5/15-minute mixes, source and edit manifest, bus/peak/voice-count measurements and listener results. Save under `docs/reviews/presentation-v3/T-085/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Frozen audio event IDs, accepted files/licensing hashes, bus map, priority/ducking/panning conventions and provisional mix values.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.
