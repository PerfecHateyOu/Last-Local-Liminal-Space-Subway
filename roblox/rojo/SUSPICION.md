# Last Local (Roblox) — Suspicion System Design

A design note for suspicion in the Rojo slice. Builds on the flag mechanic
(see `README.md`, `src/client/Flag.luau`, and `src/server/Ride.luau`). Tuning
numbers are starting values to playtest, not verified results. Anything marked
TBD is undecided — do not fill it in from a guess.

## Port notes (current code)

**Already in this port**

- Server-owned meter 0–100 on `ReplicatedStorage.Ride` attribute `Suspicion`.
- Bands from `Shared.Band` / `Constants` thresholds: **0–24 calm**, **25–49 uneasy**,
  **50–74 watched**, **75–100 hunted**. Published as Ride attribute `Band`.
- Flag deltas and per-stop decay via `Shared.Score` (correct flag −5, false alarm
  +10, clean stop −7 including decay, miss decay only −2). Reaching 100 does
  **not** end the ride.
- Band effects: uneasy glances + occasional one-tube blink; watched heads turn +
  PA word-repeat; hunted slow dim. Client `Glance.luau` poses heads from `Band`.
- On-screen meter in `Hud.luau`: **`25 UNEASY`**-style label from
  `Lines.suspicionMeter` plus a fill bar. Display only — do not recompute bands
  on the client.
- Per-stop feedback words: Caught / Missed / False flag / Clean.
- Parent chats (`Dialogue` / Route `chat`) and first-tier mask prompts: odd
  answers +15 (`MASK_FAIL_SUSPICION`), hesitation +8 (`MASK_TIMEOUT_SUSPICION`).
  Sanity meter + HUD tier (high/medium/low/critical); stop bands + drift;
  Safe Haven restores +15; mask fail/timeout, trial, restraint, and
  intervention nudge sanity inside the current stop band.
- Greenpoint Av **restraint**: hold Space/F for 15s; success raises the
  11–13 sanity ceiling; fail +15 suspicion. Walk locked while active.
- Concerned **intervention** at suspicion ≥ 60: parent lines, reset to 40,
  −5 sanity. Does **not** end the ride (no hard fail at 100).
- Court Square **exit choice** + `resolveEnding` Travel Report (peak,
  interventions, trials, sanity retained, accuracy, restraint, tapes, exit).
  Peak 100 still resolves an ending; it never invents a fail-at-100 game over.
- Safe Haven at Myrtle–Willoughby: step off → platform linger + `HasRecorder`;
  stay aboard → `refuseHaven` +10. Train handoff if you skipped the platform.
- False Stop Trial on non-forgiving false step-offs: path/board rounds, lying
  signs, chime+light (and board door) tells. Exit applies +20 suspicion and
  −20 sanity; Mom/Dad pull-you-back lines; ride resumes.
- Tape recorder / EVP after `HasRecorder`: raise, tune, lock, hold-to-record,
  Evidence tape list + playback (TapeGlance may turn a head).

**Added in remaining-suspicion pass**

- Caught-staring: Gaze remote + dwell; +15 while looking at a live anomaly when
  parents are alert (watched/hunted, or hold `StareIntervalScale` > 1 on uneasy+).
  Prolonged stare at Mom/Dad is +5. Hold multiplier shortens the dwell need.
- False-stop react: standing near an open door leaf during a false-stop dwell
  (+10). Early-departure hook stays **false** on purpose (passenger, no dispatch).
- Psych Log on the Travel Report (ride-local seen / documented catalog entries).
  Persistent Case Files remain MetaStore (PR15).
- Band-tuned parent masks (calm / uneasy–watched / hunted tiers) and hunted chat
  overlays. Critical **glitch** UI (PARANOID_UI_WORDS) stays out.
- Sitting-still extra decay on clean stops; flicker tick scales at watched/hunted.

**Still not in this port (TBD)**

- Critical-tier mask glitch UI and nightmare glance/bulb extras beyond cruise/speed/drift.
- Inventing new Court Square ending variants by final band alone (resolveEnding
  already uses peak, trials, tapes, exit, restraint, interventions).
- Polaroid-inside-trial polish.

The player is a passenger: the kid riding with Mom and Dad, the same as the web
game. Decided. They are not a conductor. See §5.

