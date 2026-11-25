/**
 * Intelligible subway PA voice (ported from Astra's source–filter renderer).
 *
 * The glottal pulse and turbulent consonants pass through three moving formants,
 * then through a band-limited PA speaker chain (highpass → lowpass → soft-clip
 * overdrive → short station echo) routed into the game audio bus.
 *
 * Synthesized live from text with zero external audio files or speechSynthesis.
 */

export const PA_LEVEL = 0.22;

const pronunciations: Record<string, string> = {
  // Astra base vocabulary & G line
  this: 'dh i s',
  is: 'i z',
  court: 'k or t',
  square: 's k w e r',
  sq: 's k w e r',
  last: 'l ae s t',
  stop: 's t o p',
  everybody: 'e v r ee b o d ee',
  off: 'o f',
  the: 'dh uh',
  train: 't r ey n',
  next: 'n e k s t',
  station: 's t ey sh uh n',
  at: 'ae t',
  hoyt: 'h oy t',
  schermerhorn: 'sh er m er h or n',
  fulton: 'f uh l t uh n',
  st: 's t r ee t',
  street: 's t r ee t',
  clinton: 'k l i n t uh n',
  washington: 'w o sh i ng t uh n',
  avs: 'ae v uh n oo z',
  avenues: 'ae v uh n oo z',
  classon: 'k l ae s uh n',
  class: 'k l ae s',
  on: 'o n',
  av: 'ae v uh n oo',
  ave: 'ae v uh n oo',
  avenue: 'ae v uh n oo',
  bedford: 'b e d f er d',
  nostrand: 'n o s t r ae n d',
  myrtle: 'm er t l',
  willoughby: 'w i l uh b ee',
  flushing: 'f l uh sh i ng',
  broadway: 'b r aw d w ey',
  metropolitan: 'm e t r uh p o l i t uh n',
  nassau: 'n ae s aw',
  greenpoint: 'g r ee n p oy n t',
  '21': 't w e n t ee f er s t',
  g: 'jh ee',
  l: 'e l',
  a: 'uh',
  new: 'n oo',
  york: 'y or k',
  city: 's i t ee',
  transit: 't r ae n z i t',
  please: 'p l ee z',
  stand: 's t ae n d',
  clear: 'k l ee r',
  of: 'uh v',
  closing: 'k l oh z i ng',
  doors: 'd or z',
  open: 'oh p uh n',
  to: 't oo',
  let: 'l e t',
  passengers: 'p ae s uh n jh er z',
  exit: 'e g z i t',
  before: 'b i f or',
  boarding: 'b or d i ng',
  keep: 'k ee p',
  your: 'y or',
  belongings: 'b i l aw ng i ng z',
  with: 'w i th',
  you: 'y oo',
  all: 'aw l',
  times: 't ai m z',
  watch: 'w o ch',
  step: 's t e p',
  gap: 'g ae p',
  between: 'b i t w ee n',
  and: 'ae n d',
  platform: 'p l ae t f or m',
  mind: 'm ai n d',
  do: 'd oo',
  not: 'n o t',
  hold: 'h oh l d',
  for: 'f or',
  an: 'ae n',
  we: 'w ee',
  are: 'ar',
  now: 'n ow',
  approaching: 'uh p r oh ch i ng',
  if: 'i f',
  see: 's ee',
  something: 's uh m th i ng',
  say: 's ey',
  conductor: 'k uh n d uh k t er',
  remain: 'r i m ey n',
  seated: 's ee t i d',
  thank: 'th ae ng k',
  riding: 'r ai d i ng',
  local: 'l oh k uh l',
  bound: 'b ow n d',
  attention: 'uh t e n sh uh n',
  away: 'uh w ey',
  from: 'f r uh m',
  edge: 'e jh',
  back: 'b ae k',
  service: 's er v i s',
  line: 'l ai n',
  while: 'w ai l',
  moving: 'm oo v i ng',
  accessible: 'ae k s e s uh b l',
  transfer: 't r ae n s f er',
  available: 'uh v ey l uh b l',
  us: 'uh s',

  // L line additions
  '1st': 'f er s t',
  '3rd': 'th er d',
  '5th': 'f i f th',
  '6th': 's i k s th',
  '8th': 'ey t th',
  '14th': 'f or t ee n th',
  '42nd': 'f or t ee s e k uh n d',
  union: 'y oo n y uh n',
  lorimer: 'l or i m er',
  graham: 'g r ae m',
  grand: 'g r ae n d',
  montrose: 'm o n t r oh z',
  morgan: 'm or g uh n',
  jefferson: 'jh e f er s uh n',
  wyckoff: 'w ai k o f',

  // 7 Ghost Line additions
  bryant: 'b r ai uh n t',
  pk: 'p ar k',
  park: 'p ar k',
  central: 's e n t r uh l',
  sub: 's uh b',
  river: 'r i v er',
  tube: 't oo b',
  level: 'l e v uh l',
  abandoned: 'uh b ae n d uh n d',
  steinway: 's t ai n w ey',
  hunters: 'h uh n t er z',
  point: 'p oy n t',
  depths: 'd e p th s',
  vernon: 'v er n uh n',
  jackson: 'jh ae k s uh n',
  void: 'v oy d',
  sunken: 's uh ng k uh n',
  yard: 'y ar d',
  switch: 's w i ch',
  dead: 'd e d',
  track: 't r ae k',
  gantry: 'g ae n t r ee',
  queensboro: 'k w ee n z b er oh',
  cavern: 'k ae v er n',
  rawlings: 'r aw l i ng z',
  tower: 't ow er',
  vault: 'v aw l t',
  terminal: 't er m i n uh l',
  echo: 'e k oh',
  marker: 'm ar k er',

  // Digits used in stop names / route labels
  '0': 'z ee r oh',
  '1': 'w uh n',
  '2': 't oo',
  '3': 'th r ee',
  '4': 'f or',
  '5': 'f ai v',
  '6': 's i k s',
  '7': 's e v uh n',
  '8': 'ey t',
  '9': 'n ai n',
};

