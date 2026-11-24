import { test } from 'bun:test';
import assert from 'node:assert/strict';
import { buildCutscene, CutscenePlayer, type CutsceneId } from '../../src/game/cutscenes';

test('all four scene definitions build with sane beats and shots', () => {
  const ids: CutsceneId[] = ['intro', 'haven', 'trial', 'arrival'];
  for (const id of ids) {
    const def = buildCutscene(id);
    assert.equal(def.id, id);
    assert.ok(def.title.length > 0);
    assert.ok(def.beats.length >= 3);
    for (const beat of def.beats) {
      assert.ok(beat.dur > 0 && Number.isFinite(beat.dur));
      assert.ok(Number.isFinite(beat.shot.yaw) && Number.isFinite(beat.shot.pitch));
      if (beat.shot.eye) {
        assert.equal(beat.shot.eye.length, 3);
        assert.ok(beat.shot.eye.every(Number.isFinite));
      }
    }
  }
});

test('intro keeps Dad line full on a fresh ride and shortens it on a chapter start', () => {
  const fresh = buildCutscene('intro', { chapterStart: false, looped: false });
  const chapter = buildCutscene('intro', { chapterStart: true, looped: false });

  const freshDad = fresh.beats.find((b) => b.sub?.includes('Dad:'))!;
  const chapterDad = chapter.beats.find((b) => b.sub?.includes('Dad:'))!;

  assert.ok(freshDad.sub!.includes('Thirteen stops to Court Square.'));
  assert.ok(!chapterDad.sub!.includes('Thirteen stops'));
  assert.ok(chapterDad.sub!.includes('Grab a seat right here.'));
});

test('intro looped adds the repeat beat after Mom and omits the look-around hint', () => {
  const looped = buildCutscene('intro', { looped: true });
  const momIdx = looped.beats.findIndex((b) => b.sub?.includes('Stay where we can see you'));
  const repeatIdx = looped.beats.findIndex((b) => b.sub?.includes('He said that last time, too.'));

  assert.ok(momIdx >= 0);
  assert.equal(repeatIdx, momIdx + 1);
  assert.ok(looped.beats.every((b) => !b.hint));
});

test('haven replays the existing lines and hands over the recorder', () => {
  const haven = buildCutscene('haven');
  assert.ok(haven.beats.some((b) => b.sub?.includes('Feels good to stand up, right?')));
  assert.ok(haven.beats.some((b) => b.sub?.includes('Couple more stops after this.')));
  assert.ok(haven.beats.some((b) => b.action?.type === 'giveRecorder' && b.action.where === 'haven'));
});

test('CutscenePlayer throws on an empty definition or non-positive beat duration', () => {
  assert.throws(() => new CutscenePlayer({ id: 'intro', title: 'Empty', beats: [] }));
  assert.throws(() =>
    new CutscenePlayer({
      id: 'intro',
      title: 'Zero',
      beats: [{ dur: 0, shot: { yaw: 0, pitch: 0 } }],
    })
  );
  assert.throws(() =>
    new CutscenePlayer({
      id: 'intro',
      title: 'Negative',
      beats: [{ dur: -1, shot: { yaw: 0, pitch: 0 } }],
    })
  );
});

test('CutscenePlayer advances beats in order and finishes at the total duration', () => {
  const player = new CutscenePlayer({
    id: 'trial',
    title: 'Test',
    beats: [
      { dur: 1.0, shot: { yaw: 0, pitch: 0 } },
      { dur: 1.5, shot: { yaw: 0.2, pitch: 0 } },
      { dur: 0.5, shot: { yaw: 0, pitch: 0 } },
    ],
  });
  assert.equal(player.totalDuration, 3.0);
  assert.equal(player.index, 0);

  let beatsSeen = 0;
  let finished = false;
  for (let i = 0; i < 60 && !finished; i++) {
    const ev = player.update(0.05);
    if (ev === 'beat') beatsSeen += 1;
    if (ev === 'finished') finished = true;
  }

  assert.equal(beatsSeen, 2);
  assert.equal(finished, true);
  assert.equal(player.finished, true);
  assert.ok(Math.abs(player.elapsed - 3.0) < 1e-9);
});

test('CutscenePlayer never jumps a beat on a huge dt step', () => {
  const player = new CutscenePlayer({
    id: 'arrival',
    title: 'Huge DT',
    beats: [
      { dur: 1.0, shot: { yaw: 0, pitch: 0 } },
      { dur: 1.0, shot: { yaw: 0.3, pitch: 0 }, action: { type: 'openDoors' } },
      { dur: 1.0, shot: { yaw: 0, pitch: 0 } },
    ],
  });

  assert.equal(player.update(999), 'beat');
  assert.equal(player.index, 1);
  assert.equal(player.finished, false);
  assert.equal(player.currentBeat.action?.type, 'openDoors');

  assert.equal(player.update(999), 'beat');
  assert.equal(player.index, 2);
  assert.equal(player.finished, false);

  assert.equal(player.update(999), 'finished');
  assert.equal(player.finished, true);
});

test('skip() returns every remaining action in order and skipping twice is a no-op', () => {
  const player = new CutscenePlayer(buildCutscene('intro'));
  // Beat 0 has started; remaining actions include chime and closeDoors in order.
  const first = player.skip();
  assert.deepEqual(
    first.map((a) => a.type),
    ['chime', 'closeDoors']
  );
  assert.equal(player.finished, true);

  const second = player.skip();
  assert.deepEqual(second, []);
});
