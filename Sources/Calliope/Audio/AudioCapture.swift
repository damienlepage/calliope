//
//  AudioCapture.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import AVFoundation
import AudioToolbox
import Combine

enum AudioCaptureError: Equatable {
    case microphonePermissionNotDetermined
    case microphonePermissionDenied
    case microphonePermissionRestricted
    case microphoneUnavailable
    case privacyGuardrailsNotSatisfied
    case voiceIsolationRiskNotAcknowledged
    case systemAudioCaptureNotAllowed
    case audioFileCreationFailed
    case engineStartFailed
    case bufferWriteFailed
    case engineConfigurationChanged
    case captureStartTimedOut
    case captureStartValidationFailed

    var message: String {
        switch self {
        case .microphonePermissionNotDetermined:
            return "Microphone access is required. Click Grant Microphone Access."
        case .microphonePermissionDenied:
            return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .microphonePermissionRestricted:
            return "Microphone access is restricted by system policy."
        case .microphoneUnavailable:
            return "No microphone input detected. Connect or enable a microphone."
        case .privacyGuardrailsNotSatisfied:
            return "Privacy guardrails must be accepted to start."
        case .voiceIsolationRiskNotAcknowledged:
            return "Acknowledge the voice isolation risk before starting."
        case .systemAudioCaptureNotAllowed:
            return "System audio capture is not allowed."
        case .audioFileCreationFailed:
            return "Failed to create local recording file."
        case .engineStartFailed:
            return "Failed to start the audio engine."
        case .bufferWriteFailed:
            return "Failed to write an audio buffer."
        case .engineConfigurationChanged:
            return "Input device changed. Press Start again."
        case .captureStartTimedOut:
            return "Capture did not start in time. Press Start again."
        case .captureStartValidationFailed:
            return "No mic input detected. Retry or select another microphone."
        }
    }
}

enum AudioCaptureStatus: Equatable {
    case idle
    case recording
    case error(AudioCaptureError)
}

enum AudioCaptureInterruption: Equatable {
    case systemSleep
    case systemWake
    case appInactive
    case inputRouteChanged
    case inputDisconnected
    case inputConnected

    var message: String {
        switch self {
        case .systemSleep:
            return "Recording stopped due to system sleep."
        case .systemWake:
            return "System woke. Press Start to resume."
        case .appInactive:
            return "Calliope is inactive. Recording continues in the background."
        case .inputRouteChanged:
            return "Audio input changed. Recording continues with the new device."
        case .inputDisconnected:
            return "Microphone disconnected. Recording will continue when input returns."
        case .inputConnected:
            return "Microphone connected. Recording continues."
        }
    }
}

enum MicTestStatus: Equatable {
    case idle
    case running
    case success(String)
    case failure(String)

    var message: String? {
        switch self {
        case .idle:
            return nil
        case .running:
            return "Mic test running..."
        case .success(let message):
            return message
        case .failure(let message):
            return message
        }
    }
}

enum AudioCaptureBackendStatus: Equatable {
    case standard
    case voiceIsolation
    case voiceIsolationUnavailable

    var message: String {
        switch self {
        case .standard:
            return "Capture: Standard mic"
        case .voiceIsolation:
            return "Capture: Voice Isolation enabled"
        case .voiceIsolationUnavailable:
            return "Capture: Voice Isolation unavailable, using standard mic"
        }
    }

    var diagnosticsLabel: String {
        switch self {
        case .standard:
            return "standard"
        case .voiceIsolation:
            return "voice_isolation"
        case .voiceIsolationUnavailable:
            return "voice_isolation_unavailable"
        }
    }
}

struct CompletedRecordingSession: Equatable {
    let sessionID: String
    let recordingURLs: [URL]
    let createdAt: Date
}

enum AudioInputSource: Equatable {
    case microphone
    case systemAudio
}

struct AudioCaptureBackendSelection {
    let backend: AudioCaptureBackend
    let status: AudioCaptureBackendStatus
}

enum AudioInputDeviceSelectionResult: Equatable {
    case notRequested
    case selected
    case fallbackToDefault
}

