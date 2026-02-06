//
//  AudioAnalyzer.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

class AudioAnalyzer: ObservableObject {
    @Published var currentPace: Double = 0.0 // words per minute
    @Published var crutchWordCount: Int = 0
    @Published var pauseCount: Int = 0
    @Published var pauseAverageDuration: TimeInterval = 0
    @Published var inputLevel: Double = 0.0
    @Published var silenceWarning: Bool = false
    @Published var processingLatencyStatus: ProcessingLatencyStatus = .ok
    @Published var processingLatencyAverage: TimeInterval = 0
    @Published var processingUtilizationStatus: ProcessingUtilizationStatus = .ok
    @Published var processingUtilizationAverage: Double = 0

    var feedbackPublisher: AnyPublisher<FeedbackState, Never> {
        let metricsPublisher = Publishers.CombineLatest4(
            $currentPace,
            $crutchWordCount,
            $pauseCount,
            $pauseAverageDuration
        )

        let latencyPublisher = Publishers.CombineLatest($processingLatencyStatus, $processingLatencyAverage)
        let utilizationPublisher = Publishers.CombineLatest($processingUtilizationStatus, $processingUtilizationAverage)

        return Publishers.CombineLatest3(metricsPublisher, $inputLevel, $silenceWarning)
            .combineLatest(latencyPublisher, utilizationPublisher)
            .map { combined, latency, utilization in
                let metrics = combined.0
                let inputLevel = combined.1
                let warning = combined.2
                return FeedbackState(
                    pace: metrics.0,
                    crutchWords: metrics.1,
                    pauseCount: metrics.2,
                    pauseAverageDuration: metrics.3,
                    inputLevel: inputLevel,
                    showSilenceWarning: warning,
                    processingLatencyStatus: latency.0,
                    processingLatencyAverage: latency.1,
                    processingUtilizationStatus: utilization.0,
                    processingUtilizationAverage: utilization.1
                )
            }
            .eraseToAnyPublisher()
    }

    private var speechTranscriber: SpeechTranscribing?
    private(set) var crutchWordDetector: CrutchWordDetector?
    private var paceAnalyzer: PaceAnalyzer?
    private(set) var pauseDetector: PauseDetector?
    private var cancellables = Set<AnyCancellable>()
    private let silenceMonitor = SilenceMonitor()
    private var silenceTimer: DispatchSourceTimer?
    private var checkpointTimer: RepeatingTimer?
    private var isRecording = false
    private let summaryWriter: AnalysisSummaryWriting
    private let now: () -> Date
    private let checkpointInterval: TimeInterval
    private let checkpointTimerFactory: () -> RepeatingTimer
    private let speechTranscriberFactory: () -> SpeechTranscribing
    private var speechPermissionProvider: SpeechPermissionStateProviding?
    private var recordingURLs: [URL] = []
    private var recordingStart: Date?
    private var paceStats = PaceStatsTracker()
    private var latestCrutchWordCounts: [String: Int] = [:]
    private var latestWordCount: Int = 0
    private var processingLatencyTracker = ProcessingLatencyTracker()
    private var processingUtilizationTracker = ProcessingUtilizationTracker()
    private var processingLatencyStats = SessionMetricTracker()
    private var processingUtilizationStats = SessionMetricTracker()

    init(
        summaryWriter: AnalysisSummaryWriting = RecordingManager.shared,
        now: @escaping () -> Date = Date.init,
        speechTranscriberFactory: @escaping () -> SpeechTranscribing = { SpeechTranscriber() },
        checkpointInterval: TimeInterval = Constants.analysisCheckpointInterval,
        checkpointTimerFactory: @escaping () -> RepeatingTimer = { DispatchRepeatingTimer() }
    ) {
        self.summaryWriter = summaryWriter
        self.now = now
        self.speechTranscriberFactory = speechTranscriberFactory
        self.checkpointInterval = checkpointInterval
        self.checkpointTimerFactory = checkpointTimerFactory
    }