const vowels: Record<string, number[]> = {
  i: [400, 1900, 2540],
  ee: [290, 2220, 3000],
  e: [535, 1800, 2510],
  ae: [690, 1700, 2450],
  uh: [570, 1260, 2450],
  er: [470, 1250, 1610],
  ar: [720, 1160, 1710],
  o: [650, 1010, 2360],
  aw: [560, 860, 2460],
  or: [490, 880, 1650],
  oo: [320, 840, 2140],
  oh: [460, 900, 2300],
  ey: [470, 1930, 2670],
  ai: [720, 1520, 2500],
  ow: [630, 1170, 2390],
  oy: [530, 1100, 2440],
};

const resonants: Record<string, number[]> = {
  r: [350, 1210, 1560],
  l: [390, 1240, 2610],
  n: [255, 1570, 2520],
  m: [240, 1050, 2250],
  ng: [270, 1700, 2450],
  w: [325, 850, 2190],
  y: [310, 2090, 2810],
};

const hiss: Record<string, number> = {
  s: 3700,
  z: 3400,
  sh: 2400,
  ch: 2540,
  jh: 2300,
  th: 3180,
  dh: 2500,
  h: 1420,
  f: 2900,
  v: 2380,
};

const fallback: Record<string, string> = {
  a: 'ae',
  e: 'e',
  i: 'i',
  o: 'oh',
  u: 'uh',
  c: 'k',
  q: 'k',
  x: 's',
  j: 'jh',
};

const RATE = 16000;
const CHIME_LEAD_S = 0.43;

export function announcementPhonemes(line: string): string[] {
  return (line.toLowerCase().match(/[a-z0-9]+|[,.;:!?]/g) ?? []).flatMap((word) => {
    if (/^[,.;:!?]$/.test(word)) return ['|'];
    const sounds = pronunciations[word]?.split(' ') ?? [...word].map((c) => fallback[c] ?? c);
    return [...sounds, '_'];
  });
}

function symbolLength(symbol: string): number {
  if (symbol === '|') return 0.19;
  if (symbol === '_') return 0.028;
  if (vowels[symbol]) return 0.115;
  if (resonants[symbol]) return 0.066;
  return 0.077;
}

export function announcementDurationSeconds(line: string): number {
  const sounds = announcementPhonemes(line);
  return sounds.reduce((sum, s) => sum + symbolLength(s), 0);
}

export function unpronouncedWords(line: string): string[] {
  const tokens = line.toLowerCase().match(/[a-z0-9]+/g) ?? [];
  const missing: string[] = [];
  for (const token of tokens) {
    if (!(token in pronunciations) && !missing.includes(token)) {
      missing.push(token);
    }
  }
  return missing;
}