protocol AudioCaptureBackend {
    var inputSource: AudioInputSource { get }
    var inputFormat: AVAudioFormat { get }
    var inputDeviceName: String { get }
    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void)
    func removeTap()
    func setConfigurationChangeHandler(_ handler: @escaping () -> Void)
    func clearConfigurationChangeHandler()
    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult
    func start() throws
    func stop()
}

protocol AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws
}

private func audioUnitDisplayName(for audioUnit: AUAudioUnit) -> String {
    var description = audioUnit.componentDescription
    if let component = AudioComponentFindNext(nil, &description) {
        var name: Unmanaged<CFString>?
        if AudioComponentCopyName(component, &name) == noErr,
           let cfName = name?.takeRetainedValue() {
            return cfName as String
        }
    }

    return "Audio Input"
}

final class SystemAudioFileWriter: AudioFileWritable {
    private let file: AVAudioFile

    init(url: URL, settings: [String: Any]) throws {
        file = try AVAudioFile(forWriting: url, settings: settings)
    }

    func write(from buffer: AVAudioPCMBuffer) throws {
        try file.write(from: buffer)
    }
}

final class SystemAudioCaptureBackend: AudioCaptureBackend {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var configurationObserver: NSObjectProtocol?
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    var inputDeviceName: String {
        audioUnitDisplayName(for: inputNode.auAudioUnit)
    }

    init() {
        engine = AVAudioEngine()
        inputNode = engine.inputNode
        inputFormat = inputNode.outputFormat(forBus: 0)
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            handler(buffer)
        }
    }

    func removeTap() {
        inputNode.removeTap(onBus: 0)
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        clearConfigurationChangeHandler()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { _ in
            handler()
        }
    }

    func clearConfigurationChangeHandler() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
    }

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        guard let preferredName, !preferredName.isEmpty else {
            return .notRequested
        }
        guard let deviceID = AudioInputDeviceLookup.deviceID(named: preferredName) else {
            return .fallbackToDefault
        }
        return AudioInputDeviceLookup.setInputDevice(deviceID, on: inputNode)
            ? .selected
            : .fallbackToDefault
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}

enum VoiceIsolationBackendError: Error {
    case notSupported
}

final class VoiceIsolationAudioCaptureBackend: AudioCaptureBackend {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var configurationObserver: NSObjectProtocol?
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    var inputDeviceName: String {
        audioUnitDisplayName(for: inputNode.auAudioUnit)
    }

    init() throws {
        engine = AVAudioEngine()
        inputNode = engine.inputNode
        try Self.enableVoiceIsolation(on: inputNode)
        inputFormat = inputNode.outputFormat(forBus: 0)
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            handler(buffer)
        }
    }

    func removeTap() {
        inputNode.removeTap(onBus: 0)
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        clearConfigurationChangeHandler()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { _ in
            handler()
        }
    }

    func clearConfigurationChangeHandler() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
    }

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        guard let preferredName, !preferredName.isEmpty else {
            return .notRequested
        }
        guard let deviceID = AudioInputDeviceLookup.deviceID(named: preferredName) else {
            return .fallbackToDefault
        }
        return AudioInputDeviceLookup.setInputDevice(deviceID, on: inputNode)
            ? .selected
            : .fallbackToDefault
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    private static func enableVoiceIsolation(on inputNode: AVAudioInputNode) throws {
        if #available(macOS 14.0, *) {
            try inputNode.setVoiceProcessingEnabled(true)
            guard inputNode.isVoiceProcessingEnabled else {
                throw VoiceIsolationBackendError.notSupported
            }
        } else {
            throw VoiceIsolationBackendError.notSupported
        }
    }
}

class AudioCapture: NSObject, ObservableObject {
    typealias AudioCaptureBackendSelector = (AudioCapturePreferences) -> AudioCaptureBackendSelection

    @Published var isRecording = false
    @Published private(set) var status: AudioCaptureStatus = .idle
    @Published private(set) var micTestStatus: MicTestStatus = .idle
    @Published private(set) var currentRecordingURL: URL?
    @Published private(set) var completedRecordingSession: CompletedRecordingSession?
    @Published private(set) var inputDeviceName: String = "Unknown Microphone"
    @Published private(set) var outputDeviceName: String = "Unknown Output"
    @Published private(set) var backendStatus: AudioCaptureBackendStatus = .standard
    @Published private(set) var deviceSelectionMessage: String?
    @Published private(set) var inputFormatSnapshot: AudioInputFormatSnapshot?
    @Published private(set) var storageStatus: RecordingStorageStatus = .ok
    @Published private(set) var interruption: AudioCaptureInterruption?

