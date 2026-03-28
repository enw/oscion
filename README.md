# e10d

```
 ___ _  ___  ___ _
/ _ ( )/ _ \|   ( )
\___/_|\___/|_|_/_/
  analog synth
```

> a minimalist modular analog synthesizer for iPhone. built with AudioKit. no bloat.

---

## what it is

**e10d** is a signal chain in your pocket.

six knobs. four waveforms. sixteen steps. one output.

```
VCO ──▶ VCF ──▶ ENV ──▶ OUT ──▶ ◈
```

the whole synth fits on one screen. no tabs, no menus, no patch cables to drag around.
just sound.

---

## the signal chain

| module | params | what it does |
|--------|--------|--------------|
| `VCO`  | TUNE, waveform | voltage-controlled oscillator — the sound source |
| `VCF`  | CUT, RES | moog ladder filter — sculpt the tone |
| `ENV`  | ATK, REL | amplitude envelope — shape the dynamics |
| `OUT`  | VOL | master output fader |

**16-step sequencer** at the bottom. tap steps to toggle. dial in BPM and root note.
play fires the chain. stop freezes it.

---

## knobs

```
[ TUNE ]  [ CUT ]  [ RES ]  [ ATK ]  [ REL ]  [ VOL ]
```

that's it. six knobs. turn them.

- **TUNE** — semitone offset ±24st from root note
- **CUT** — filter cutoff 20hz → 20khz
- **RES** — resonance 0 → 0.99 (careful up here)
- **ATK** — envelope attack 0s → 4s
- **REL** — envelope release 0s → 4s
- **VOL** — master output 0 → 1

---

## waveforms

```
SINE   SAW   SQR   TRI
 ∿     /|    ⊓    /\
```

tap to switch. no crossfading. instant.

---

## sequencer

```
[■][ ][■][ ][■][ ][ ][■]
[ ][■][ ][■][ ][■][■][ ]

▶  NOTE C4  BPM 120
```

- 16 steps, 2 rows of 8
- tap a step to toggle it on/off
- the glowing amber block = current position
- NOTE sets root pitch for all steps
- BPM 20–250 via +/−

---

## stack

| layer | tech |
|-------|------|
| language | Swift 6 |
| UI | SwiftUI |
| audio | [AudioKit 5.6](https://audiokit.io) + SoundpipeAudioKit |
| filter | Moog Ladder (SoundpipeAudioKit) |
| envelope | AmplitudeEnvelope (SoundpipeAudioKit) |
| MIDI | CoreMIDI via AudioKit |
| platform | iOS 17+ |
| arch | MVVM + modular graph |

---

## build

requires Xcode 16+ and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/yourname/e10d-analog-synth
cd e10d-analog-synth
xcodegen generate
open e10dSynth.xcodeproj
```

select a simulator or device. hit run.

> packages resolve automatically on first build (~60s).

---

## midi

e10d listens on channel 1 by default. plug in a controller. play notes.
the VCO tracks pitch, ENV fires on note-on, releases on note-off.
MIDI clock sync: coming.

---

## architecture

```
SynthEngine (singleton)
├── VCOModule   → DynamicOscillator
├── VCFModule   → MoogLadder
├── ENVModule   → AmplitudeEnvelope
└── OUTModule   → Fader
        │
        ▼
    AudioEngine.output

SequencerViewModel
├── SequencerClock (Timer-based, drift-corrected)
└── Pattern [tracks[0..7]] → [Step x16]
        │  on tick →
        ▼
    SynthEngine.noteOn(note:velocity:)
```

modules are protocol-typed (`SynthModule`), own an AudioKit `Node`,
and can be connected arbitrarily via `ModularGraph`.
the default chain is hardwired at launch; patch changes trigger `rebuildAudioChain()`.

---

## license

MIT. do what you want. make noise.

---

```
e10d ● running
```
