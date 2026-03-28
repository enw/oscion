# Multi-Track Design

## Goal

Multiple simultaneous tracks, each with independent synth settings (internal voice) or MIDI out routing.

## Constraints

- Max 4 internal voices (full VCO+VCF+ENV chains)
- Up to 8 tracks per pattern (existing limit)
- Tracks 5-8 must use MIDI out if all 4 internal slots are taken

---

## Data Model (`SequencerModels.swift`)

```swift
enum TrackVoiceType: Codable {
    case internalVoice
    case midiOut(channel: Int)  // 1-16
}

struct TrackVoiceSettings: Codable {
    var waveform: Waveform = .sawtooth
    var octave: Int = 0           // -2 to +2
    var detune: Float = 0         // cents, -50 to +50
    var cutoff: Float = 1000      // Hz
    var resonance: Float = 0.1
    var attack: Float = 0.01
    var decay: Float = 0.1
    var sustain: Float = 0.8
    var release: Float = 0.3
    var volume: Float = 0.8
}

// Added to Track:
var voiceType: TrackVoiceType = .internalVoice
var voiceSettings: TrackVoiceSettings = TrackVoiceSettings()
```

---

## Audio Engine (`SynthEngine.swift`)

Replace single VCO/VCF/ENV with 4 `SynthVoice` instances summed via `Mixer → OUT`.

```swift
struct SynthVoice {
    var vco: VCOModule
    var vcf: VCFModule
    var env: ENVModule
}

var voices: [SynthVoice]   // 4 entries
var mixer: Mixer           // voices[0..3] → mixer → out
```

**Track-to-voice mapping**: the Nth internal track in pattern order owns `voices[N]`. 1:1, static, no allocation.

`applySettings(_ settings: TrackVoiceSettings, to voiceIndex: Int)` updates VCO/VCF/ENV params on the target voice before each note trigger.

---

## Sequencer (`SequencerViewModel.swift`)

`tick()` routes per track:

```swift
switch track.voiceType {
case .internalVoice:
    let i = internalVoiceIndex(for: track)
    engine.applySettings(track.voiceSettings, to: i)
    engine.noteOn(note: step.note, velocity: vel, voice: i)
case .midiOut(let channel):
    midi.send(noteOn: step.note, velocity: vel, channel: channel)
}
// noteOff scheduled after step.length in both cases
```

`internalVoiceIndex(for:)` counts preceding internal tracks in the array.

---

## UI

### Track row header (right side)
- Internal track: green badge `INT 1`–`INT 4`
- MIDI track: blue badge `CH 1`–`CH 16`
- Tap badge → opens voice editor sheet

### Voice editor sheet (bottom sheet)
- Segmented control: `Internal | MIDI`
  - Switching to Internal when all 4 slots taken → alert
- **Internal mode**: waveform picker, octave stepper, detune knob, cutoff knob, resonance knob, A/D/S/R knobs, volume knob
- **MIDI mode**: channel picker (1–16)
