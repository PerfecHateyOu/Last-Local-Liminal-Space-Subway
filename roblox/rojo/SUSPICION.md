# Last Local (Roblox) — Suspicion System Design

A design draft for the suspicion system in the Roblox slice. Builds on the
flag mechanic already in the slice (see `README.md`, `src/client/Flag.luau`,
and `src/server/Ride.luau`); it does not replace it. There is no
`last-local-roblox-guide.md` in this port. Tuning numbers are starting
values to playtest, not verified results. Anything marked TBD is undecided
— do not fill it in from a guess.

## Port notes

The Rojo port has no suspicion meter yet. It only has the flag, caught,
false-flag, and an end-of-ride result (missed and false flags). It does
not show a 0–100 meter, and it does not report a per-stop result.

The player is a passenger: the kid riding with Mom and Dad, the same as
the web game. Decided. They are not a conductor. See §5.

`roblox/exporter/` is a different track. Its `addSuspicion` ends the ride
when suspicion reaches 100 (phase `end`, ending EXPOSED: the parents pull
you off at the next platform). That conflicts with §12, "No fail state in
the slice." This is an open question. It is not resolved. This Rojo port
does not copy that ending.

## The slice this is for

One G-train car, Hoyt–Schermerhorn → Court Square (13 stops). Already in
the slice: the flag mechanic, false stops at Classon Av and Metropolitan Av,
the blackout after Myrtle–Willoughby, and the Court Square ending. Not in
the slice (out of scope here): sound, cars A and C, stepping off, the Safe
Haven, the trial, the camera, the tape recorder.

The video that fed this draft: *ROBLOX: Conducting an R62A 1 Train in NYC
Subway: Automated* (Tako Elevators) and the game it shows, *NYC Subway:
Automated* by Automated Transit Studio
(https://www.roblox.com/games/13804003310/NYC-Subway-Automated). The ideas
taken from it are listed under "Borrowed from the video" in each section.

## 1. What suspicion is

Suspicion is the car's attention on you: how much the passengers, the
conductor, and the train itself have noticed you noticing things. It is a
0–100 meter, shown on screen (display-only, like the web game's HUD — the
web HUD reads "25 UNEASY" at 25, so the bands below keep that threshold).

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
| Caught staring at an active anomaly | +15 | Not in this port (TBD). The slice can flag a passenger. It does not score a stare. |
| False alarm — flagging when no anomaly is active | +10 | Applied when a flag lands while no tell is up and the poster has not changed. Flagging the wrong person while a tell or the poster is up does not add this. |
| Reacting at a false stop | +10 | The amount is in Constants. This port cannot see standing, moving to the doors, or staring, so the hook stays off. |
| Leaving before the dwell ends | +10 | Stays off. The player is a passenger and cannot depart. The amount stays in Constants for the unused hook. See §5. |
| Staring at the conductor or a parent for too long | +5 | New. The people in the car notice being watched, anomaly or not. |

## 3. What lowers suspicion

| Cause | Amount (starting value) | Notes |
|---|---|---|
| Decay over time | −2 per stop with no incident | Applied on a miss and on a clean stop. A miss does not also raise suspicion. |
| Correct flag — flagging while an anomaly is active | −5 | Applied when the flag is noticed. The screen still says Caught. |
| Completing a stop cleanly | −5 | Applied with the decay, so a clean stop is −7. Arrive, dwell, depart, nothing flagged, no anomaly on that stop. |
| Sitting still and looking away | −2 per stop | New. Acting normal is the safest play. |

## 4. Per-stop result

At the end of each stop the server reports one result. The screen shows it
briefly, using the existing words where they exist. There is no suspicion
meter. The Psych Log is still not in this port (TBD):

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
- Reacting at a false stop is still +10 in §2. This port cannot see that
  reaction, so the hook stays off.
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
- Staring during a hold is riskier: the caught-staring check runs more
  often while held (starting value: twice as often). This port has no
  caught-staring check. The hold publishes that multiplier for when the
  check exists. It does not watch the player.
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
  learns to dread.

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

This port: calm does nothing. Uneasy glances while you walk, and one tube blinks now and then. Watched turns heads toward you and repeats one word of the PA line that is already playing. There is no Ding in this slice, so the glitch is that repeated word, not a second chime. False stops are a fixed table, so the watched false-stop bonus is published and not rolled. Hunted dims the car slowly. Parent lines and a longer blackout stay TBD.

## 10. The blackout (after Myrtle–Willoughby)

The blackout is already in the slice. Suspicion shapes it:

- **CALM / UNEASY at blackout:** the blackout is short, and the car
  comes back as it was.
- **WATCHED / HUNTED at blackout:** the blackout lasts longer. What
  happens in the dark is TBD — decide before building it. Do not invent a
  blackout event here.
- Suspicion does not reset at the blackout. It carries into Court Square.

## 11. The ending (Court Square)

Final suspicion at arrival changes the ending:

- **CALM / UNEASY:** a clean arrival. TBD what "clean" shows.
- **WATCHED / HUNTED:** you are watched off the train. TBD what that
  shows.

Exact ending variants are TBD. Do not build them from this draft alone.

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
- **Psych Log.** Every anomaly, flag, stop result, and band change writes
  an entry. The log is not in this port (TBD). There is no guide next-step
  list. The log is the record the player re-reads — and the record a
  playtester uses to tune.
- **Anomalies are server-picked.** The catalog is `AnomalySystem.types()`
  in `src/server/AnomalySystem.luau`: `poster_changed`,
  `wrong_announcement`, and `wrong_countdown`. There is no
  `GameData.Anomalies`. The server picks at most one per stop from the
  stop numbers in `src/shared/Constants.luau`. Other stops have none.
  `poster_changed` is still scheduled from `src/server/Ride.luau` and that
  poster still clears on arrival. The two tells clear on arrival too.
  Picking one anomaly for every stop from a larger table is not built
  (TBD). One strip or tube flickering, a dim platform, and a rat would be
  further entries in that catalog, not separate systems.
- **Existing anomaly stays.** `poster_changed` is still the first anomaly.
  Add the new tells one at a time and playtest each before adding the
  next.
- **No fail state in the slice.** Suspicion changes what the car does,
  not whether you can finish the ride. Whether the full game gets a fail
  state is TBD. The exporter's suspicion-100 ending conflicts with this
  and is not resolved (see Port notes and §14).

## 13. Build order

1. Dwell banner + early-departure penalty (§5).
2. Wrong-announcement and wrong-countdown tells (§7).
3. Held At Signal with one strip or tube flickering, or a slow dim (§6, §8). Not a whole-car flicker.
4. False-alarm penalty + per-stop results (§2–§4).
5. Band effects (§9) — glances first, then announcement glitches.
6. Blackout shaping (§10) and ending variants (§11) — only after 1–5
   playtest clean.

## 14. Open questions (TBD — do not fill in)

- Exact blackout event at WATCHED / HUNTED.
- Exact Court Square ending variants per band.
- Whether the Early / Late timer should affect suspicion or stay a
  tension layer.
- Which parents' lines change at HUNTED, and how.
- Whether the full game gets a fail state.
- `roblox/exporter/` ends the ride at suspicion 100. §12 says the slice
  has no fail state. That conflict is not resolved.