    func setup(
        audioCapture: AudioCapture,
        preferencesStore: AnalysisPreferencesStore,
        speechPermission: SpeechPermissionStateProviding? = nil
    ) {
        speechPermissionProvider = speechPermission
        speechTranscriber = speechTranscriberFactory()
        paceAnalyzer = PaceAnalyzer(now: now)
        applyPreferences(preferencesStore.current)

        speechTranscriber?.onTranscription = { [weak self] transcript in
            self?.handleTranscription(transcript)
        }

        preferencesStore.preferencesPublisher
            .removeDuplicates()
            .sink { [weak self] preferences in
                self?.applyPreferences(preferences)
            }
            .store(in: &cancellables)

        audioCapture.$isRecording
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                let update = {
                    self.isRecording = isRecording
                    if isRecording {
                        self.paceAnalyzer?.start()
                        self.pauseDetector?.reset()
                        self.pauseCount = 0
                        self.pauseAverageDuration = 0
                        self.inputLevel = 0.0
                        self.silenceWarning = false
                        self.processingLatencyStatus = .ok
                        self.processingLatencyAverage = 0
                        self.processingUtilizationStatus = .ok
                        self.processingUtilizationAverage = 0
                        self.silenceMonitor.reset()
                        self.paceStats.reset()
                        self.processingLatencyTracker.reset()
                        self.processingUtilizationTracker.reset()
                        self.processingLatencyStats.reset()
                        self.processingUtilizationStats.reset()
                        self.latestCrutchWordCounts = [:]
                        self.latestWordCount = 0
                        self.recordingStart = self.now()
                        self.recordingURLs = []
                        if let currentURL = audioCapture.currentRecordingURL {
                            self.recordingURLs.append(currentURL)
                        }
                        self.startSilenceTimer()
                        self.startCheckpointTimer()
                        if self.canStartTranscription() {
                            self.speechTranscriber?.startTranscription()
                        }
                    } else {
                        self.stopCheckpointTimer()
                        self.writeSummaryIfNeeded()
                        self.stopSilenceTimer()
                        self.speechTranscriber?.stopTranscription()
                        self.paceAnalyzer?.reset()
                        self.crutchWordDetector?.reset()
                        self.pauseDetector?.reset()
                        self.currentPace = 0.0
                        self.crutchWordCount = 0
                        self.pauseCount = 0
                        self.pauseAverageDuration = 0
                        self.inputLevel = 0.0
                        self.silenceWarning = false
                        self.processingLatencyStatus = .ok
                        self.processingLatencyAverage = 0
                        self.processingUtilizationStatus = .ok
                        self.processingUtilizationAverage = 0
                        self.recordingStart = nil
                        self.recordingURLs = []
                        self.processingLatencyTracker.reset()
                        self.processingUtilizationTracker.reset()
                        self.processingLatencyStats.reset()
                        self.processingUtilizationStats.reset()
                        self.latestCrutchWordCounts = [:]
                        self.latestWordCount = 0
                    }
                }
                if Thread.isMainThread {
                    update()
                } else {
                    DispatchQueue.main.async(execute: update)
                }
            }
            .store(in: &cancellables)

        audioCapture.$currentRecordingURL
            .compactMap { $0 }
            .sink { [weak self] url in
                guard let self, self.isRecording else { return }
                if !self.recordingURLs.contains(url) {
                    self.recordingURLs.append(url)
                }
            }
            .store(in: &cancellables)