/** Astra's source–filter voice renderer verbatim. */
export function makeAnnouncement(context: BaseAudioContext, line: string): AudioBuffer {
  const sounds = announcementPhonemes(line);
  const lengths = sounds.map((s) => Math.round(symbolLength(s) * RATE));
  const count = Math.max(1, lengths.reduce((sum, n) => sum + n, 0));
  const buffer = context.createBuffer(1, count, RATE);
  const data = buffer.getChannelData(0);
  let index = 0;
  let seed = 90172;
  let phase = 0;
  let dc = 0;
  const previous = [0, 0, 0];
  const previous2 = [0, 0, 0];
  const freqs = [480, 1260, 2450];

  for (let p = 0; p < sounds.length; p++) {
    const symbol = sounds[p];
    const silent = symbol === '_' || symbol === '|';
    const vowel = vowels[symbol];
    const resonant = resonants[symbol];
    const fricative = hiss[symbol];
    const stop = !vowel && !resonant && !silent && !fricative;
    const voiced = !!(vowel || resonant || ['b', 'd', 'g', 'dh', 'v', 'z', 'jh'].includes(symbol));
    const target = vowel || resonant || (fricative ? [950, fricative, fricative + 800] : [450, 1600, 2900]);
    const gains = resonant ? [0.57, 0.28, 0.1] : fricative ? [0.06, 0.52, 0.45] : [0.78, 0.44, 0.24];
    const radii = vowel || resonant ? [0.983, 0.977, 0.966] : [0.87, 0.89, 0.86];
    let coefficients = [0, 0, 0];

    for (let j = 0; j < lengths[p]; j++, index++) {
      const portion = j / lengths[p];
      // Smooth articulation as the mouth moves from the previous sound.
      if (j % 32 === 0) {
        coefficients = freqs.map((f, k) => {
          let end = target[k];
          if (k === 1 && symbol === 'ai') end += 650 * portion;
          if (k === 1 && symbol === 'oy') end += 1000 * portion;
          if (k === 0 && symbol === 'ow') end -= 210 * portion;
          freqs[k] = f + (end - f) * 0.2;
          return 2 * radii[k] * Math.cos((2 * Math.PI * freqs[k]) / RATE);
        });
      }
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      const noise = seed / 2147483648 - 1;
      const f0 = 114 - (8 * index) / count + 4 * Math.sin((index / RATE) * 4.1);
      phase = (phase + f0 / RATE) % 1;
      const glottis = phase < 0.46 ? Math.sin((Math.PI * phase) / 0.46) ** 2 : 0;
      let source = voiced ? glottis - 0.23 : 0;
      if (fricative) source = (voiced ? 0.36 * source : 0) + noise * 0.62;
      if (stop) source = (voiced ? 0.16 * source : 0) + (portion > 0.55 ? noise * Math.exp(-12 * (portion - 0.55)) : 0);
      if (silent) source = 0;
      let sample = 0;
      for (let k = 0; k < 3; k++) {
        const y = (1 - radii[k]) * source + coefficients[k] * previous[k] - radii[k] ** 2 * previous2[k];
        previous2[k] = previous[k];
        previous[k] = y;
        sample += y * gains[k];
      }
      dc += 0.055 * (sample - dc);
      data[index] = Math.tanh((sample - dc) * 4.8) * 0.8;
    }
  }
  return buffer;
}

export interface PaVoicePlayback {
  text: string;
  start: number;
  duration: number;
  chime: boolean;
}

interface ActiveLine {
  src: AudioBufferSourceNode;
  chimeOscs: OscillatorNode[];
  out: GainNode;
  echoFb: GainNode;
  cleanupTimer: ReturnType<typeof setTimeout> | null;
}

export class PaVoice {
  private ac: BaseAudioContext;
  private dest: AudioNode;
  private shaperCurve: Float32Array<ArrayBuffer>;
  private current: ActiveLine | null = null;
  /** Last spoken announcement, for tests and debugging. */
  public last: PaVoicePlayback | null = null;

  constructor(ac: BaseAudioContext, destination: AudioNode) {
    this.ac = ac;
    this.dest = destination;
    const n = 1024;
    this.shaperCurve = new Float32Array(new ArrayBuffer(n * 4));
    for (let i = 0; i < n; i++) {
      const x = (i / (n - 1)) * 2 - 1;
      this.shaperCurve[i] = Math.tanh(3 * x) / Math.tanh(3);
    }
  }