`roblox/exporter/` is a different track. Its `addSuspicion` ends the ride when
suspicion reaches 100 (phase `end`, ending EXPOSED). That conflicts with §12,
"No fail state in the slice." **Resolved for Rojo (PR13):** the product
decision is **no hard fail at 100**. Suspicion clamps; a Concerned
Intervention may fire at 60+ (reset to 40, −5 sanity, ride continues).
`Constants.SUSPICION_HARD_FAIL = false`. The exporter ending is not copied.

## The slice this is for

One G-train car, Hoyt–Schermerhorn → Court Square (13 stops). Already in the
slice: the flag mechanic, suspicion meter + bands, false stops at Classon Av and
Metropolitan Av, the Safe Haven at Myrtle–Willoughby (recorder unlock), the
False Stop Trial, the blackout after Myrtle–Willoughby, and the Court Square
score sticky, and the tape recorder / EVP after haven unlock. Not in the slice
(out of scope here): cars A and C, the Polaroid camera, Case Files persistence.
A minimal sound bed (PA chime, rumble, door latch, clacks, mute) is in;
ride-music decay, full EVP hiss bed, heartbeat, and intercom voice are not.

The video that fed early drafts: *ROBLOX: Conducting an R62A 1 Train in NYC
Subway: Automated* (Tako Elevators) and the game it shows, *NYC Subway:
Automated* by Automated Transit Studio
(https://www.roblox.com/games/13804003310/NYC-Subway-Automated). Ideas taken
from it are listed under "Borrowed from the video" in each section.

## 1. What suspicion is

Suspicion is the car's attention on you: how much the passengers, the
conductor, and the train itself have noticed you noticing things. It is a
0–100 meter, shown on screen (display-only — the HUD reads **"25 UNEASY"** at
25 with the Rojo band thresholds below).

- **0–24 CALM** — nobody is paying attention to you.
- **25–49 UNEASY** — glances. A passenger looks up when you move.
- **50–74 WATCHED** — heads turn. The car feels aware of you.
- **75–100 HUNTED** — the car is waiting for you to slip.

Suspicion is server-authoritative. The client only displays it. Flag
validation (caught or false flag) already lives on the server in
`src/server/Ride.luau`. A caught-staring check is not in this port (TBD).
Everything below follows that rule: the server decides, the client displays.

## 2. What raises suspicion

| Cause | Amount (starting value) | Notes |
|---|---|---|
| Caught staring at an active anomaly | +15 | Wired: Gaze dwell while parents are alert (watched/hunted or hold scale). |
| False alarm — flagging when no anomaly is active | +10 | Applied when a flag lands while no tell is up and the poster has not changed. Flagging the wrong person while a tell or the poster is up does not add this. |
| Reacting at a false stop | +10 | Wired: near an open door leaf during a false-stop dwell. |
| Leaving before the dwell ends | +10 | Stays off. The player is a passenger and cannot depart. See §5. |
| Staring at a parent for too long | +5 | Wired: prolonged Gaze on Mom/Dad. |

## 3. What lowers suspicion

| Cause | Amount (starting value) | Notes |
|---|---|---|
| Decay over time | −2 per stop with no incident | Applied on a miss and on a clean stop. A miss does not also raise suspicion. |
| Correct flag — flagging while an anomaly is active | −5 | Applied when the flag is noticed. The screen still says Caught. |
| Completing a stop cleanly | −5 | Applied with the decay, so a clean stop is −7. Arrive, dwell, depart, nothing flagged, no anomaly on that stop. |
| Sitting still and looking away | −2 per stop | Wired on clean stops when movement this stretch is under the threshold. |

## 4. Per-stop result

At the end of each stop the server reports one result. The screen shows it
briefly. The suspicion meter stays visible. The Psych Log is still not in this
port (TBD):

- **Noticed** — you flagged an active anomaly. The screen says Caught.
- **Missed** — an anomaly was active and you never flagged it. Suspicion
  does not go up. Decay still applies when you also did not flag.
- **False alarm** — you flagged while no tell was up and the poster had
  not changed, and you did not catch an anomaly. The screen says False flag.
- **Clean** — no anomaly on that stop, no flag. The screen says Clean.

A catch is reported over a false alarm, and a false alarm over a miss.
A missed anomaly stays in the Psych Log once that log exists.

## 5. Dwell time (passenger)

The player is a passenger: the kid riding with Mom and Dad, the same as
the web game. Decided. They are not a conductor. They do not work the
doors, and they do not dispatch the train. There are no door controls.

The video's game is conductor-only. This slice keeps the pressure and
leaves the player powerless: the train drives itself.

- Every stop shows a **MINIMUM DWELL TIME** banner with a countdown. It is
  a pressure timer. The player watches it and cannot change it. The server
  keeps the doors open for the full dwell.
- The early-departure penalty stays off. The player cannot leave early.
  The hook remains in the server, intentionally unused.
- Reacting at a false stop is +10 when the player stands near an open door
  leaf during that dwell.
- An **Early / Late** timer runs against the schedule. Being late does not
  raise suspicion directly; it raises tension (see §8, TBD).

## 6. Held at signal (borrowed from the video)

Between stops, the train can be **Held At Signal**: it stops in the tunnel
for a few seconds with no station in sight.

- During a hold, one light strip or tube flickers, or the car dims slowly.
  The whole car does not flicker or go black. Only the existing flicker
  tick may do that (the lighting rule calls it the door tick: after
  Myrtle–Willoughby and at 21 St). A hold is not that tick. An anomaly
  from the existing catalog may appear during a hold and clear when the
  train moves again.
- Staring during a hold is riskier: `StareIntervalScale` shortens the
  dwell needed to charge a stare while held (starting value: 2×).
- The hold itself is not an anomaly — it is a pressure moment. The player
  has to decide whether to look. The player cannot start or end a hold.

## 7. Announcements and countdown boards (borrowed from the video)

The video's game announces every stop with a Ding first and shows minutes
on hanging LED countdown boards ("1.0 Rose St 1min").

- The PA announces the next stop. Sometimes it announces the **wrong**
  stop, using another signed name and the same "The next stop is …" line.
  That tell is `wrong_announcement` in `AnomalySystem`. Flagging the
  announcement plate while the line is up counts as noticed. The scripted
  arrival lie at Metropolitan Av stays what it is. It is not this tell.
  A stop that does not exist is not used here. New station names are TBD.
- The countdown board shows the next stop and a minute count. It can show
  the **wrong minutes**. That tell is `wrong_countdown` in the same
  catalog. Flagging the board's plate while the wrong count is up counts
  as noticed. The server picks the stop and checks the flag.
- Announcements are prerecorded and slightly wrong on purpose. The
  conductor never answers questions. Keep the player alone with the PA.
- The Ding before each announcement stays. It is the sound the player
  learns to dread. The client sound bed plays a two-tone chime when
  `PaText` updates (built-in assets; not a full intercom voice).

## 8. Atmosphere tells (borrowed from the video)

Cheap, reusable tells that make a stop feel wrong without new models:

- **Flickering fluorescents** — one flickering strip or tube is an anomaly
  tell at a stop. The whole car does not flicker. A hold may blink one
  tube or dim the car slowly. That is not a whole-car flicker and not a
  new anomaly type. The car is brightest where it is safest.
- **Dim platform** — at a false stop, one platform is dimmer than the
  others. Noticing it is not an action; staring at it is.
- **Rats** — the video's game brags "this game has rats." A rat on the
  platform appears when an anomaly is active. It is a tell, not a threat.
- **Elevator as the only way down** — the video's game has elevators
  between station floors. Out of scope for this slice (no stepping off
  yet); keep it as a future hook for when stepping off is built.
- **Empty platforms** — long platforms, almost nobody on them. Keep them
  empty and darken them; do not fill them with chatty NPCs.

## 9. What happens at each band

| Band | Effect (starting values) |
|---|---|
| CALM | Nothing. Normal stops, normal announcements. |
| UNEASY | Passengers glance when you move. One fluorescent strip or tube flickers occasionally. The whole car does not flicker. |
| WATCHED | Heads turn toward you. Announcements glitch (a word repeats, a Ding comes twice). False-stop chance goes up. |
| HUNTED | The car dims slowly. That dim is not a flicker and not a blackout. The blackout risk rises (see §10). Parents' lines change — TBD which lines and how. |

This port: calm does nothing. Uneasy glances while you walk, and one tube blinks now and then. Watched turns heads toward you and repeats one word of the PA line that is already playing. There is no Ding in this slice, so the glitch is that repeated word, not a second chime. False stops are a fixed table, so the watched false-stop bonus is published and not rolled. Hunted dims the car slowly. Parent mask/chat lines shift by band. Flicker tick lengthens at watched/hunted.

## 10. The blackout (after Myrtle–Willoughby)

The blackout is already in the slice. Suspicion shapes it:

- **CALM / UNEASY at blackout:** the blackout is short, and the car
  comes back as it was.
- **WATCHED / HUNTED at blackout:** the blackout lasts longer. What
  happens in the dark is TBD — decide before building it. Do not invent a
  blackout event here.
- Suspicion does not reset at the blackout. It carries into Court Square.

(Flicker tick scales at watched/hunted; the exact “event in the dark” remains TBD.)

## 11. The ending (Court Square)

Final suspicion at arrival changes the ending:

- **CALM / UNEASY:** a clean arrival. TBD what "clean" shows.
- **WATCHED / HUNTED:** you are watched off the train. TBD what that
  shows.

Court Square uses `Endings.resolve` (peak, trials, tapes, exit, restraint,
interventions). Do not invent extra band-only endings from this draft.

## 12. Implementation notes (Roblox)

- **Server owns the meter.** Caught-staring, flag validation, dwell
  timing, and hold scheduling all run on the server. The client displays
  the meter, the dwell banner, the countdown board, and the stop result.
- **Tuning lives in one place.** Put the amounts, thresholds, decay, and
  hold frequency in `src/shared/Constants.luau`. Put on-screen copy in
  `src/shared/Lines.luau`. There is no `GameData.lua` in this port.
- **Whole-car light.** Only the existing flicker tick may flicker or black
  out the whole car (the lighting rule calls it the door tick: after
  Myrtle–Willoughby and at 21 St). The doors tick opens the doors early
  and does not touch the lights. One light strip or tube may flicker. The
  car may dim slowly. Do not add a whole-car flicker for holds, bands, or
  tells.
- **Psych Log.** Catalog anomalies marked seen / caught this ride appear
  on the Travel Report. Persistent Case Files stay in MetaStore.
- **Anomalies are server-picked.** The catalog is `AnomalySystem.types()`
  in `src/server/AnomalySystem.luau`: `poster_changed`, `extra`,
  `wrong_announcement`, `wrong_countdown`, plus expanded entries
  `lighttemp`, `sticker`, `nearword`, `mapstop`, `moved`, `empty`
  (`faceturn` / `momface` apply paths exist; stops unused this slice).
  There is no `GameData.Anomalies`. The server picks at most one per stop
  from the stop numbers in `src/shared/Constants.luau`. Other stops have
  none. Close-look props use `NEAR_X` (5 m). Catalog tells clear on
  arrival with the poster and PA/board plates. Web leftovers (`adswap`,
  `adcolor`, `stare`, `dadanswer`, forced parent/crit) stay out.
- **Existing anomaly stays.** `poster_changed` remains first in pick
  priority. New tells reuse free or false-approach stops so collisions
  stay rare.
- **No fail state in the slice.** Suspicion changes what the car does,
  not whether you can finish the ride. **Decided (PR13):** Rojo keeps
  **no hard fail at 100**. Intervention at 60+ cools the meter; endings
  that consume intervention count wait for PR14. The exporter's
  suspicion-100 ending remains out of this tree.

## 13. Build order (remaining)

1. ~~Dwell banner + early-departure penalty hook.~~ Done (banner on; penalty unused on purpose).
2. ~~Wrong-announcement and wrong-countdown tells.~~ Done.
3. ~~Held At Signal with one strip or tube flickering, or a slow dim.~~ Done.
4. ~~False-alarm penalty + per-stop results + HUD meter.~~ Done (meter + Score; Psych Log still TBD).
5. Band effects — glances / PA glitch / dim / parent lines / flicker scale are in.
6. Exact blackout “event in the dark” (§10) — only after playtest; do not invent.

## 14. Open questions (TBD — do not fill in)

- Exact blackout event at WATCHED / HUNTED.
- Exact Court Square ending variants per band.
- Whether the Early / Late timer should affect suspicion or stay a
  tension layer.
- Which parents' lines change at HUNTED, and how.
- Whether the full (non-Rojo) game gets a fail state at 100 remains TBD;
  Rojo's decision is no hard fail (see Port notes / §12).
