import Foundation

final class SequencerClock {

    var bpm: Double = 120 {
        didSet { bpm = min(250, max(20, bpm)) }
    }
    var swing: Double = 0 {
        didSet { swing = min(100, max(0, swing)) }
    }

    var onTick: ((Int) -> Void)?
    var onBar: (() -> Void)?

    private var timer: Timer?
    private(set) var currentStep: Int = 0
    private(set) var isRunning: Bool = false

    /// Duration of one 16th-note step in seconds
    var stepInterval: TimeInterval { 60.0 / bpm / 4.0 }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentStep = 0
        scheduleTick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        currentStep = 0
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func scheduleTick() {
        let interval = swungInterval(for: currentStep)
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self, self.isRunning else { return }
            self.onTick?(self.currentStep)
            if self.currentStep % 16 == 0 { self.onBar?() }
            self.currentStep += 1
            self.scheduleTick()
        }
        t.tolerance = interval * 0.1  // improve battery usage
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func swungInterval(for step: Int) -> TimeInterval {
        let base = stepInterval
        guard swing > 0 else { return base }
        let factor = (swing / 100.0) * 0.2
        return step % 2 == 0 ? base * (1 + factor) : base * (1 - factor)
    }
}