  public get speaking(): boolean {
    return this.current !== null;
  }

  public speak(text: string, opts: { chime?: boolean } = {}): number {
    const clean = text.trim();
    if (!clean) return 0;

    this.stop();

    const ac = this.ac;
    const chime = opts.chime !== false;
    const t0 = ac.currentTime + 0.02;
    const voiceStart = chime ? t0 + CHIME_LEAD_S : t0;

    // Speaker chain mirroring intercom.ts: band-limited PA speaker → overdrive → out (+ station echo)
    const hp = ac.createBiquadFilter();
    hp.type = 'highpass';
    hp.frequency.value = 380;

    const lp = ac.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = 3000;

    const drive = ac.createGain();
    drive.gain.value = 1.8;

    const shaper = ac.createWaveShaper();
    shaper.curve = this.shaperCurve;

    const out = ac.createGain();
    out.gain.setValueAtTime(PA_LEVEL, t0);

    hp.connect(lp).connect(drive).connect(shaper).connect(out).connect(this.dest);

    // Short darkened station echo
    const echo = ac.createDelay(1);
    echo.delayTime.value = 0.13;
    const echoLp = ac.createBiquadFilter();
    echoLp.type = 'lowpass';
    echoLp.frequency.value = 2200;
    const echoFb = ac.createGain();
    echoFb.gain.value = 0.28;

    out.connect(echo).connect(echoLp).connect(echoFb);
    echoFb.connect(echo);
    echoFb.connect(this.dest);

    // Optional Astra attention chime (1030 Hz → 820 Hz)
    const chimeOscs: OscillatorNode[] = [];
    if (chime) {
      chimeOscs.push(this.chimeTone(out, 1030, t0, 0.22, 0.3));
      chimeOscs.push(this.chimeTone(out, 820, t0 + 0.16, 0.29, 0.24));
    }

    const buffer = makeAnnouncement(ac, clean);
    const src = ac.createBufferSource();
    src.buffer = buffer;
    src.connect(hp);

    const active: ActiveLine = { src, chimeOscs, out, echoFb, cleanupTimer: null };
    this.current = active;

    src.onended = () => {
      if (this.current === active) {
        this.current = null;
      }
      if (typeof OfflineAudioContext === 'undefined' || !(ac instanceof OfflineAudioContext)) {
        active.cleanupTimer = setTimeout(() => {
          try {
            out.disconnect();
            echoFb.disconnect();
          } catch {
            /* already disconnected */
          }
        }, 1200);
      }
    };

    src.start(voiceStart);

    const duration = (chime ? CHIME_LEAD_S : 0) + buffer.duration;
    this.last = { text: clean, start: t0, duration, chime };
    return duration;
  }

  public stop(): void {
    const active = this.current;
    if (!active) return;
    this.current = null;

    if (active.cleanupTimer) {
      clearTimeout(active.cleanupTimer);
      active.cleanupTimer = null;
    }

    const now = this.ac.currentTime;
    try {
      active.out.gain.cancelScheduledValues(now);
      active.out.gain.setValueAtTime(active.out.gain.value, now);
      active.out.gain.linearRampToValueAtTime(0, now + 0.015);
    } catch {
      /* ignore */
    }
    try {
      active.src.onended = null;
      active.src.stop(now + 0.02);
    } catch {
      /* already stopped */
    }
    for (const osc of active.chimeOscs) {
      try {
        osc.stop(now + 0.02);
      } catch {
        /* already stopped */
      }
    }
    try {
      active.echoFb.disconnect();
      active.out.disconnect();
    } catch {
      /* already disconnected */
    }
  }

  private chimeTone(dest: AudioNode, freq: number, at: number, tail: number, volume: number): OscillatorNode {
    const osc = this.ac.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, at);

    const amp = this.ac.createGain();
    amp.gain.setValueAtTime(0.0001, at);
    amp.gain.exponentialRampToValueAtTime(Math.max(0.0002, volume), at + Math.min(0.008, tail / 4));
    amp.gain.exponentialRampToValueAtTime(0.0001, at + tail);

    osc.connect(amp).connect(dest);
    osc.start(at);
    osc.stop(at + tail + 0.02);
    return osc;
  }
}