    private let bufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        bufferSubject.eraseToAnyPublisher()
    }

    private var backend: AudioCaptureBackend?
    private var audioFile: AudioFileWritable?
    private var tapFrameCounter: UInt = 0
    private var micTestBackend: AudioCaptureBackend?
    private var micTestWorkItem: DispatchWorkItem?
    private var micTestDidReceiveBuffer = false
    private let recordingManager: RecordingManager
    private let capturePreferencesStore: AudioCapturePreferencesStore
    private let backendSelector: AudioCaptureBackendSelector
    private let audioFileFactory: (URL, [String: Any]) throws -> AudioFileWritable
    private let recordingStartTimeout: TimeInterval
    private let recordingStartTimeoutQueue: DispatchQueue
    private let recordingStartConfirmation: () -> Bool
    private var recordingStartWorkItem: DispatchWorkItem?
    private let now: () -> Date
    private let captureStartValidationTimeout: TimeInterval
    private let captureStartValidationQueue: DispatchQueue
    private let inputLevelProvider: (AVAudioPCMBuffer) -> Double
    private let fileSizeProvider: (URL) -> Int
    private let captureStartValidationThreshold: Double
    private var captureStartValidationWorkItem: DispatchWorkItem?
    private var didReceiveMeaningfulInput = false
    private var awaitingRecordingStart = false
    private let storageMonitor: RecordingStorageMonitor
    private let storageMonitorQueue: DispatchQueue
    private let storageMonitorInterval: TimeInterval
    private var storageMonitorTimer: DispatchSourceTimer?
    private let notificationCenter: NotificationCenter
    private let workspaceNotificationCenter: NotificationCenter
    private var notificationObservers: [NSObjectProtocol] = []
    private var stoppedForSleep = false
    private var recordingSessionID: String?
    private var recordingSegmentIndex: Int = 0
    private var recordingSegmentStart: Date?
    private var recordingSessionStart: Date?
    private var recordingFileSettings: [String: Any]?
    private var recordedSegmentURLs: [URL] = []
    private var maxSegmentDuration: TimeInterval = 0

    var statusText: String {
        switch status {
        case .idle:
            return "Stopped"
        case .recording:
            return "Recording"
        case .error(let error):
            return "Error: \(error.message)"
        }
    }

    init(
        recordingManager: RecordingManager = .shared,
        capturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        backendSelector: @escaping AudioCaptureBackendSelector = AudioCapture.defaultBackendSelector,
        audioFileFactory: @escaping (URL, [String: Any]) throws -> AudioFileWritable = { url, settings in
            try SystemAudioFileWriter(url: url, settings: settings)
        },
        recordingStartTimeout: TimeInterval = 1.0,
        recordingStartTimeoutQueue: DispatchQueue = .main,
        recordingStartConfirmation: @escaping () -> Bool = { false },
        now: @escaping () -> Date = Date.init,
        captureStartValidationTimeout: TimeInterval = 2.0,
        captureStartValidationQueue: DispatchQueue = .main,
        captureStartValidationThreshold: Double = InputLevelMeter.meaningfulThreshold,
        inputLevelProvider: @escaping (AVAudioPCMBuffer) -> Double = { buffer in
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return 0 }

            if let floatChannelData = buffer.floatChannelData {
                let samples = floatChannelData[0]
                var sum: Float = 0
                for index in 0..<frameLength {
                    let sample = samples[index]
                    sum += sample * sample
                }
                return InputLevelMeter.scaledLevel(for: sqrt(sum / Float(frameLength)))
            }

            if let int16ChannelData = buffer.int16ChannelData {
                let samples = int16ChannelData[0]
                var sum: Float = 0
                let scale = 1.0 as Float / Float(Int16.max)
                for index in 0..<frameLength {
                    let sample = Float(samples[index]) * scale
                    sum += sample * sample
                }
                return InputLevelMeter.scaledLevel(for: sqrt(sum / Float(frameLength)))
            }

            if let int32ChannelData = buffer.int32ChannelData {
                let samples = int32ChannelData[0]
                var sum: Float = 0
                let scale = 1.0 as Float / Float(Int32.max)
                for index in 0..<frameLength {
                    let sample = Float(samples[index]) * scale
                    sum += sample * sample
                }
                return InputLevelMeter.scaledLevel(for: sqrt(sum / Float(frameLength)))
            }

            return 0
        },
        fileSizeProvider: @escaping (URL) -> Int = { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return values?.fileSize ?? 0
        },
        storageMonitor: RecordingStorageMonitor? = nil,
        storageMonitorQueue: DispatchQueue = DispatchQueue(label: "com.calliope.storageMonitor"),
        storageMonitorInterval: TimeInterval = 15.0,
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        self.recordingManager = recordingManager
        self.capturePreferencesStore = capturePreferencesStore
        self.backendSelector = backendSelector
        self.audioFileFactory = audioFileFactory
        self.recordingStartTimeout = recordingStartTimeout
        self.recordingStartTimeoutQueue = recordingStartTimeoutQueue
        self.recordingStartConfirmation = recordingStartConfirmation
        self.now = now
        self.captureStartValidationTimeout = captureStartValidationTimeout
        self.captureStartValidationQueue = captureStartValidationQueue
        self.inputLevelProvider = inputLevelProvider
        self.fileSizeProvider = fileSizeProvider
        self.captureStartValidationThreshold = captureStartValidationThreshold
        self.storageMonitor = storageMonitor ?? RecordingStorageMonitor(
            fileSizeProvider: fileSizeProvider
        )
        self.storageMonitorQueue = storageMonitorQueue
        self.storageMonitorInterval = storageMonitorInterval
        self.notificationCenter = notificationCenter
        self.workspaceNotificationCenter = workspaceNotificationCenter
        super.init()
        startSystemMonitoring()
        // macOS doesn't use AVAudioSession - AVAudioEngine handles this directly
    }

    static let defaultBackendSelector: AudioCaptureBackendSelector = { preferences in
        if preferences.voiceIsolationEnabled {
            if let backend = try? VoiceIsolationAudioCaptureBackend() {
                return AudioCaptureBackendSelection(
                    backend: backend,
                    status: .voiceIsolation
                )
            }
            return AudioCaptureBackendSelection(
                backend: SystemAudioCaptureBackend(),
                status: .voiceIsolationUnavailable
            )
        }
        return AudioCaptureBackendSelection(
            backend: SystemAudioCaptureBackend(),
            status: .standard
        )
    }

    var backendStatusText: String {
        backendStatus.message
    }

    var micTestStatusText: String? {
        micTestStatus.message
    }

    var interruptionMessage: String? {
        interruption?.message
    }

    var isTestingMic: Bool {
        if case .running = micTestStatus {
            return true
        }
        return false
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true,
        requiresVoiceIsolationAcknowledgement: Bool = false,
        hasAcknowledgedVoiceIsolationRisk: Bool = false
    ) {
        guard !isRecording, !awaitingRecordingStart else { return }
        guard !isTestingMic else { return }
        micTestStatus = .idle
        clearInterruption()
        stoppedForSleep = false
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput,
            requiresVoiceIsolationAcknowledgement: requiresVoiceIsolationAcknowledgement,
            hasAcknowledgedVoiceIsolationRisk: hasAcknowledgedVoiceIsolationRisk
        )
        guard blockingReasons.isEmpty else {
            if let reason = blockingReasons.first {
                updateStatus(.error(error(for: reason)))
            }
            return
        }

        let preferences = capturePreferencesStore.current
        let selection = backendSelector(preferences)
        let backend = selection.backend
        backendStatus = selection.status
        guard backend.inputSource == .microphone else {
            updateStatus(.error(.systemAudioCaptureNotAllowed))
            return
        }
        self.backend = backend
        applyPreferredInputDeviceSelection(
            preferredName: preferences.preferredMicrophoneName,
            backend: backend
        )
        refreshInputDeviceName(from: backend)
        refreshOutputDeviceName()
        refreshInputFormat(from: backend)
        let recordingFormat = backend.inputFormat
        backend.setConfigurationChangeHandler { [weak self] in
            self?.handleConfigurationChange()
        }

        // Recordings are written locally only; no network transmission.
        // Create audio file
        recordingSessionID = UUID().uuidString
        recordingSegmentIndex = 0
        recordingSegmentStart = nil
        recordingSessionStart = nil
        recordingFileSettings = recordingFormat.settings
        maxSegmentDuration = max(0, preferences.maxSegmentDuration)
        recordedSegmentURLs = []
        completedRecordingSession = nil
        guard startNewRecordingSegment() else {
            self.backend = nil
            return
        }

        tapFrameCounter = 0
        didReceiveMeaningfulInput = false
        awaitingRecordingStart = true
        cancelCaptureStartValidation()

        // Install tap to capture audio
        backend.installTap(bufferSize: 1024) { [weak self] buffer in
            guard let self else { return }

            if let copiedBuffer = AudioBufferCopy.copy(buffer) {
                self.bufferSubject.send(copiedBuffer)
            }

            if self.awaitingRecordingStart {
                self.confirmRecordingStartIfNeeded()
            }

            let level = self.inputLevelProvider(buffer)
            if level >= self.captureStartValidationThreshold {
                self.didReceiveMeaningfulInput = true
            }

            self.rotateRecordingSegmentIfNeeded()

            do {
                guard let audioFile = self.audioFile else { return }
                try audioFile.write(from: buffer)
            } catch {
                self.handleCaptureError(.bufferWriteFailed)
            }

            self.tapFrameCounter += 1
            if self.tapFrameCounter % 50 == 0 {
                print("AudioCapture received \(self.tapFrameCounter) buffers")
            }
        }

        scheduleRecordingStartTimeout()

        if recordingStartConfirmation() {
            confirmRecordingStartIfNeeded()
        }

        do {
            try backend.start()
        } catch {
            cancelRecordingStartTimeout()
            awaitingRecordingStart = false
            isRecording = false
            stopRecordingInternal(statusOverride: .error(.engineStartFailed))
        }
    }

    func startMicTest(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true,
        duration: TimeInterval = 2.5
    ) {
        guard !isRecording else {
            updateMicTestStatus(.failure("Stop the current recording before running a mic test."))
            return
        }
        guard !isTestingMic else { return }
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput
        )
        guard blockingReasons.isEmpty else {
            if let reason = blockingReasons.first {
                updateMicTestStatus(.failure(error(for: reason).message))
            }
            return
        }

        let preferences = capturePreferencesStore.current
        let selection = backendSelector(preferences)
        let backend = selection.backend
        backendStatus = selection.status
        guard backend.inputSource == .microphone else {
            updateMicTestStatus(.failure(AudioCaptureError.systemAudioCaptureNotAllowed.message))
            return
        }

        micTestBackend = backend
        applyPreferredInputDeviceSelection(
            preferredName: preferences.preferredMicrophoneName,
            backend: backend
        )
        refreshInputDeviceName(from: backend)
        refreshOutputDeviceName()
        refreshInputFormat(from: backend)
        backend.setConfigurationChangeHandler { [weak self] in
            self?.handleMicTestConfigurationChange()
        }

        micTestDidReceiveBuffer = false
        updateMicTestStatus(.running)

        backend.installTap(bufferSize: 1024) { [weak self] _ in
            guard let self else { return }
            self.micTestDidReceiveBuffer = true
        }

        do {
            try backend.start()
        } catch {
            stopMicTest(status: .failure(AudioCaptureError.engineStartFailed.message))
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.finishMicTest()
        }
        micTestWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermissionProvider: MicrophonePermissionProviding,
        hasMicrophoneInput: Bool = true,
        requiresVoiceIsolationAcknowledgement: Bool = false,
        hasAcknowledgedVoiceIsolationRisk: Bool = false
    ) {
        let state = microphonePermissionProvider.authorizationState()
        startRecording(
            privacyState: privacyState,
            microphonePermission: state,
            hasMicrophoneInput: hasMicrophoneInput,
            requiresVoiceIsolationAcknowledgement: requiresVoiceIsolationAcknowledgement,
            hasAcknowledgedVoiceIsolationRisk: hasAcknowledgedVoiceIsolationRisk
        )
    }

    func stopRecording() {
        if isRecording || awaitingRecordingStart {
            stopRecordingInternal(statusOverride: .idle, shouldPublishCompletedSession: true)
            return
        }
        if case .error = status {
            updateStatus(.idle)
        }
    }

    private func stopRecordingInternal(
        statusOverride: AudioCaptureStatus,
        shouldPublishCompletedSession: Bool = false
    ) {
        let wasRecording = isRecording
        let completedSessionID = recordingSessionID
        let completedSessionStart = recordingSessionStart ?? now()
        let completedSegmentURLs = recordedSegmentURLs
        cancelRecordingStartTimeout()
        cancelCaptureStartValidation()
        stopStorageMonitoring()
        awaitingRecordingStart = false
        backend?.clearConfigurationChangeHandler()
        backend?.removeTap()
        backend?.stop()
        audioFile = nil
        backend = nil
        recordingSessionID = nil
        recordingSegmentIndex = 0
        recordingSegmentStart = nil
        recordingSessionStart = nil
        recordingFileSettings = nil
        maxSegmentDuration = 0
        recordedSegmentURLs = []

        isRecording = false
        updateStatus(statusOverride)
        if case .idle = statusOverride, !stoppedForSleep {
            clearInterruption()
        }
        if shouldPublishCompletedSession,
           wasRecording,
           case .idle = statusOverride,
           let completedSessionID,
           !completedSegmentURLs.isEmpty {
            completedRecordingSession = CompletedRecordingSession(
                sessionID: completedSessionID,
                recordingURLs: completedSegmentURLs,
                createdAt: completedSessionStart
            )
        }
        cleanupFailedRecordingIfNeeded(wasRecording: wasRecording)
    }

    private func stopMicTest(status: MicTestStatus) {
        micTestWorkItem?.cancel()
        micTestWorkItem = nil
        micTestBackend?.clearConfigurationChangeHandler()
        micTestBackend?.removeTap()
        micTestBackend?.stop()
        micTestBackend = nil
        micTestDidReceiveBuffer = false
        updateMicTestStatus(status)
    }

    private func handleCaptureError(_ error: AudioCaptureError) {
        DispatchQueue.main.async { [weak self] in
            self?.stopRecordingInternal(statusOverride: .error(error))
        }
    }

    private func handleConfigurationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRecording else { return }
            self.refreshInputDeviceName(from: self.backend)
            self.refreshOutputDeviceName()
            self.noteInterruption(.inputRouteChanged)
        }
    }

    private func handleMicTestConfigurationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isTestingMic else { return }
            self.refreshInputDeviceName(from: self.micTestBackend)
            self.refreshOutputDeviceName()
            self.stopMicTest(status: .failure(AudioCaptureError.engineConfigurationChanged.message))
        }
    }

    private func finishMicTest() {
        let status: MicTestStatus = micTestDidReceiveBuffer
            ? .success("Mic test succeeded.")
            : .failure("No mic input detected during the mic test.")
        stopMicTest(status: status)
    }

    private func updateStatus(_ newStatus: AudioCaptureStatus) {
        if case .recording = newStatus {
            cancelRecordingStartTimeout()
        }
        if case .error = newStatus {
            cancelRecordingStartTimeout()
            cancelCaptureStartValidation()
        }
        if Thread.isMainThread {
            status = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.status = newStatus
            }
        }
    }

    private func updateMicTestStatus(_ newStatus: MicTestStatus) {
        if Thread.isMainThread {
            micTestStatus = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.micTestStatus = newStatus
            }
        }
    }

    private func noteInterruption(_ interruption: AudioCaptureInterruption) {
        if Thread.isMainThread {
            self.interruption = interruption
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.interruption = interruption
            }
        }
    }

    private func clearInterruption() {
        if Thread.isMainThread {
            interruption = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.interruption = nil
            }
        }
    }

    private func refreshInputDeviceName(from backend: AudioCaptureBackend?) {
        guard let backend else { return }
        let deviceName = backend.inputDeviceName
        if Thread.isMainThread {
            inputDeviceName = deviceName
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.inputDeviceName = deviceName
            }
        }
    }

    private func refreshOutputDeviceName() {
        let deviceName = AudioOutputDeviceLookup.defaultOutputDevice()?.name ?? "Unknown Output"
        if Thread.isMainThread {
            outputDeviceName = deviceName
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.outputDeviceName = deviceName
            }
        }
    }

    private func refreshInputFormat(from backend: AudioCaptureBackend?) {
        guard let backend else { return }
        let format = backend.inputFormat
        let snapshot = AudioInputFormatSnapshot(
            sampleRate: format.sampleRate,
            channelCount: Int(format.channelCount)
        )
        if Thread.isMainThread {
            inputFormatSnapshot = snapshot
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.inputFormatSnapshot = snapshot
            }
        }
    }

    private func applyPreferredInputDeviceSelection(
        preferredName: String?,
        backend: AudioCaptureBackend
    ) {
        deviceSelectionMessage = nil
        let result = backend.selectInputDevice(named: preferredName)
        if case .fallbackToDefault = result, let preferredName {
            deviceSelectionMessage = "Preferred microphone \"\(preferredName)\" not available. Using system default."
        }
    }

    func refreshDiagnostics() {
        if isRecording, let backend {
            refreshInputDeviceName(from: backend)
            refreshOutputDeviceName()
            refreshInputFormat(from: backend)
            return
        }

        if isTestingMic, let micTestBackend {
            refreshInputDeviceName(from: micTestBackend)
            refreshOutputDeviceName()
            refreshInputFormat(from: micTestBackend)
            return
        }

        let preferences = capturePreferencesStore.current
        let selection = backendSelector(preferences)
        backendStatus = selection.status
        let backend = selection.backend
        applyPreferredInputDeviceSelection(
            preferredName: preferences.preferredMicrophoneName,
            backend: backend
        )
        refreshInputDeviceName(from: backend)
        refreshOutputDeviceName()
        refreshInputFormat(from: backend)
    }

    private func error(for reason: RecordingEligibility.Reason) -> AudioCaptureError {
        switch reason {
        case .microphonePermissionNotDetermined:
            return .microphonePermissionNotDetermined
        case .microphonePermissionDenied:
            return .microphonePermissionDenied
        case .microphonePermissionRestricted:
            return .microphonePermissionRestricted
        case .microphoneUnavailable:
            return .microphoneUnavailable
        case .disclosureNotAccepted:
            return .privacyGuardrailsNotSatisfied
        case .voiceIsolationRiskUnacknowledged:
            return .voiceIsolationRiskNotAcknowledged
        }
    }

    func setRecordingURLForTesting(_ url: URL?) {
        currentRecordingURL = url
    }

    private func markRecordingStarted() {
        isRecording = true
        updateStatus(.recording)
        startStorageMonitoring()
        scheduleCaptureStartValidation()
    }

    private func confirmRecordingStartIfNeeded() {
        guard !isRecording else { return }
        if case .error = status {
            return
        }
        awaitingRecordingStart = false
        markRecordingStarted()
    }

    private func scheduleRecordingStartTimeout() {
        cancelRecordingStartTimeout()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.isRecording {
                return
            }
            if case .error = self.status {
                return
            }
            self.stopRecordingInternal(statusOverride: .error(.captureStartTimedOut))
        }
        recordingStartWorkItem = workItem
        recordingStartTimeoutQueue.asyncAfter(
            deadline: .now() + recordingStartTimeout,
            execute: workItem
        )
    }

    private func cancelRecordingStartTimeout() {
        recordingStartWorkItem?.cancel()
        recordingStartWorkItem = nil
    }

    private func scheduleCaptureStartValidation() {
        cancelCaptureStartValidation()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.isRecording else { return }
            if case .error = self.status {
                return
            }
            guard let url = self.currentRecordingURL else { return }
            let fileSize = self.fileSizeProvider(url)
            guard self.didReceiveMeaningfulInput, fileSize > 0 else {
                self.stopRecordingInternal(statusOverride: .error(.captureStartValidationFailed))
                return
            }
        }
        captureStartValidationWorkItem = workItem
        captureStartValidationQueue.asyncAfter(
            deadline: .now() + captureStartValidationTimeout,
            execute: workItem
        )
    }

    private func cancelCaptureStartValidation() {
        captureStartValidationWorkItem?.cancel()
        captureStartValidationWorkItem = nil
    }

    private func startStorageMonitoring() {
        stopStorageMonitoring()
        guard currentRecordingURL != nil else { return }
        storageMonitor.reset()
        let timer = DispatchSource.makeTimerSource(queue: storageMonitorQueue)
        timer.schedule(deadline: .now(), repeating: storageMonitorInterval)
        timer.setEventHandler { [weak self] in
            guard let self, self.isRecording else { return }
            guard let recordingURL = self.currentRecordingURL else { return }
            let status = self.storageMonitor.evaluate(
                recordingURL: recordingURL,
                inputFormat: self.inputFormatSnapshot
            )
            DispatchQueue.main.async {
                self.storageStatus = status
            }
        }
        storageMonitorTimer = timer
        timer.resume()
    }

    private func stopStorageMonitoring() {
        storageMonitorTimer?.cancel()
        storageMonitorTimer = nil
        storageMonitor.reset()
        if Thread.isMainThread {
            storageStatus = .ok
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.storageStatus = .ok
            }
        }
    }

    private func cleanupFailedRecordingIfNeeded(wasRecording: Bool) {
        guard !wasRecording else { return }
        guard let url = currentRecordingURL else { return }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values?.fileSize ?? 0
        guard fileSize == 0 else { return }
        try? recordingManager.deleteRecording(at: url)
    }

    private func startNewRecordingSegment() -> Bool {
        guard let recordingFileSettings else { return false }
        let sessionID = recordingSessionID ?? UUID().uuidString
        recordingSessionID = sessionID
        recordingSegmentIndex += 1
        let url = recordingManager.getNewRecordingURL(
            sessionID: sessionID,
            segmentIndex: recordingSegmentIndex
        )
        do {
            audioFile = try audioFileFactory(url, recordingFileSettings)
            currentRecordingURL = url
            let segmentStart = now()
            if recordingSessionStart == nil {
                recordingSessionStart = segmentStart
            }
            recordingSegmentStart = segmentStart
            recordedSegmentURLs.append(url)
            return true
        } catch {
            updateStatus(.error(.audioFileCreationFailed))
            return false
        }
    }

    private func rotateRecordingSegmentIfNeeded() {
        guard maxSegmentDuration > 0 else { return }
        guard let segmentStart = recordingSegmentStart else { return }
        let elapsed = now().timeIntervalSince(segmentStart)
        guard elapsed >= maxSegmentDuration else { return }
        audioFile = nil
        if !startNewRecordingSegment() {
            handleCaptureError(.audioFileCreationFailed)
            return
        }
        storageMonitor.reset()
    }

    private func startSystemMonitoring() {
        notificationObservers = [
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSystemSleep()
            },
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSystemWake()
            },
            notificationCenter.addObserver(
                forName: .AVCaptureDeviceWasDisconnected,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleInputDisconnected()
            },
            notificationCenter.addObserver(
                forName: .AVCaptureDeviceWasConnected,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleInputConnected()
            },
            notificationCenter.addObserver(
                forName: NSApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppWillResignActive()
            },
            notificationCenter.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
        ]
    }

    private func handleSystemSleep() {
        guard isRecording || awaitingRecordingStart else { return }
        stoppedForSleep = true
        noteInterruption(.systemSleep)
        stopRecordingInternal(statusOverride: .idle)
    }

    private func handleSystemWake() {
        guard stoppedForSleep else { return }
        stoppedForSleep = false
        noteInterruption(.systemWake)
    }

    private func handleInputDisconnected() {
        guard isRecording else { return }
        noteInterruption(.inputDisconnected)
    }

    private func handleInputConnected() {
        guard isRecording else { return }
        refreshInputDeviceName(from: backend)
        noteInterruption(.inputConnected)
    }

    private func handleAppWillResignActive() {
        guard isRecording || awaitingRecordingStart else { return }
        noteInterruption(.appInactive)
    }

    private func handleAppDidBecomeActive() {
        guard interruption == .appInactive else { return }
        clearInterruption()
    }
    deinit {
        notificationObservers.forEach(notificationCenter.removeObserver)
        notificationObservers.forEach(workspaceNotificationCenter.removeObserver)
    }
}