        audioCapture.audioBufferPublisher
            .sink { [weak self] buffer in
                self?.processAudioBuffer(buffer)
            }
            .store(in: &cancellables)
    }

    private func canStartTranscription() -> Bool {
        guard let speechPermissionProvider else {
            return true
        }
        return speechPermissionProvider.state == .authorized
    }

    func applyPreferences(_ preferences: AnalysisPreferences) {
        crutchWordDetector = CrutchWordDetector(crutchWords: preferences.crutchWords)
        pauseDetector = PauseDetector(pauseThreshold: preferences.pauseThreshold)
    }

    func handleTranscription(_ transcript: String) {
        guard isRecording else { return }
        let totalWords = wordCount(in: transcript)
        latestWordCount = totalWords
        paceAnalyzer?.updateWordCount(totalWords)
        let pace = paceAnalyzer?.calculatePace() ?? 0.0
        let counts = crutchWordDetector?.analyzeCounts(transcript) ?? [:]
        let crutchCount = counts.values.reduce(0, +)
        paceStats.record(pace)
        latestCrutchWordCounts = counts
        DispatchQueue.main.async { [weak self] in
            self?.currentPace = pace
            self?.crutchWordCount = crutchCount
        }
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRecording else { return }
        let startTime = CFAbsoluteTimeGetCurrent()
        // Process audio buffer for real-time analysis
        // This will be called continuously during recording
        speechTranscriber?.appendAudioBuffer(buffer)
        updateInputLevel(from: buffer)
        if let pauseDetector = pauseDetector {
            let didDetectPause = pauseDetector.detectPause(in: buffer)
            let updatedCount = pauseDetector.getPauseCount()
            let averageDuration = pauseDetector.averagePauseDuration()
            DispatchQueue.main.async { [weak self] in
                if didDetectPause {
                    self?.pauseCount = updatedCount
                }
                self?.pauseAverageDuration = averageDuration
            }
        }
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let status = processingLatencyTracker.record(duration: duration)
        let average = processingLatencyTracker.average
        processingLatencyStats.record(value: duration * 1000)
        if status != processingLatencyStatus {
            DispatchQueue.main.async { [weak self] in
                self?.processingLatencyStatus = status
            }
        }
        if abs(average - processingLatencyAverage) >= 0.001 {
            DispatchQueue.main.async { [weak self] in
                self?.processingLatencyAverage = average
            }
        }

        let frameLength = Double(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate
        if frameLength > 0, sampleRate > 0 {
            let bufferDuration = frameLength / sampleRate
            if bufferDuration > 0 {
                let utilization = duration / bufferDuration
                let utilizationStatus = processingUtilizationTracker.record(utilization: utilization)
                let utilizationAverage = processingUtilizationTracker.average
                processingUtilizationStats.record(value: utilization)
                if utilizationStatus != processingUtilizationStatus {
                    DispatchQueue.main.async { [weak self] in
                        self?.processingUtilizationStatus = utilizationStatus
                    }
                }
                if abs(utilizationAverage - processingUtilizationAverage) >= 0.001 {
                    DispatchQueue.main.async { [weak self] in
                        self?.processingUtilizationAverage = utilizationAverage
                    }
                }
            }
        }
    }

    private func updateInputLevel(from buffer: AVAudioPCMBuffer) {
        let rms = rmsAmplitude(in: buffer)
        let scaled = InputLevelMeter.scaledLevel(for: rms)
        silenceMonitor.registerLevel(scaled)
        if silenceWarning, scaled >= InputLevelMeter.meaningfulThreshold {
            DispatchQueue.main.async { [weak self] in
                self?.silenceWarning = false
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.inputLevel = InputLevelMeter.smoothedLevel(previous: self.inputLevel, target: scaled)
        }
    }

    private func rmsAmplitude(in buffer: AVAudioPCMBuffer) -> Float {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        if let floatChannelData = buffer.floatChannelData {
            let samples = floatChannelData[0]
            var sum: Float = 0
            for index in 0..<frameLength {
                let sample = samples[index]
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        if let int16ChannelData = buffer.int16ChannelData {
            let samples = int16ChannelData[0]
            var sum: Float = 0
            let scale = 1.0 as Float / Float(Int16.max)
            for index in 0..<frameLength {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        if let int32ChannelData = buffer.int32ChannelData {
            let samples = int32ChannelData[0]
            var sum: Float = 0
            let scale = 1.0 as Float / Float(Int32.max)
            for index in 0..<frameLength {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        return 0
    }

    func wordCount(in text: String) -> Int {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens.count
    }

    private func startSilenceTimer() {
        stopSilenceTimer()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self, self.isRecording else { return }
            let shouldWarn = self.silenceMonitor.isSilenceWarningActive()
            if shouldWarn != self.silenceWarning {
                DispatchQueue.main.async { [weak self] in
                    self?.silenceWarning = shouldWarn
                }
            }
        }
        silenceTimer = timer
        timer.resume()
    }

    private func stopSilenceTimer() {
        silenceTimer?.cancel()
        silenceTimer = nil
    }

    private func startCheckpointTimer() {
        stopCheckpointTimer()
        guard checkpointInterval > 0 else { return }
        let timer = checkpointTimerFactory()
        timer.schedule(interval: checkpointInterval) { [weak self] in
            guard let self, self.isRecording else { return }
            self.writeSummaryIfNeeded()
        }
        checkpointTimer = timer
    }

    private func stopCheckpointTimer() {
        checkpointTimer?.cancel()
        checkpointTimer = nil
    }

    private func writeSummaryIfNeeded() {
        guard let recordingStart, !recordingURLs.isEmpty else { return }
        let pauseTotal = pauseDetector?.getPauseCount() ?? pauseCount
        let pauseThreshold = pauseDetector?.pauseThreshold ?? Constants.pauseThreshold
        let pauseAverage = pauseDetector?.averagePauseDuration(currentTime: now()) ?? pauseAverageDuration
        let paceSummary = paceStats.summary(totalWords: latestWordCount)
        let crutchCounts = latestCrutchWordCounts
        let crutchTotal = crutchCounts.values.reduce(0, +)
        let processing = AnalysisSummary.ProcessingStats(
            latencyAverageMs: processingLatencyStats.average,
            latencyPeakMs: processingLatencyStats.peak,
            utilizationAverage: processingUtilizationStats.average,
            utilizationPeak: processingUtilizationStats.peak
        )
        let summary = AnalysisSummary(
            version: 1,
            createdAt: now(),
            durationSeconds: max(0, now().timeIntervalSince(recordingStart)),
            pace: paceSummary,
            pauses: AnalysisSummary.PauseStats(
                count: pauseTotal,
                thresholdSeconds: pauseThreshold,
                averageDurationSeconds: pauseAverage
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: crutchTotal,
                counts: crutchCounts
            ),
            processing: processing
        )
        for recordingURL in recordingURLs {
            do {
                try summaryWriter.writeSummary(summary, for: recordingURL)
            } catch {
                print("Failed to write analysis summary: \(error)")
            }
        }
    }
}

private struct PaceStatsTracker {
    private var minValue: Double = .greatestFiniteMagnitude
    private var maxValue: Double = 0
    private var totalValue: Double = 0
    private var count: Int = 0

    mutating func record(_ value: Double) {
        guard value > 0 else { return }
        minValue = min(minValue, value)
        maxValue = max(maxValue, value)
        totalValue += value
        count += 1
    }

    mutating func reset() {
        minValue = .greatestFiniteMagnitude
        maxValue = 0
        totalValue = 0
        count = 0
    }

    func summary(totalWords: Int) -> AnalysisSummary.PaceStats {
        guard count > 0 else {
            return AnalysisSummary.PaceStats(
                averageWPM: 0,
                minWPM: 0,
                maxWPM: 0,
                totalWords: totalWords
            )
        }
        return AnalysisSummary.PaceStats(
            averageWPM: totalValue / Double(count),
            minWPM: minValue,
            maxWPM: maxValue,
            totalWords: totalWords
        )
    }
}

private struct SessionMetricTracker {
    private(set) var total: Double = 0
    private(set) var count: Int = 0
    private(set) var peak: Double = 0

    var average: Double {
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    mutating func record(value: Double) {
        guard value >= 0 else { return }
        total += value
        count += 1
        peak = max(peak, value)
    }

    mutating func reset() {
        total = 0
        count = 0
        peak = 0
    }
}
