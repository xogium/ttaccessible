//
//  MediaStreamingPlayerViewController.swift
//  ttaccessible
//

import AppKit

@MainActor
protocol MediaStreamingPlayerActions: AnyObject {
    func mediaStreamingPlayerDidTogglePlayPause()
    func mediaStreamingPlayerDidStop()
    func mediaStreamingPlayerDidSeek(toMSec offsetMSec: UInt32)
    func mediaStreamingPlayerDidChangeBroadcastGainPercent(_ percent: Int)
}

/// Compact embedded playback controls (no separate window).
final class MediaStreamingPlayerViewController: NSViewController {
    weak var actions: MediaStreamingPlayerActions?

    private let fileNameLabel = NSTextField(labelWithString: "")
    private let positionControl = MediaPlaybackPositionControl()
    private let playPauseButton = NSButton()
    private let stopButton = NSButton()
    private let broadcastGainSlider = AccessibleSlider()
    private let broadcastGainValueLabel = NSTextField(labelWithString: "")

    private var displayTimer: Timer?
    private var lastProgress = MediaStreamingProgress.inactive
    private var suppressGainAction = false

    override func loadView() {
        view = NSView()
        configureUI()
    }

    func update(with progress: MediaStreamingProgress) {
        lastProgress = progress
        view.isHidden = !progress.isActive

        if let fileName = progress.fileName {
            fileNameLabel.stringValue = L10n.format("mediaPlayer.fileName.format", fileName)
        } else {
            fileNameLabel.stringValue = L10n.text("mediaPlayer.fileName.empty")
        }

        playPauseButton.title = progress.isPaused
            ? L10n.text("mediaPlayer.play")
            : L10n.text("mediaPlayer.pause")
        playPauseButton.setAccessibilityLabel(playPauseButton.title)

        positionControl.isPlaybackActive = progress.isActive && !progress.isPaused

        if !positionControl.isAdjustingPosition {
            applyPositionControl(announceAccessibility: false)
        }

        suppressGainAction = true
        broadcastGainSlider.doubleValue = Double(progress.broadcastGainPercent)
        suppressGainAction = false
        broadcastGainValueLabel.stringValue = "\(progress.broadcastGainPercent)%"
        broadcastGainSlider.setAccessibilityValueDescription("\(progress.broadcastGainPercent)%")
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let noModifiers = modifiers.isDisjoint(with: [.command, .option, .control, .shift])

        switch event.keyCode {
        case 49 where noModifiers:
            actions?.mediaStreamingPlayerDidTogglePlayPause()
        case 53 where noModifiers:
            actions?.mediaStreamingPlayerDidStop()
        case 123 where noModifiers:
            seekDelta(seconds: -5)
        case 124 where noModifiers:
            seekDelta(seconds: +5)
        case 126 where noModifiers:
            adjustBroadcastGain(delta: +5)
        case 125 where noModifiers:
            adjustBroadcastGain(delta: -5)
        default:
            super.keyDown(with: event)
        }
    }

    private func seekDelta(seconds: Int) {
        guard lastProgress.isActive, lastProgress.durationMSec > 0 else { return }
        let currentMS = Int(currentEstimatedElapsedMSec())
        let durationMS = Int(lastProgress.durationMSec)
        let newMS = max(0, min(currentMS + seconds * 1000, durationMS - 1))
        actions?.mediaStreamingPlayerDidSeek(toMSec: UInt32(newMS))
        applyPositionControl(elapsedMSec: UInt32(newMS), announceAccessibility: true)
    }

    private func adjustBroadcastGain(delta: Int) {
        guard lastProgress.isActive else { return }
        let newValue = max(0, min(100, lastProgress.broadcastGainPercent + delta))
        actions?.mediaStreamingPlayerDidChangeBroadcastGainPercent(newValue)
    }

    @objc private func playPauseButtonClicked() {
        actions?.mediaStreamingPlayerDidTogglePlayPause()
    }

    @objc private func stopButtonClicked() {
        actions?.mediaStreamingPlayerDidStop()
    }

    @objc private func broadcastGainSliderAction(_ sender: NSSlider) {
        guard !suppressGainAction else { return }
        actions?.mediaStreamingPlayerDidChangeBroadcastGainPercent(Int(sender.doubleValue.rounded()))
    }

    private func startDisplayTimerIfNeeded() {
        guard displayTimer == nil else { return }
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshPositionControlIfNeeded()
            }
        }
    }

    private func refreshPositionControlIfNeeded() {
        guard lastProgress.isActive, lastProgress.durationMSec > 0, !positionControl.isAdjustingPosition else { return }
        applyPositionControl(announceAccessibility: false)
    }

    private func applyPositionControl(
        elapsedMSec: UInt32? = nil,
        announceAccessibility: Bool = false
    ) {
        let elapsed = elapsedMSec ?? currentEstimatedElapsedMSec()
        positionControl.apply(
            elapsedMSec: elapsed,
            durationMSec: lastProgress.durationMSec,
            enabled: lastProgress.durationMSec > 0,
            announceAccessibility: announceAccessibility
        )
    }

    private func currentEstimatedElapsedMSec() -> UInt32 {
        guard lastProgress.isActive else { return 0 }
        guard !lastProgress.isPaused, let sampledAt = lastProgress.elapsedSampleAt else {
            return lastProgress.elapsedMSec
        }
        let delta = Date().timeIntervalSince(sampledAt) * 1000
        let projected = Double(lastProgress.elapsedMSec) + max(0, delta)
        let capped = lastProgress.durationMSec > 0
            ? min(projected, Double(lastProgress.durationMSec))
            : projected
        return UInt32(capped)
    }

    private func configureUI() {
        view.isHidden = true

        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.maximumNumberOfLines = 1

        positionControl.onSeek = { [weak self] offsetMSec in
            self?.actions?.mediaStreamingPlayerDidSeek(toMSec: offsetMSec)
        }

        playPauseButton.bezelStyle = .rounded
        playPauseButton.target = self
        playPauseButton.action = #selector(playPauseButtonClicked)

        stopButton.bezelStyle = .rounded
        stopButton.title = L10n.text("mediaPlayer.stop")
        stopButton.target = self
        stopButton.action = #selector(stopButtonClicked)

        broadcastGainSlider.target = self
        broadcastGainSlider.action = #selector(broadcastGainSliderAction(_:))
        broadcastGainSlider.minValue = 0
        broadcastGainSlider.maxValue = 100
        broadcastGainSlider.isContinuous = true
        broadcastGainSlider.setAccessibilityLabel(L10n.text("mediaPlayer.broadcastGain.label"))

        broadcastGainValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)

        let controlsRow = NSStackView(views: [playPauseButton, stopButton])
        controlsRow.orientation = .horizontal
        controlsRow.spacing = 8

        let gainRow = NSStackView(views: [broadcastGainSlider, broadcastGainValueLabel])
        gainRow.orientation = .horizontal
        gainRow.spacing = 8
        broadcastGainSlider.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views: [fileNameLabel, positionControl, controlsRow, gainRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            positionControl.widthAnchor.constraint(equalTo: stack.widthAnchor),
            gainRow.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        startDisplayTimerIfNeeded()
    }
}
