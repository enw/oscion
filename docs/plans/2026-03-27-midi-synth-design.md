# e10d Analog Synth — Design Doc
_2026-03-27_

## Overview

Minimalist MIDI-enabled modular analog synth + step sequencer. iOS SwiftUI app. Targets live performance, music production, and exploration equally.

---

## Architecture

Three separated layers:

### Audio Engine
- `AVAudioEngine` with custom `AVAudioUnit` node subclasses
- Each module is an `AVAudioNode` — patching cables literally connects nodes in the engine graph
- Graph rebuilt on patch change, evaluated top-down

### MIDI Engine
- `CoreMIDI` — one virtual input port, one virtual output port
- Visible to GarageBand, AUM, DAWs on-device
- MIDI clock: 24 ppqn, sends/receives start/stop/continue
- MIDI Learn: long-press any knob → wiggle CC → mapped; persisted in `UserDefaults`

### Modular Graph
- Directed graph of `Module` nodes + `Patch` connections
- Serializable to JSON for preset save/load
- Signal types: Audio, CV, Gate

---

## Modules (MVP)

| Module | Params | Inputs | Outputs |
|--------|--------|--------|---------|
| VCO | waveform (sin/saw/sq/tri), tune, octave | CV pitch, CV FM, Gate | Audio |
| VCF | cutoff, resonance, type (LP/HP/BP) | Audio in, CV cutoff | Audio |
| VCA | gain | Audio in, CV gain | Audio |
| ENV | attack, decay, sustain, release | Gate | CV |
| LFO | rate, depth, waveform | — | CV |
| SEQ | (see sequencer section) | Clock in | Gate, CV pitch |
| MIDI IN | channel | — | Gate, CV pitch, CV vel |
| MIDI OUT | channel | Gate, CV pitch, CV vel | — |
| OUT | level | Audio L, Audio R | — |

---

## Patching UI (Rack View)

- Infinite scrollable/zoomable 2D canvas
- Dark background `#0a0a0a`, dot-grid `#1a2a1a` — CRT phosphor feel
- Modules: draggable cards ~180pt wide, monospace caps, amber/green on near-black
- Jacks: small circles, left = inputs, right = outputs, color-coded by signal type
- Patch cables: cubic bezier curves on `Canvas` overlay
  - Audio = `#00ff88`, CV = `#ffaa00`, Gate = `#ff4444`
- Patching gesture: long-press jack → drag → release on compatible jack
- Incompatible jacks highlight red; tap cable to delete
- Cable overlay redraws only on patch state change (not per-frame)

---

## Step Sequencer

- 8 tracks × 16 or 32 steps (toggle per-track)
- 16 patterns (A1–D4 naming)
- Pattern chain queue, loops

### Step cells
- Off (dark) / On (bright green) / Accent (amber)
- Long-press → popover: note, velocity (0–127), length (1/16–1 bar), probability (0–100%)

### Track header
- Name (editable), Mute/Solo
- MIDI channel (1–16) or Internal (routes to patched VCO)
- Color dot matching rack cable

### Transport bar
- BPM (tap-tempo or numeric)
- Swing (0–100%)
- Play / Stop / Record
- Pattern selector (4×4 grid)
- Clock source: Internal | MIDI In | Ableton Link

### Clock
- `SequencerClock` using `AVAudioTime` — sample-accurate, not `Timer`/`DispatchQueue`

---

## App Structure

### Tabs

| Tab | Icon | Content |
|-----|------|---------|
| Rack | `⬡` | Patch canvas |
| Seq | `▦` | Step sequencer |
| MIDI | `⇄` | Port routing, CC map, clock config |

### State

- `SynthEngine` — `@Observable` singleton, owns audio graph + MIDI client
- `RackViewModel` — module positions, patch connections
- `SequencerViewModel` — patterns, tracks, transport state
- No SwiftData/CoreData — JSON presets to `Documents/`

### Presets
- `.e10d` JSON bundle: full rack + sequencer state
- iCloud Drive via `UIDocumentPickerViewController`

---

## Visual Style

- Aesthetic: retro digital / CRT — green `#00ff88`, amber `#ffaa00`, near-black `#0a0a0a`
- Typography: monospace (SF Mono or custom bitmap-style font)
- Grid-heavy, utilitarian, no gradients or shadows
- Knobs: circular with tick marks, value shown in monospace below
